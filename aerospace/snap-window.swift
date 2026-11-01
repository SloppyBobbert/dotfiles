import Cocoa
import ApplicationServices
import Darwin

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data(("snap-window: " + message + "\n").utf8))
    exit(1)
}

func attribute(_ element: AXUIElement, _ key: String) -> CFTypeRef {
    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(element, key as CFString, &value)
    guard result == .success, let value = value else {
        fail("Cannot read \(key) (Accessibility error \(result.rawValue)).")
    }
    return value
}

func edgeAction(at point: CGPoint, in screen: CGRect) -> String? {
    guard screen.width > 16, screen.height > 0,
          point.x >= screen.minX, point.x <= screen.maxX,
          point.y >= screen.minY, point.y <= screen.maxY else { return nil }
    let side: String
    if point.x <= screen.minX + 8 { side = "left" }
    else if point.x >= screen.maxX - 8 { side = "right" }
    else { return nil }
    let fromTop = (screen.maxY - point.y) / screen.height
    if fromTop < 0.2 { return "top-" + side }
    if fromTop >= 0.8 { return "bottom-" + side }
    return side
}

func isWindowMove(from start: CGRect, to end: CGRect) -> Bool {
    return abs(start.width - end.width) < 1 && abs(start.height - end.height) < 1
        && max(abs(start.minX - end.minX), abs(start.minY - end.minY)) >= 6
}

final class EdgeDragWatcher {
    struct Drag {
        let window: AXUIElement
        let pid: pid_t
        let bundle: String
        let frame: CGRect
    }
    var drag: Drag?
    var generation = 0
    var monitor: Any?
    var preview: NSPanel?
    func value(_ element: AXUIElement, _ key: String) -> CFTypeRef? {
        var result: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, key as CFString, &result) == .success else { return nil }
        return result
    }

    func bounds(_ window: AXUIElement) -> CGRect? {
        guard let p = value(window, kAXPositionAttribute), CFGetTypeID(p) == AXValueGetTypeID(),
              let s = value(window, kAXSizeAttribute), CFGetTypeID(s) == AXValueGetTypeID() else { return nil }
        var origin = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(p as! AXValue, .cgPoint, &origin),
              AXValueGetValue(s as! AXValue, .cgSize, &size),
              origin.x.isFinite, origin.y.isFinite, size.width > 0, size.height > 0 else { return nil }
        return CGRect(origin: origin, size: size)
    }

    func windowAt(_ event: NSEvent) -> Drag? {
        guard let location = event.cgEvent?.location else { return nil }
        var hit: AXUIElement?
        guard AXUIElementCopyElementAtPosition(AXUIElementCreateSystemWide(), Float(location.x),
                                               Float(location.y), &hit) == .success, let element = hit else { return nil }
        let window: AXUIElement
        if value(element, kAXRoleAttribute) as? String == kAXWindowRole { window = element }
        else if let w = value(element, kAXWindowAttribute), CFGetTypeID(w) == AXUIElementGetTypeID() { window = w as! AXUIElement }
        else { return nil }
        var pid: pid_t = 0
        var movable = DarwinBoolean(false)
        var resizable = DarwinBoolean(false)
        guard AXUIElementGetPid(window, &pid) == .success, pid != getpid(),
              value(window, kAXSubroleAttribute) as? String == kAXStandardWindowSubrole,
              value(window, "AXFullScreen") as? Bool != true,
              AXUIElementIsAttributeSettable(window, kAXPositionAttribute as CFString, &movable) == .success,
              AXUIElementIsAttributeSettable(window, kAXSizeAttribute as CFString, &resizable) == .success,
              movable.boolValue, resizable.boolValue,
              let bundle = NSRunningApplication(processIdentifier: pid)?.bundleIdentifier,
              let frame = bounds(window) else { return nil }
        return Drag(window: window, pid: pid, bundle: bundle, frame: frame)
    }

    func focused(_ candidate: Drag) -> Bool {
        guard NSWorkspace.shared.frontmostApplication?.processIdentifier == candidate.pid,
              let current = value(AXUIElementCreateApplication(candidate.pid), kAXFocusedWindowAttribute),
              CFGetTypeID(current) == AXUIElementGetTypeID() else { return false }
        return CFEqual(current, candidate.window)
    }

    func zone(_ event: NSEvent) -> (NSScreen, String)? {
        guard let location = event.cgEvent?.location, let primary = NSScreen.screens.first else { return nil }
        let point = CGPoint(x: location.x, y: primary.frame.maxY - location.y)
        for screen in NSScreen.screens {
            if let action = edgeAction(at: point, in: screen.frame) { return (screen, action) }
        }
        return nil
    }

    func hidePreview() { preview?.orderOut(nil) }

    func showPreview(screen: NSScreen, action: String) {
        guard let primary = NSScreen.screens.first else { return }
        let visible = screen.visibleFrame
        let visibleTop = primary.frame.maxY - visible.maxY
        let top = max(visibleTop, primary.frame.maxY - screen.frame.maxY + 38)
        let available = CGRect(x: visible.minX, y: top, width: visible.width,
                               height: visible.height - (top - visibleTop))
        let target = frameForAction(action, in: available)
        let frame = CGRect(x: target.minX, y: primary.frame.maxY - target.maxY,
                           width: target.width, height: target.height).insetBy(dx: 4, dy: 4)
        if preview == nil {
            let panel = NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            panel.level = .floating
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false
            panel.ignoresMouseEvents = true
            panel.hidesOnDeactivate = false
            panel.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
            let view = NSView(frame: CGRect(origin: .zero, size: frame.size))
            view.wantsLayer = true
            view.layer?.backgroundColor = NSColor(white: 34 / 255, alpha: 0.4).cgColor
            view.layer?.borderColor = NSColor(srgbRed: 136 / 255, green: 165 / 255, blue: 125 / 255, alpha: 0.9).cgColor
            view.layer?.borderWidth = 2
            view.layer?.cornerRadius = 10
            panel.contentView = view
            preview = panel
        }
        if preview?.frame != frame { preview?.setFrame(frame, display: true) }
        preview?.orderFrontRegardless()
    }

    func apply(_ candidate: Drag, screen: NSScreen, action: String) {
        guard let display = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else { return }
        let token = generation
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let query = Process()
            let output = Pipe()
            let finished = DispatchSemaphore(value: 0)
            query.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/aerospace")
            query.arguments = ["list-windows", "--focused", "--format", "%{window-id}\t%{app-bundle-id}"]
            query.standardOutput = output
            query.standardError = FileHandle.nullDevice
            query.terminationHandler = { _ in finished.signal() }
            do { try query.run() } catch { return }
            guard finished.wait(timeout: .now() + 2) == .success else { query.terminate(); return }
            let text = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let parts = text.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "\t")
            guard query.terminationStatus == 0, parts.count == 2, parts[1] == candidate.bundle,
                  let id = Int(parts[0]), id > 0 else { return }
            DispatchQueue.main.async {
                guard let self = self, self.generation == token, self.focused(candidate),
                      !CGEventSource.buttonState(.combinedSessionState, button: .left) else { return }
                let snap = Process()
                snap.executableURL = URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL
                snap.arguments = [action, String(id), display.stringValue]
                do { try snap.run() } catch { self.hidePreview() }
            }
        }
    }

    func handle(_ event: NSEvent) {
        if event.type == .keyDown {
            // Escape cancels a drag; no key text is read or recorded.
            if event.keyCode == 53 { generation += 1; drag = nil; hidePreview() }
            return
        }
        if event.type == .leftMouseDown {
            generation += 1
            hidePreview()
            drag = windowAt(event)
            return
        }
        guard let candidate = drag else { return }
        guard focused(candidate), let current = bounds(candidate.window),
              isWindowMove(from: candidate.frame, to: current) else {
            hidePreview()
            if event.type == .leftMouseUp { drag = nil }
            return
        }
        if event.type == .leftMouseUp {
            drag = nil
            hidePreview()
            if let (screen, action) = zone(event) { apply(candidate, screen: screen, action: action) }
        } else if event.type == .leftMouseDragged {
            if let (screen, action) = zone(event) { showPreview(screen: screen, action: action) }
            else { hidePreview() }
        }
    }

    static func run(checkOnly: Bool) -> Never {
        guard AXIsProcessTrusted(), CGPreflightListenEventAccess() else {
            fail("Edge dragging needs Accessibility and input-listening access for AeroSpace or its launching terminal.")
        }
        let application = NSApplication.shared
        application.setActivationPolicy(.accessory)
        let events: NSEvent.EventTypeMask = [.leftMouseDown, .leftMouseDragged, .leftMouseUp, .keyDown]
        if checkOnly {
            guard let token = NSEvent.addGlobalMonitorForEvents(matching: events, handler: { _ in }) else { fail("Cannot monitor window drags.") }
            NSEvent.removeMonitor(token)
            print("EDGE_SNAP_ACCESS_OK")
            exit(0)
        }
        let path = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Caches/aerospace-edge-snap.pid").path
        let lock = open(path, O_CREAT | O_RDWR | O_NOFOLLOW, S_IRUSR | S_IWUSR)
        guard lock >= 0 else { fail("Cannot open the edge listener lock.") }
        guard flock(lock, LOCK_EX | LOCK_NB) == 0 else { exit(0) }
        let watcher = EdgeDragWatcher()
        guard let monitor = NSEvent.addGlobalMonitorForEvents(matching: events, handler: { [weak watcher] event in watcher?.handle(event) }) else { fail("Cannot monitor window drags.") }
        watcher.monitor = monitor
        let pid = String(getpid()) + "\n"
        guard ftruncate(lock, 0) == 0, pid.withCString({ Darwin.write(lock, $0, strlen($0)) }) == pid.utf8.count else { fail("Cannot record the edge listener PID.") }
        FileHandle.standardOutput.write(Data("Edge drag listener ready: top/bottom 20% quarters, middle 60% halves.\n".utf8))
        withExtendedLifetime(watcher) { application.run() }
        exit(0)
    }
}

let arguments = CommandLine.arguments
if arguments.count >= 2 && arguments[1] == "watch-edges" {
    guard arguments.count == 2 || (arguments.count == 3 && arguments[2] == "--check") else { fail("Use watch-edges [--check].") }
    EdgeDragWatcher.run(checkOnly: arguments.count == 3)
}
let actions = ["left", "right", "maximize", "top-left", "bottom-left", "top-right", "bottom-right",
               "home-zen", "home-terminal", "home-btop", "home-tv"]
guard (2...4).contains(arguments.count), actions.contains(arguments[1]),
      arguments.count == 2 || (Int(arguments[2]) ?? 0) > 0,
      arguments.count < 4 || (UInt32(arguments[3]) ?? 0) > 0 else {
    fail("Use left, right, maximize, top-left, bottom-left, top-right, bottom-right, home-zen, home-terminal, home-btop, or home-tv [window-id [display-id]].")
}
let action = arguments[1]
let expectedWindowID = arguments.count >= 3 ? arguments[2] : nil
let expectedDisplayID = arguments.count == 4 ? UInt32(arguments[3]) : nil
if expectedDisplayID != nil && CGEventSource.buttonState(.combinedSessionState, button: .left) {
    fail("A new mouse drag started before placement.")
}

func requireExpectedFocus(_ app: NSRunningApplication) {
    guard let expected = expectedWindowID else { return }
    let query = Process()
    let output = Pipe()
    query.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/aerospace")
    query.arguments = ["list-windows", "--focused", "--format", "%{window-id} %{app-bundle-id}"]
    query.standardOutput = output
    do { try query.run() } catch { fail("Cannot verify the focused window.") }
    let data = output.fileHandleForReading.readDataToEndOfFile()
    query.waitUntilExit()
    let focused = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    guard query.terminationStatus == 0, focused == expected + " " + (app.bundleIdentifier ?? "") else {
        fail("The focused window changed before placement.")
    }
}

func frameForAction(_ action: String, in available: CGRect) -> CGRect {
    let halfWidth = floor(available.width / 2)
    let halfHeight = floor(available.height / 2)
    let leftWidth = floor(available.width * 3 / 5)
    let zenHeight = floor(available.height * 4 / 5)
    switch action {
    case "home-zen":
        return CGRect(x: available.minX, y: available.minY, width: leftWidth, height: zenHeight)
    case "home-terminal":
        return CGRect(x: available.minX, y: available.minY + zenHeight,
                      width: leftWidth, height: available.height - zenHeight)
    case "home-btop":
        return CGRect(x: available.minX + leftWidth, y: available.minY,
                      width: available.width - leftWidth, height: halfHeight)
    case "home-tv":
        return CGRect(x: available.minX + leftWidth, y: available.minY + halfHeight,
                      width: available.width - leftWidth, height: available.height - halfHeight)
    default:
        break
    }
    let right = ["right", "top-right", "bottom-right"].contains(action)
    let quarter = ["top-left", "bottom-left", "top-right", "bottom-right"].contains(action)
    let bottom = ["bottom-left", "bottom-right"].contains(action)
    return CGRect(
        x: available.minX + (right ? halfWidth : 0),
        y: available.minY + (bottom ? halfHeight : 0),
        width: action == "maximize" ? available.width : (right ? available.width - halfWidth : halfWidth),
        height: quarter ? (bottom ? available.height - halfHeight : halfHeight) : available.height
    )
}
guard AXIsProcessTrusted() else { fail("Accessibility access is required.") }
guard let app = NSWorkspace.shared.frontmostApplication else {
    fail("No application is focused.")
}
requireExpectedFocus(app)
let element = attribute(AXUIElementCreateApplication(app.processIdentifier), kAXFocusedWindowAttribute)
guard CFGetTypeID(element) == AXUIElementGetTypeID() else { fail("No window is focused.") }
let window = element as! AXUIElement
if action == "maximize" || expectedWindowID != nil {
    // AeroSpace requests the exit; macOS completes the transition asynchronously.
    let deadline = Date().addingTimeInterval(5)
    while true {
        var fullscreen: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(window, "AXFullScreen" as CFString, &fullscreen)
        if result == .attributeUnsupported || (result == .success && fullscreen as? Bool == false) { break }
        guard Date() < deadline else { fail("The window did not leave macOS full screen.") }
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))
    }
    guard NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier,
          CFEqual(attribute(AXUIElementCreateApplication(app.processIdentifier), kAXFocusedWindowAttribute), window) else {
        fail("The focused window changed while leaving full screen.")
    }
    // Native full-screen exit can return a floating window to AeroSpace's tiled layout.
    let floating = Process()
    floating.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/aerospace")
    floating.arguments = ["layout"] + (expectedWindowID.map { ["--window-id", $0] } ?? []) + ["floating"]
    do { try floating.run() } catch { fail("Cannot restore the floating layout.") }
    floating.waitUntilExit()
    guard floating.terminationStatus == 0 else { fail("Cannot restore the floating layout.") }
}
let position = attribute(window, kAXPositionAttribute)
let size = attribute(window, kAXSizeAttribute)
guard CFGetTypeID(position) == AXValueGetTypeID(), CFGetTypeID(size) == AXValueGetTypeID() else {
    fail("The focused window has no readable bounds.")
}
var origin = CGPoint.zero
var dimensions = CGSize.zero
guard AXValueGetValue(position as! AXValue, .cgPoint, &origin),
      AXValueGetValue(size as! AXValue, .cgSize, &dimensions) else {
    fail("Cannot read the focused window bounds.")
}
let screens = NSScreen.screens
guard let primary = screens.first else { fail("No display is available.") }
func desktopRect(_ rect: CGRect) -> CGRect {
    CGRect(x: rect.minX, y: primary.frame.maxY - rect.maxY, width: rect.width, height: rect.height)
}
let current = CGRect(origin: origin, size: dimensions)
func overlap(_ screen: NSScreen) -> CGFloat {
    let rect = current.intersection(desktopRect(screen.frame))
    return rect.isNull ? 0 : rect.width * rect.height
}
let screen: NSScreen
if let displayID = expectedDisplayID {
    guard let selected = screens.first(where: {
        ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value == displayID
    }) else { fail("The drag display is no longer available.") }
    screen = selected
} else {
    screen = screens.max { overlap($0) < overlap($1) }!
}
var available = desktopRect(screen.visibleFrame)
if expectedWindowID != nil {
    // Startup layouts also leave room for the existing 38-point SketchyBar.
    let top = max(available.minY, desktopRect(screen.frame).minY + 38)
    available = CGRect(x: available.minX, y: top, width: available.width, height: available.maxY - top)
}
let target = frameForAction(action, in: available)
var targetOrigin = target.origin
var targetSize = target.size
requireExpectedFocus(app)
guard NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier,
      CFEqual(attribute(AXUIElementCreateApplication(app.processIdentifier), kAXFocusedWindowAttribute), window) else {
    fail("The focused window changed before placement.")
}
guard let newSize = AXValueCreate(.cgSize, &targetSize),
      let newPosition = AXValueCreate(.cgPoint, &targetOrigin) else {
    fail("Cannot create the target window bounds.")
}
// Resize before and after moving to avoid macOS screen-edge constraints.
for (key, value) in [(kAXSizeAttribute, newSize), (kAXPositionAttribute, newPosition),
                     (kAXSizeAttribute, newSize)] {
    if expectedDisplayID != nil && CGEventSource.buttonState(.combinedSessionState, button: .left) {
        fail("A new mouse drag started before placement.")
    }
    let result = AXUIElementSetAttributeValue(window, key as CFString, value)
    guard result == .success else { fail("Cannot set \(key) (Accessibility error \(result.rawValue)).") }
}
