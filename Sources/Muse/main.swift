// Muse: turns the Magic Mouse surface into a mini trackpad.
// One finger slides the cursor, two fingers scroll; one-finger scrolling is blocked.
// This file is the engine (multitouch + scroll event tap); the menu bar lives in MenuBar.swift.
// Usage: Muse [--probe] [--debug]
import Cocoa
import CoreGraphics
import ApplicationServices
import MuseCore

typealias MTDeviceRef = UnsafeMutableRawPointer
typealias MTCallback = @convention(c) (MTDeviceRef?, UnsafeMutableRawPointer?, Int32, Double, Int32) -> Int32

let mt = dlopen("/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport", RTLD_NOW)!
func sym<T>(_ name: String, _: T.Type) -> T { unsafeBitCast(dlsym(mt, name)!, to: T.self) }
let MTDeviceCreateList = sym("MTDeviceCreateList", (@convention(c) () -> Unmanaged<CFArray>).self)
let MTRegisterContactFrameCallback = sym("MTRegisterContactFrameCallback", (@convention(c) (MTDeviceRef, MTCallback) -> Void).self)
let MTDeviceStart = sym("MTDeviceStart", (@convention(c) (MTDeviceRef, Int32) -> Void).self)
let MTDeviceGetFamilyID = sym("MTDeviceGetFamilyID", (@convention(c) (MTDeviceRef, UnsafeMutablePointer<Int32>) -> Int32).self)
let MTDeviceGetDeviceID = sym("MTDeviceGetDeviceID", (@convention(c) (MTDeviceRef, UnsafeMutablePointer<UInt64>) -> Int32).self)

let options = LaunchOptions(arguments: CommandLine.arguments)
let debug = options.debug
func log(_ s: String) { FileHandle.standardError.write((s + "\n").data(using: .utf8)!) }

// Shared state (touch callback thread <-> event tap on main thread)
let lock = NSLock()
var devices = DeviceRegistry()
let session = TouchSession()

// ---- Settings ----
// Live copy of the prefs in defaults (domain io.github.singhchinmayy.Muse). The menu bar and
// Settings window edit them through SettingsModel, which calls applySettings.
var settings = Settings.load(from: .standard)   // guarded by `lock`
func applySettings(_ s: Settings) { lock.lock(); settings = s; lock.unlock() }

// ---- One-finger trackpad-style cursor, tap to click ----
let cursor = CursorTracker()
let tapper = TapDetector(doubleClickInterval: NSEvent.doubleClickInterval)
// Tags events Muse posts so the event tap can tell them from hardware.
let museEventTag: Int64 = 0x4D757365   // "Muse"

func displayBounds() -> CGRect {
    var ids = [CGDirectDisplayID](repeating: 0, count: 16)
    var n: UInt32 = 0
    CGGetActiveDisplayList(16, &ids, &n)
    return CursorPlacement.union(ids.prefix(Int(n)).map(CGDisplayBounds))
}

func moveCursor(dx: Double, dy: Double) {
    guard let loc = CGEvent(source: nil)?.location else { return }
    let p = CursorPlacement.clamp(CGPoint(x: loc.x + dx, y: loc.y + dy), to: displayBounds())
    let kind = CursorPlacement.event(leftDown: CGEventSource.buttonState(.combinedSessionState, button: .left),
                                     rightDown: CGEventSource.buttonState(.combinedSessionState, button: .right))
    guard let e = CGEvent(mouseEventSource: nil, mouseType: kind.type, mouseCursorPosition: p,
                          mouseButton: kind.button) else { return }
    e.setIntegerValueField(.mouseEventDeltaX, value: Int64(dx.rounded()))
    e.setIntegerValueField(.mouseEventDeltaY, value: Int64(dy.rounded()))
    e.setIntegerValueField(.eventSourceUserData, value: museEventTag)
    e.post(tap: .cghidEventTap)
}

func click(count: Int) {
    guard let loc = CGEvent(source: nil)?.location else { return }
    for type in [CGEventType.leftMouseDown, .leftMouseUp] {
        guard let e = CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: loc,
                              mouseButton: .left) else { continue }
        e.setIntegerValueField(.mouseEventClickState, value: Int64(count))
        e.setIntegerValueField(.eventSourceUserData, value: museEventTag)
        e.post(tap: .cghidEventTap)
    }
}

// Called with the single touching finger (or nil). Runs on the multitouch thread, holding `lock`.
func handleOneFinger(id: Int32?, x: Double, y: Double) {
    guard let (dx, dy) = cursor.update(id: id, x: x, y: y, settings: settings) else { return }
    if debug { log("cursor dx=\(dx) dy=\(dy)") }
    moveCursor(dx: dx, dy: dy)
}

let touchCallback: MTCallback = { dev, touches, n, _, _ in
    guard let dev else { return 0 }
    let active = TouchFrame.activeTouches(touches, count: Int(n))
    let count = active.count
    let one = active.last ?? Touch(id: 0, x: 0, y: 0)
    let oneID = one.id, oneX = one.x, oneY = one.y
    let now = CFAbsoluteTimeGetCurrent()
    lock.lock()
    if devices.isMouse(handle: UInt(bitPattern: dev)) {
        if debug && count != session.mouseFingers { log("mouse fingers: \(count)") }
        let cursorAllowed = session.mouseFrame(fingers: count, now: now)
        handleOneFinger(id: cursorAllowed ? oneID : nil, x: oneX, y: oneY)
        if let n = tapper.frame(touches: active, now: now, settings: settings) {
            if debug { log("tap click x\(n)") }
            click(count: n)
        }
    } else {
        session.otherFrame(fingers: count, now: now)
    }
    lock.unlock()
    return 0
}

func scanDevices() {
    let list = MTDeviceCreateList().takeRetainedValue() as [AnyObject]
    for obj in list {
        let dev = Unmanaged.passUnretained(obj).toOpaque()
        var id: UInt64 = 0, fam: Int32 = 0
        _ = MTDeviceGetDeviceID(dev, &id)
        _ = MTDeviceGetFamilyID(dev, &fam)
        lock.lock()
        let isNew = devices.register(id: id, family: fam, handle: UInt(bitPattern: dev))
        lock.unlock()
        if isNew {
            log("device id=\(id) family=\(fam) \(DeviceRegistry.isMagicMouse(family: fam) ? "-> MAGIC MOUSE" : "")")
            _ = Unmanaged.passRetained(obj) // keep alive
            MTRegisterContactFrameCallback(dev, touchCallback)
            MTDeviceStart(dev, 0)
        }
    }
}

// Fresh check for the menu's status line (the scan list keeps stale devices until wake).
func magicMouseConnected() -> Bool {
    let list = MTDeviceCreateList().takeRetainedValue() as [AnyObject]
    return list.contains { obj in
        var fam: Int32 = 0
        _ = MTDeviceGetFamilyID(Unmanaged.passUnretained(obj).toOpaque(), &fam)
        return DeviceRegistry.isMagicMouse(family: fam)
    }
}

if options.probe {
    scanDevices()
    exit(0)
}

var gTap: CFMachPort?
// Where the cursor was after the last move we let through (main thread only).
var lastCursor = CGEvent(source: nil)?.location ?? .zero

let buttonDowns: Set<CGEventType> = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
let motions: Set<CGEventType> = [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]

let tapCallback: CGEventTapCallBack = { _, type, event, _ in
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let gTap { CGEvent.tapEnable(tap: gTap, enable: true) }
        return Unmanaged.passUnretained(event)
    }
    let synthetic = event.getIntegerValueField(.eventSourceUserData) == museEventTag
    if buttonDowns.contains(type) {
        if !synthetic { lock.lock(); tapper.buttonPressed(); lock.unlock() }   // a real click is not a tap
        return Unmanaged.passUnretained(event)
    }
    if motions.contains(type) {
        lock.lock()
        let allow = session.allowPointerMotion(synthetic: synthetic, now: CFAbsoluteTimeGetCurrent(), settings: settings)
        lock.unlock()
        if allow { lastCursor = event.location; return Unmanaged.passUnretained(event) }
        // The cursor has already moved by the time a tap sees the event: put it back.
        CGWarpMouseCursorPosition(lastCursor)
        CGAssociateMouseAndMouseCursorPosition(1)   // undo the brief freeze a warp causes
        if debug { log("blocked optical move") }
        return nil
    }
    guard type == .scrollWheel else { return Unmanaged.passUnretained(event) }
    let continuous = event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0
    let momentum = event.getIntegerValueField(.scrollWheelEventMomentumPhase) != 0
    lock.lock()
    let allow = session.allowScroll(continuous: continuous, momentum: momentum,
                                    now: CFAbsoluteTimeGetCurrent(), enabled: settings.enabled)
    let fingers = session.mouseFingers
    lock.unlock()
    if debug && !allow { log("blocked scroll (fingers=\(fingers) momentum=\(momentum))") }
    return allow ? Unmanaged.passUnretained(event) : nil
}

func startTap() -> Bool {
    let mask = ([.scrollWheel] + buttonDowns + motions).reduce(CGEventMask(0)) { $0 | 1 << $1.rawValue }
    guard let tap = CGEvent.tapCreate(tap: .cghidEventTap, place: .headInsertEventTap,
                                      options: .defaultTap, eventsOfInterest: mask,
                                      callback: tapCallback, userInfo: nil) else { return false }
    gTap = tap
    let src = CFMachPortCreateRunLoopSource(nil, tap, 0)
    CFRunLoopAddSource(CFRunLoopGetMain(), src, .commonModes)
    CGEvent.tapEnable(tap: tap, enable: true)
    log("event tap running")
    return true
}

_ = AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary)
scanDevices()

if !startTap() {
    log("waiting for Accessibility permission...")
    Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { t in
        if startTap() { t.invalidate() }
    }
}
// Pick up the mouse again after reconnect / sleep.
Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in scanDevices() }
NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { _ in
    lock.lock(); devices.reset(); lock.unlock()
    scanDevices()
}
let app = NSApplication.shared
let appDelegate = AppDelegate()
app.delegate = appDelegate
app.run()
