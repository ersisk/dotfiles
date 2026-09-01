// ZenPipDefocus — keeps Picture-in-Picture from holding the browser's AXMain window.
//
// cmd+tab is macOS's own app switcher and it raises whichever window the app marks
// AXMain. Zen marks the PiP window AXMain the moment it is born, so cmd+tab lands on
// the floating video instead of the page behind it.
//
// AeroSpace cannot drive this: it never enumerates the PiP window, so once PiP holds
// AXMain its focus events stop firing entirely — measured, four cmd+tab switches in a
// row produced no callback at all. It also misses the common case where the PiP is
// created seconds AFTER you have already switched away.
//
// Zen turned out not to emit window notifications for the PiP window either, so the
// AX observer alone caught nothing. The timer below is what actually holds the line;
// the observer stays because when it does fire it corrects within milliseconds.
//
// Build: .local/share/zen-pip-defocus/build.sh

import AppKit
import ApplicationServices

private let pipTitle = "Picture-in-Picture"
private let watchedBundleIDs: Set<String> = ["app.zen-browser.zen", "org.mozilla.firefox"]

// A freshly created window often has no title yet, so one look is not enough.
private let recheckDelays: [TimeInterval] = [0.15, 0.5]

// An AX round trip inside the process costs about a millisecond, so a poll this often
// is a rounding error — the 140ms in the old shell version was osascript startup.
private let pollInterval: TimeInterval = 1.0

// Set ZEN_PIP_DEBUG=1 to trace what the observer sees; silent otherwise.
private let debug = ProcessInfo.processInfo.environment["ZEN_PIP_DEBUG"] != nil
private let logStamp: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "HH:mm:ss.SSS"
    return f
}()

private func log(_ message: @autoclosure () -> String) {
    guard debug else { return }
    FileHandle.standardError.write(Data("\(logStamp.string(from: Date())) \(message())\n".utf8))
}

private func attribute<T>(_ element: AXUIElement, _ name: String) -> T? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
    return value as? T
}

private func isPiP(_ window: AXUIElement) -> Bool {
    (attribute(window, kAXTitleAttribute) ?? "").contains(pipTitle)
}

private final class Watch {
    let element: AXUIElement
    var observer: AXObserver?
    // The poll runs every second; logging only transitions keeps the trace readable.
    private var lastState = ""

    init(pid: pid_t) { element = AXUIElementCreateApplication(pid) }

    func check(_ source: String) {
        guard let windows: [AXUIElement] = attribute(element, kAXWindowsAttribute) else { return }

        let state = windows.map {
            "[\(attribute($0, kAXTitleAttribute) ?? "")]main=\(attribute($0, kAXMainAttribute) ?? false)"
        }.joined(separator: " ")
        if state != lastState {
            log("\(source): \(state)")
            lastState = state
        }

        // Leave it alone unless PiP actually holds AXMain, so a raise never fights the user.
        guard windows.contains(where: { isPiP($0) && (attribute($0, kAXMainAttribute) ?? false) }) else { return }
        // The window list runs front to back, so the first non-PiP entry is the last one used.
        guard let target = windows.first(where: { !isPiP($0) }) else { return }
        let result = AXUIElementPerformAction(target, kAXRaiseAction as CFString)
        log("  -> raise [\(attribute(target, kAXTitleAttribute) ?? "")] result=\(result.rawValue)")
        lastState = ""
    }

    func checkWithRechecks(_ source: String) {
        check(source)
        for delay in recheckDelays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in self?.check("\(source)+\(delay)s") }
        }
    }
}

private var watches: [pid_t: Watch] = [:]

private let axCallback: AXObserverCallback = { _, _, notification, refcon in
    guard let refcon else { return }
    Unmanaged<Watch>.fromOpaque(refcon).takeUnretainedValue().checkWithRechecks(notification as String)
}

private func attach(_ app: NSRunningApplication) {
    guard let bundleID = app.bundleIdentifier, watchedBundleIDs.contains(bundleID) else { return }
    let pid = app.processIdentifier
    guard watches[pid] == nil else { return }

    var observer: AXObserver?
    guard AXObserverCreate(pid, axCallback, &observer) == .success, let observer else {
        log("AXObserverCreate failed pid=\(pid)")
        return
    }

    let watch = Watch(pid: pid)
    watch.observer = observer
    watches[pid] = watch

    let refcon = Unmanaged.passUnretained(watch).toOpaque()
    for note in [kAXWindowCreatedNotification, kAXMainWindowChangedNotification,
                 kAXFocusedWindowChangedNotification, kAXApplicationActivatedNotification] {
        let result = AXObserverAddNotification(observer, watch.element, note as CFString, refcon)
        log("register \(note) -> \(result.rawValue)")
    }
    CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .defaultMode)

    log("attached pid=\(pid) \(bundleID)")
    watch.checkWithRechecks("attach")
}

private func detach(_ app: NSRunningApplication) {
    guard let watch = watches.removeValue(forKey: app.processIdentifier),
          let observer = watch.observer else { return }
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .defaultMode)
    log("detached pid=\(app.processIdentifier)")
}

// Exiting here would crash-loop under KeepAlive, so ask once and wait for the grant.
if !AXIsProcessTrusted() {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
    _ = AXIsProcessTrustedWithOptions(options)
    FileHandle.standardError.write(Data("zen-pip-defocus: waiting for Accessibility permission\n".utf8))
    while !AXIsProcessTrusted() { Thread.sleep(forTimeInterval: 2) }
}

let center = NSWorkspace.shared.notificationCenter
for (name, handler) in [(NSWorkspace.didLaunchApplicationNotification, attach),
                        (NSWorkspace.didTerminateApplicationNotification, detach)] {
    center.addObserver(forName: name, object: nil, queue: .main) { note in
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        handler(app)
    }
}
NSWorkspace.shared.runningApplications.forEach(attach)

Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { _ in
    watches.values.forEach { $0.check("poll") }
}

CFRunLoopRun()
