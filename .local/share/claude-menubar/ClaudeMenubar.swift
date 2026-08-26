// ClaudeMenubar — menu bar indicator for running Claude Code sessions.
//
// State lives in ~/.local/state/claude-menubar/sessions/<session-id>.json, written
// atomically (write + rename) by the claude-tmux-notify hook. The rename is what
// makes the directory vnode fire, so the icon reflects a hook write within
// milliseconds without polling; the timer only prunes sessions whose tmux pane is
// gone (a session killed with ctrl-C never gets a SessionEnd hook).
//
// Build: .local/share/claude-menubar/build.sh

import AppKit

// MARK: - Palette

enum Kanagawa {
    static let springGreen = rgb(0x98, 0xbb, 0x6c)
    static let roninYellow = rgb(0xff, 0x9e, 0x3b)
    static let carpYellow = rgb(0xe6, 0xc3, 0x84)
    static let crystalBlue = rgb(0x7e, 0x9c, 0xd8)

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
    case done
    case idle

    var rank: Int {
        switch self {
        case .waiting: return 0
        case .working: return 1
        case .bgRunning: return 2
        case .done: return 3
        case .idle: return 4
        }
    }

    var symbol: String {
        switch self {
        case .waiting: return "bell.badge.fill"
        case .working: return "arrow.triangle.2.circlepath"
        case .bgRunning: return "hourglass"
        case .done: return "checkmark.circle.fill"
        case .idle: return "circle.dashed"
        }
    }

    var color: NSColor? {
        switch self {
        case .waiting: return Kanagawa.roninYellow
        case .working: return Kanagawa.crystalBlue
        case .bgRunning: return Kanagawa.carpYellow
        case .done: return Kanagawa.springGreen
        case .idle: return nil // template image, follows the menu bar
        }
    }

    var label: String {
        switch self {
        case .waiting: return "needs input"
        case .working: return "working"
        case .bgRunning: return "background task"
        case .done: return "finished"
        case .idle: return "idle"
        }
    }
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
        updatedAt = Date(timeIntervalSince1970: (obj["updated_at"] as? Double) ?? 0)
    }

    // "Home:2", empty when the session was not started inside tmux.
    var context: String {
        guard !tmuxSession.isEmpty else { return "" }
        return tmuxWindow.isEmpty ? tmuxSession : "\(tmuxSession):\(tmuxWindow)"
    }

    var isJumpable: Bool { !tmuxSocket.isEmpty && !tmuxSession.isEmpty }
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

    // A session whose pane is gone is dropped; one that is simply old is kept as
    // long as its pane lives, so a finished session stays clickable all day.
    private let maxAge: TimeInterval = 24 * 3600
    private let pruneInterval: TimeInterval = 30

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

    // Live pane ids on one tmux server, or nil when the server cannot be reached.
    // One list-panes covers every session: `display-message -t <pane>` is useless as
    // a liveness probe because a literal format string never resolves the target, so
    // it exits 0 for panes that do not exist.
    private func livePanes(socket: String) -> Set<String>? {
        guard let tmux = tmuxBin,
              let out = capture(tmux, ["-S", socket, "list-panes", "-a", "-F", "#{pane_id}"])
        else { return nil }
        return Set(out.split(separator: "\n").map(String.init))
    }

    // Drops sessions whose tmux pane is gone, plus anything ancient that was never in
    // tmux. An unreachable server falls back to age, so a tmux restart mid-session
    // does not wipe the list.
    private func prune() {
        var live: [String: Set<String>?] = [:]
        var removed = false
        let now = Date()

        for session in sessions {
            var dead: Bool
            if !session.tmuxPane.isEmpty, !session.tmuxSocket.isEmpty {
                let panes = live[session.tmuxSocket] ?? livePanes(socket: session.tmuxSocket)
                live[session.tmuxSocket] = panes
                dead = panes.map { !$0.contains(session.tmuxPane) }
                    ?? (now.timeIntervalSince(session.updatedAt) > maxAge)
            } else {
                dead = now.timeIntervalSince(session.updatedAt) > maxAge
            }
            if dead {
                try? FileManager.default.removeItem(at: session.file)
                removed = true
            }
        }

        if removed { reload() }
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

    private var active: [Session] { sessions.filter { $0.phase != .idle } }

    private func updateIcon() {
        let phase = active.first?.phase ?? .idle
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        var image = NSImage(systemSymbolName: phase.symbol, accessibilityDescription: phase.label)
            ?? NSImage(systemSymbolName: "circle.fill", accessibilityDescription: phase.label)

        if let color = phase.color {
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
        item.button?.toolTip = sessions.isEmpty
            ? "Claude Code — no sessions"
            : sessions.map { "\($0.project) — \($0.phase.label)" }.joined(separator: "\n")
    }

    // MARK: Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        reload()
        menu.removeAllItems()

        if sessions.isEmpty {
            let empty = NSMenuItem(title: "No Claude sessions", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
        } else {
            for session in sessions { menu.addItem(row(for: session)) }
        }

        menu.addItem(.separator())

        if sessions.contains(where: { $0.phase == .done }) {
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
        var icon = NSImage(systemSymbolName: session.phase.symbol, accessibilityDescription: nil)
        if let color = session.phase.color {
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
        let context = session.context.isEmpty ? session.phase.label : "\(session.context) · \(session.phase.label)"
        title.append(NSAttributedString(
            string: "  \(context)",
            attributes: [
                .font: NSFont.menuFont(ofSize: 11),
                .foregroundColor: session.phase.color ?? NSColor.secondaryLabelColor,
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
        for session in sessions where session.phase == .done {
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

// One menu bar item per user, even if launchd and a manual run race.
let lock = open(root.appendingPathComponent("lock").path, O_CREAT | O_RDWR, 0o644)
if lock < 0 || flock(lock, LOCK_EX | LOCK_NB) != 0 { exit(0) }

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let controller = Controller(stateDir: root.appendingPathComponent("sessions"))
app.run()
