// ClaudeMenubar — menu bar indicator for running Claude Code sessions.
//
// State lives in ~/.local/state/claude-menubar/sessions/<session-id>.json, written
// atomically (write + rename) by the claude-tmux-notify hook. The rename is what
// makes the directory vnode fire, so the icon reflects a hook write within
// milliseconds without polling. The timer drops entries that have gone stale and,
// the other way round, writes one back for any pane running claude that has no state
// file at all — see prune and recover.
//
// Build: .local/share/claude-menubar/build.sh

import AppKit

// MARK: - Palette

enum Kanagawa {
    static let springGreen = rgb(0x98, 0xbb, 0x6c)
    static let roninYellow = rgb(0xff, 0x9e, 0x3b)
    static let carpYellow = rgb(0xe6, 0xc3, 0x84)
    static let crystalBlue = rgb(0x7e, 0x9c, 0xd8)
    static let samuraiRed = rgb(0xe8, 0x24, 0x24)

    private static func rgb(_ r: Int, _ g: Int, _ b: Int) -> NSColor {
        NSColor(srgbRed: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
    }
}

// MARK: - Phase

// Raw values are the `state` strings the hook writes; order of `rank` decides
// which session's colour the menu bar icon takes when several are active.
enum Phase: String, CaseIterable {
    case waiting
    case working
    case bgRunning = "bg-running"
    case doneBg = "done-bg"
    case done
    case idle

    var rank: Int {
        switch self {
        case .waiting: return 0
        case .working: return 1
        case .bgRunning: return 2
        case .doneBg: return 3
        case .done: return 4
        case .idle: return 5
        }
    }

    var symbol: String {
        switch self {
        case .waiting: return "bell.badge.fill"
        case .working: return "arrow.triangle.2.circlepath"
        case .bgRunning: return "hourglass"
        case .doneBg: return "checkmark.circle"
        case .done: return "checkmark.circle.fill"
        case .idle: return "circle.dashed"
        }
    }

    var color: NSColor? {
        switch self {
        case .waiting: return Kanagawa.roninYellow
        case .working: return Kanagawa.crystalBlue
        case .bgRunning: return Kanagawa.carpYellow
        case .doneBg: return Kanagawa.crystalBlue
        case .done: return Kanagawa.springGreen
        case .idle: return nil // template image, follows the menu bar
        }
    }

    var label: String {
        switch self {
        case .waiting: return "needs input"
        case .working: return "working"
        case .bgRunning: return "background task"
        case .doneBg: return "background task done"
        case .done: return "finished"
        case .idle: return "idle"
        }
    }

    // Nothing is going to happen in these on its own, so looking at the pane is
    // all the acknowledgement they need.
    var clearsWhenSeen: Bool { self == .done || self == .doneBg }
}

// Compact relative age: what turns "needs input" into "needs input, 20 minutes ago".
func shortAge(_ date: Date) -> String {
    let s = max(Int(Date().timeIntervalSince(date)), 0)
    if s < 60 { return "\(s)s" }
    if s < 3600 { return "\(s / 60)m" }
    if s < 86400 { return "\(s / 3600)h" }
    return "\(s / 86400)d"
}

// MARK: - Session

struct Session {
    let file: URL
    let phase: Phase
    let project: String
    let detail: String
    let tmuxSocket: String
    let tmuxSession: String
    let tmuxWindow: String
    let tmuxPane: String
    let tmuxTty: String
    let isRecovered: Bool
    let updatedAt: Date

    init?(file: URL) {
        guard let data = try? Data(contentsOf: file),
              let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        else { return nil }

        func str(_ key: String) -> String { (obj[key] as? String) ?? "" }

        self.file = file
        phase = Phase(rawValue: str("state")) ?? .idle
        project = str("project").isEmpty ? "unknown" : str("project")
        detail = str("detail")
        tmuxSocket = str("tmux_socket")
        tmuxSession = str("tmux_session")
        tmuxWindow = str("tmux_window")
        tmuxPane = str("tmux_pane")
        tmuxTty = str("tmux_tty")
        isRecovered = (obj["recovered"] as? Bool) ?? false
        updatedAt = Date(timeIntervalSince1970: (obj["updated_at"] as? Double) ?? 0)
    }

    // "Home:2", empty when the session was not started inside tmux.
    var context: String {
        guard !tmuxSession.isEmpty else { return "" }
        return tmuxWindow.isEmpty ? tmuxSession : "\(tmuxSession):\(tmuxWindow)"
    }

    var isJumpable: Bool { !tmuxSocket.isEmpty && !tmuxSession.isEmpty }

    // ps reports ttys008, the tmux format reports /dev/ttys008.
    var ttyName: String {
        tmuxTty.hasPrefix("/dev/") ? String(tmuxTty.dropFirst(5)) : tmuxTty
    }
}

// MARK: - Controller

final class Controller: NSObject, NSMenuDelegate {
    private let stateDir: URL
    private let jumpTool: URL
    private let tmuxBin: String?
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()

    private var sessions: [Session] = []
    private var watcher: DispatchSourceFileSystemObject?
    private var pending: DispatchWorkItem?

    // Fallback only, for entries whose tmux server cannot be reached at all.
    private let maxAge: TimeInterval = 24 * 3600
    // A state file written milliseconds ago must not be judged before its own
    // `claude` shows up in the process list.
    private let claudeGrace: TimeInterval = 15
    // Waiting longer than this is no longer news: the icon turns red so a forgotten
    // prompt reads differently from one that just arrived.
    private let urgentAfter: TimeInterval = 300
    private let pruneInterval: TimeInterval = 15

    init(stateDir: URL) {
        self.stateDir = stateDir
        jumpTool = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".local/bin/claude-jump")
        tmuxBin = ["/opt/homebrew/bin/tmux", "/usr/local/bin/tmux", "/usr/bin/tmux"]
            .first { FileManager.default.isExecutableFile(atPath: $0) }
        super.init()

        menu.delegate = self
        menu.autoenablesItems = false
        item.menu = menu
        item.button?.imagePosition = .imageLeading

        try? FileManager.default.createDirectory(at: stateDir, withIntermediateDirectories: true)
        reload()
        prune()
        startWatching()

        // reload first: prune walks the sessions list, so pruning ahead of it would
        // always be judging the previous tick's snapshot.
        Timer.scheduledTimer(withTimeInterval: pruneInterval, repeats: true) { [weak self] _ in
            self?.reload()
            self?.prune()
        }
    }

    // MARK: State

    private func startWatching() {
        let fd = open(stateDir.path, O_EVTONLY)
        guard fd >= 0 else { return }
        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename],
            queue: .main
        )
        src.setEventHandler { [weak self] in self?.scheduleReload() }
        src.setCancelHandler { close(fd) }
        src.resume()
        watcher = src
    }

    // Several sessions writing at once produce a burst of vnode events; coalesce.
    private func scheduleReload() {
        pending?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.reload() }
        pending = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08, execute: work)
    }

    private func reload() {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: stateDir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )) ?? []

        sessions = files
            .filter { $0.pathExtension == "json" }
            .compactMap(Session.init(file:))
            .sorted {
                $0.phase.rank != $1.phase.rank
                    ? $0.phase.rank < $1.phase.rank
                    : $0.updatedAt > $1.updatedAt
            }

        updateIcon()
    }

    // What tmux still knows about one pane. @claude_state / @claude_last are the
    // hook's other output and they outlive a missing state file, which is what makes
    // recovery possible.
    private struct PaneInfo {
        let id: String
        let tty: String
        let visible: Bool
        let session: String
        let window: String
        let path: String
        let glyph: String
        let last: String

        // ps reports ttys008, tmux reports /dev/ttys008.
        var ttyName: String { tty.hasPrefix("/dev/") ? String(tty.dropFirst(5)) : tty }
    }

    // The hook's state glyph, read back the other way. Keep in sync with
    // set_window_state in claude-tmux-notify.
    private static let phaseByGlyph: [String: Phase] = [
        "󰓦": .working,
        "󰛐": .waiting,
        "󱎫": .bgRunning,
        "": .doneBg,
        "": .done
    ]

    // One query per server per tick, answering liveness, visibility and everything
    // recovery needs. The separator is "|" and not a tab: with no UTF-8 locale in the
    // environment tmux rewrites a tab in format output to "_", which silently broke
    // every split and made every pane look gone. Only the last field can contain the
    // separator, so maxSplits keeps it whole.
    private func paneInfo(socket: String?) -> (socket: String, panes: [PaneInfo])? {
        guard let tmux = tmuxBin else { return nil }

        var args = socket.map { ["-S", $0] } ?? []
        args += ["list-panes", "-a", "-F", [
            "#{socket_path}", "#{pane_id}", "#{pane_tty}",
            "#{pane_active}#{window_active}#{?#{session_attached},1,0}",
            "#{session_name}", "#{window_index}", "#{pane_current_path}",
            "#{@claude_state}", "#{@claude_last}",
        ].joined(separator: "|")]

        guard let out = capture(tmux, args) else {
            log("list-panes failed on \(socket ?? "the default socket")")
            return nil
        }

        var socketPath = socket ?? ""
        var panes: [PaneInfo] = []
        for line in out.split(separator: "\n") {
            let f = line.split(separator: "|", maxSplits: 8, omittingEmptySubsequences: false)
            guard f.count >= 8 else { continue }
            socketPath = String(f[0])
            panes.append(PaneInfo(
                id: String(f[1]),
                tty: String(f[2]),
                visible: f[3] == "111",
                session: String(f[4]),
                window: String(f[5]),
                path: String(f[6]),
                glyph: String(f[7]),
                last: f.count > 8 ? String(f[8]) : ""
            ))
        }

        // A live server always has panes, so an empty parse means the answer was
        // unparsable — treat that as "cannot tell" rather than "everything is gone".
        guard !panes.isEmpty else {
            log("list-panes parsed no panes from \(out.count) bytes")
            return nil
        }
        return (socketPath, panes)
    }

    // ttys running a live `claude`. tmux reports the pane's foreground command as the
    // shell even while Claude is running, so the tty is the only cheap link between a
    // state file and the process that wrote it. nil when ps fails.
    private func claudeTtys() -> Set<String>? {
        guard let out = capture("/bin/ps", ["-ax", "-o", "tty=,comm="]) else { return nil }
        var ttys: Set<String> = []
        for line in out.split(separator: "\n") {
            let fields = line.split(separator: " ", omittingEmptySubsequences: true)
            guard fields.count >= 2, fields[0] != "??" else { continue }
            if fields[1].hasSuffix("claude") { ttys.insert(String(fields[0])) }
        }
        return ttys
    }

    // Ways an entry stops being worth showing:
    //   the pane is gone                          → the session went with it
    //   claude is gone but the pane lives         → a crash or ctrl-C fires no SessionEnd
    //   finished and the pane is on screen        → you have seen it; a green icon that
    //                                               never clears is the pile-up this app exists to avoid
    //   a placeholder the real session has replaced
    // An unreachable tmux server falls back to age, so a tmux restart mid-session does
    // not wipe the list.
    private func prune() {
        var probes: [String: (socket: String, panes: [PaneInfo])?] = [:]
        func probe(_ socket: String?) -> (socket: String, panes: [PaneInfo])? {
            let key = socket ?? ""
            if let cached = probes[key] { return cached }
            let fresh = paneInfo(socket: socket)
            probes[key] = fresh
            return fresh
        }

        let ttys = claudeTtys()
        let realPanes = Set(sessions.filter { !$0.isRecovered }.map(\.tmuxPane))
        var removed = false
        let now = Date()

        for session in sessions {
            var reason: String?

            if !session.tmuxPane.isEmpty, !session.tmuxSocket.isEmpty {
                if let found = probe(session.tmuxSocket) {
                    if let pane = found.panes.first(where: { $0.id == session.tmuxPane }) {
                        if session.phase.clearsWhenSeen, pane.visible {
                            reason = "seen in \(pane.id)"
                            acknowledge(session)
                        }
                    } else {
                        reason = "pane \(session.tmuxPane) gone"
                    }
                } else if now.timeIntervalSince(session.updatedAt) > maxAge {
                    reason = "tmux server unreachable, aged out"
                }
            } else if now.timeIntervalSince(session.updatedAt) > maxAge {
                reason = "no tmux coordinates, aged out"
            }

            if reason == nil, session.isRecovered, realPanes.contains(session.tmuxPane) {
                reason = "superseded by the session's own state file"
            }

            if reason == nil, let ttys, !session.tmuxTty.isEmpty,
               now.timeIntervalSince(session.updatedAt) > claudeGrace,
               !ttys.contains(session.ttyName) {
                reason = "no claude on \(session.ttyName)"
            }

            if let reason {
                try? FileManager.default.removeItem(at: session.file)
                log("dropped \(session.project) [\(session.phase.rawValue)]: \(reason)")
                removed = true
            }
        }

        if removed { reload() }
        if let ttys, let found = probe(nil) { recover(from: found, ttys: ttys) }
    }

    // Clearing a finished entry is an acknowledgement, and it has to outlive this
    // process: without a durable record, recovery below would resurrect the entry on
    // the next tick straight from the window glyph. Unsetting @claude_state is that
    // record — it also drops the glyph from the window name wherever tmux renders the
    // name itself. @claude_last is left alone: recovery still wants the message.
    private func acknowledge(_ session: Session) {
        guard let tmux = tmuxBin, !session.tmuxSocket.isEmpty, !session.tmuxPane.isEmpty
        else { return }
        let server = ["-S", session.tmuxSocket]

        // Read the name before clearing. With automatic-rename off — which is how a
        // window whose title Claude Code owns arrives — the format that renders
        // @claude_state never runs, so the glyph is baked into the name and unsetting
        // the option alone would leave it sitting there until the next hook event.
        let info = capture(tmux, server + [
            "display-message", "-p", "-t", session.tmuxPane, "#{automatic-rename}|#{window_name}",
        ])

        _ = capture(tmux, server + [
            "set-option", "-uw", "-t", session.tmuxPane, "@claude_state",
        ])

        guard let info else { return }
        let parts = info.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2, parts[0] == "0" else { return }

        // Idempotent, and only the five state glyphs: a window can also carry a
        // permanent icon of its own, which is not a state and must survive.
        var name = String(parts[1])
        var changed = false
        while let first = name.first, Self.phaseByGlyph.keys.contains(String(first)) {
            name.removeFirst()
            while name.first == " " { name.removeFirst() }
            changed = true
        }

        guard changed else { return }
        _ = capture(tmux, server + ["rename-window", "-t", session.tmuxPane, name])
        log("cleared state glyph from \(session.tmuxSession):\(session.tmuxWindow)")
    }

    // A Claude that was already waiting when its state file went missing would never
    // announce itself again: the next hook event is exactly the thing that is not
    // coming. So a pane running claude with no state file gets one written from what
    // tmux still knows. The hook stays the primary writer; this only fills gaps.
    //
    private func recover(from probe: (socket: String, panes: [PaneInfo]), ttys: Set<String>) {
        let claimed = Set(sessions.map(\.tmuxPane))

        for pane in probe.panes
        where ttys.contains(pane.ttyName) && !claimed.contains(pane.id) {
            // No glyph means either nothing has happened yet or the entry was
            // acknowledged; either way idle is the honest answer.
            let phase = Self.phaseByGlyph[pane.glyph] ?? .idle

            let payload: [String: Any] = [
                "session_id": "recovered-\(pane.ttyName)",
                "state": phase.rawValue,
                "project": (pane.path as NSString).lastPathComponent,
                "cwd": pane.path,
                "detail": pane.last,
                "tmux_socket": probe.socket,
                "tmux_session": pane.session,
                "tmux_window": pane.window,
                "tmux_pane": pane.id,
                "tmux_tty": pane.tty,
                "recovered": true,
                "updated_at": Date().timeIntervalSince1970.rounded(),
            ]
            guard let data = try? JSONSerialization.data(withJSONObject: payload) else { continue }

            let target = stateDir.appendingPathComponent("recovered-\(pane.ttyName).json")
            let tmp = target.appendingPathExtension("tmp")
            guard (try? data.write(to: tmp)) != nil else { continue }
            try? FileManager.default.removeItem(at: target)
            guard (try? FileManager.default.moveItem(at: tmp, to: target)) != nil else {
                try? FileManager.default.removeItem(at: tmp)
                continue
            }
            log("recovered \(pane.session):\(pane.window) [\(phase.rawValue)] from tmux")
        }
    }

    // launchd captures stderr to the path in the plist; a background app that drops
    // and re-adds entries on its own needs to be able to say why.
    private func log(_ message: String) {
        FileHandle.standardError.write(Data("claude-menubar: \(message)\n".utf8))
    }

    private func capture(_ path: String, _ args: [String]) -> String? {
        let proc = Process()
        let pipe = Pipe()
        proc.executableURL = URL(fileURLWithPath: path)
        proc.arguments = args
        proc.standardOutput = pipe
        proc.standardError = FileHandle.nullDevice
        do {
            try proc.run()
        } catch {
            return nil
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        proc.waitUntilExit()
        guard proc.terminationStatus == 0 else { return nil }
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: Icon

    // A placeholder is hidden the moment the real session writes its own file. It stays
    // in `sessions` so prune still sees it and deletes the leftover file — dropping it
    // here instead would leave the file behind forever, and claude-next.sh reads the
    // files directly, so prefix + j would keep landing on a session that is no longer
    // waiting.
    private var displayed: [Session] {
        let real = Set(sessions.filter { !$0.isRecovered }.map(\.tmuxPane))
        return sessions.filter { !($0.isRecovered && real.contains($0.tmuxPane)) }
    }

    private var active: [Session] { displayed.filter { $0.phase != .idle } }

    // A prompt that has gone unanswered for a while gets its own colour; everything
    // else keeps the colour of its phase.
    private func tint(_ session: Session) -> NSColor? {
        if session.phase == .waiting, Date().timeIntervalSince(session.updatedAt) > urgentAfter {
            return Kanagawa.samuraiRed
        }
        return session.phase.color
    }

    private func updateIcon() {
        let top = active.first
        let phase = top?.phase ?? .idle
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        var image = NSImage(systemSymbolName: phase.symbol, accessibilityDescription: phase.label)
            ?? NSImage(systemSymbolName: "circle.fill", accessibilityDescription: phase.label)

        if let color = top.flatMap(tint) ?? phase.color {
            image = image?.withSymbolConfiguration(
                config.applying(NSImage.SymbolConfiguration(paletteColors: [color]))
            )
            image?.isTemplate = false
        } else {
            image = image?.withSymbolConfiguration(config)
            image?.isTemplate = true
        }

        item.button?.image = image

        // Count only when it adds information: several sessions want attention.
        let peers = active.filter { $0.phase == phase }.count
        item.button?.title = peers > 1 ? " \(peers)" : ""
        let rows = displayed
        item.button?.toolTip = rows.isEmpty
            ? "Claude Code — no sessions"
            : rows
                .map { "\($0.project) — \($0.phase.label), \(shortAge($0.updatedAt))" }
                .joined(separator: "\n")
    }

    // MARK: Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        reload()
        menu.removeAllItems()

        let rows = displayed
        if rows.isEmpty {
            let empty = NSMenuItem(title: "No Claude sessions", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
        } else {
            for session in rows { menu.addItem(row(for: session)) }
        }

        menu.addItem(.separator())

        if rows.contains(where: { $0.phase.clearsWhenSeen }) {
            let clear = NSMenuItem(title: "Clear finished", action: #selector(clearFinished), keyEquivalent: "")
            clear.target = self
            menu.addItem(clear)
        }

        let quit = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
    }

    private func row(for session: Session) -> NSMenuItem {
        let row = NSMenuItem(title: session.project, action: nil, keyEquivalent: "")
        let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        let accent = tint(session)
        var icon = NSImage(systemSymbolName: session.phase.symbol, accessibilityDescription: nil)
        if let color = accent {
            icon = icon?.withSymbolConfiguration(
                config.applying(NSImage.SymbolConfiguration(paletteColors: [color]))
            )
            icon?.isTemplate = false
        } else {
            icon = icon?.withSymbolConfiguration(config)
            icon?.isTemplate = true
        }
        row.image = icon

        let title = NSMutableAttributedString(
            string: session.project,
            attributes: [
                .font: NSFont.menuFont(ofSize: 13),
                .foregroundColor: NSColor.labelColor,
            ]
        )
        var context = session.context.isEmpty ? "" : "\(session.context) · "
        context += session.phase.label
        if !session.isRecovered { context += " · \(shortAge(session.updatedAt))" }
        title.append(NSAttributedString(
            string: "  \(context)",
            attributes: [
                .font: NSFont.menuFont(ofSize: 11),
                .foregroundColor: accent ?? NSColor.secondaryLabelColor,
            ]
        ))
        if !session.detail.isEmpty {
            title.append(NSAttributedString(
                string: "\n\(session.detail)",
                attributes: [
                    .font: NSFont.menuFont(ofSize: 11),
                    .foregroundColor: NSColor.secondaryLabelColor,
                ]
            ))
        }
        row.attributedTitle = title

        if session.isJumpable {
            row.action = #selector(jump(_:))
            row.target = self
            row.representedObject = session
            row.isEnabled = true
        } else {
            row.isEnabled = false
        }
        return row
    }

    @objc private func jump(_ sender: NSMenuItem) {
        guard let session = sender.representedObject as? Session,
              FileManager.default.isExecutableFile(atPath: jumpTool.path)
        else { return }
        // Not waited on: raising kitty takes a moment and this runs on the main thread.
        let proc = Process()
        proc.executableURL = jumpTool
        proc.arguments = [session.tmuxSocket, session.tmuxSession, session.tmuxWindow, session.tmuxPane]
        proc.standardOutput = FileHandle.nullDevice
        proc.standardError = FileHandle.nullDevice
        try? proc.run()
    }

    @objc private func clearFinished() {
        for session in displayed where session.phase.clearsWhenSeen {
            acknowledge(session)
            try? FileManager.default.removeItem(at: session.file)
        }
        reload()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

// MARK: - Entry point

let home = URL(fileURLWithPath: NSHomeDirectory())
let root = home.appendingPathComponent(".local/state/claude-menubar")
try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

// Same override the hook honours. A test instance points at its own directory, so it
// also skips the single-instance lock — a second menu bar item is the point there.
let override = ProcessInfo.processInfo.environment["CLAUDE_MENUBAR_STATE_DIR"]
if override == nil {
    // One menu bar item per user, even if launchd and a manual run race.
    let lock = open(root.appendingPathComponent("lock").path, O_CREAT | O_RDWR, 0o644)
    if lock < 0 || flock(lock, LOCK_EX | LOCK_NB) != 0 { exit(0) }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let controller = Controller(
    stateDir: override.map { URL(fileURLWithPath: $0) }
        ?? root.appendingPathComponent("sessions")
)
app.run()
