// Muse: turns the Magic Mouse surface into a mini trackpad.
// One finger slides the cursor, two fingers scroll; one-finger scrolling is blocked.
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

let args = CommandLine.arguments
let debug = args.contains("--debug")
func log(_ s: String) { FileHandle.standardError.write((s + "\n").data(using: .utf8)!) }

// Magic Mouse family IDs (Magic Mouse 1/2/USB-C). Trackpads are 98+ / 128+.
let mouseFamilies: Set<Int32> = [112, 113, 114]

// Shared state (touch callback thread <-> event tap on main thread)
let lock = NSLock()
var mouseDevices = Set<UInt>()
var knownDeviceIDs = Set<UInt64>()
var mouseFingers = 0
var sessionMax = 0            // max fingers since mouse surface was last empty
var lastTwoFinger = 0.0       // last time >= 2 fingers on mouse
var lastMouseTouch = 0.0
var lastOtherTouch = 0.0      // trackpad etc.

// ---- One-finger trackpad-style cursor ----
// Tune with: defaults write io.github.singhchinmayy.Muse <key> <value>; then restart the agent.
let prefs = UserDefaults.standard  // domain = bundle id io.github.singhchinmayy.Muse
let cursorEnabled = prefs.object(forKey: "cursorEnabled") as? Bool ?? true
let cursorSpeed = prefs.object(forKey: "cursorSpeed") as? Double ?? 1.0
let cursorAccel = prefs.object(forKey: "cursorAccel") as? Double ?? 1.0
let invertX = prefs.bool(forKey: "invertX")
let invertY = prefs.bool(forKey: "invertY")
let deadzone = prefs.object(forKey: "deadzone") as? Double ?? 0.03   // normalized surface units before cursor starts moving

var trackID: Int32 = -1               // touch path being followed
var lastPos = (x: 0.0, y: 0.0)
var startPos = (x: 0.0, y: 0.0)
var tracking = false                  // passed the deadzone
var remainder = (x: 0.0, y: 0.0)

func displayBounds() -> CGRect {
    var ids = [CGDirectDisplayID](repeating: 0, count: 16)
    var n: UInt32 = 0
    CGGetActiveDisplayList(16, &ids, &n)
    return ids.prefix(Int(n)).reduce(CGRect.null) { $0.union(CGDisplayBounds($1)) }
}

func moveCursor(dx: Double, dy: Double) {
    guard let loc = CGEvent(source: nil)?.location else { return }
    let b = displayBounds()
    let p = CGPoint(x: min(max(loc.x + dx, b.minX), b.maxX - 1), y: min(max(loc.y + dy, b.minY), b.maxY - 1))
    let left = CGEventSource.buttonState(.combinedSessionState, button: .left)
    let right = CGEventSource.buttonState(.combinedSessionState, button: .right)
    let type: CGEventType = left ? .leftMouseDragged : right ? .rightMouseDragged : .mouseMoved
    guard let e = CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: p,
                          mouseButton: right && !left ? .right : .left) else { return }
    e.setIntegerValueField(.mouseEventDeltaX, value: Int64(dx.rounded()))
    e.setIntegerValueField(.mouseEventDeltaY, value: Int64(dy.rounded()))
    e.post(tap: .cghidEventTap)
}

// Called with the single touching finger (or nil). Runs on the multitouch thread.
func handleOneFinger(id: Int32?, x: Double, y: Double) {
    guard cursorEnabled, let id else { trackID = -1; tracking = false; return }
    if id != trackID {                 // new finger (or 2 -> 1 transition): re-anchor, no jump
        trackID = id; lastPos = (x, y); startPos = (x, y); tracking = false; remainder = (0, 0)
        return
    }
    if !tracking {
        if hypot(x - startPos.x, y - startPos.y) < deadzone { lastPos = (x, y); return }
        tracking = true
    }
    var dx = x - lastPos.x, dy = y - lastPos.y
    lastPos = (x, y)
    // Surface is ~10x15 sensor cells; scale y so both axes feel equal.
    let speed = hypot(dx, dy * 1.5)
    let gain = 900.0 * cursorSpeed * (1 + cursorAccel * min(speed * 60, 3))
    dx *= gain * (invertX ? -1 : 1)
    dy *= gain * 1.5 * (invertY ? 1 : -1)   // surface y grows upward, screen y grows downward
    dx += remainder.x; dy += remainder.y
    let ix = dx.rounded(.towardZero), iy = dy.rounded(.towardZero)
    remainder = (dx - ix, dy - iy)
    if ix != 0 || iy != 0 {
        if debug { log("cursor dx=\(ix) dy=\(iy)") }
        moveCursor(dx: ix, dy: iy)
    }
}

let touchCallback: MTCallback = { dev, touches, n, _, _ in
    guard let dev else { return 0 }
    var count = 0
    var oneID: Int32 = 0, oneX = 0.0, oneY = 0.0
    if let t = touches {
        for i in 0..<Int(n) {
            // MTTouch is 96 bytes: id@16, state@20, normalized pos x@32 y@36. state 3=make, 4=touching, 5=break.
            let base = i * 96
            let state = t.load(fromByteOffset: base + 20, as: Int32.self)
            if state >= 3 && state <= 5 {
                count += 1
                oneID = t.load(fromByteOffset: base + 16, as: Int32.self)
                oneX = Double(t.load(fromByteOffset: base + 32, as: Float.self))
                oneY = Double(t.load(fromByteOffset: base + 36, as: Float.self))
            }
        }
    }
    let now = CFAbsoluteTimeGetCurrent()
    lock.lock()
    if mouseDevices.contains(UInt(bitPattern: dev)) {
        // Only one finger, and not right after a two-finger gesture.
        handleOneFinger(id: count == 1 && now - lastTwoFinger > 0.25 ? oneID : nil, x: oneX, y: oneY)
        if count > 0 {
            if mouseFingers == 0 { sessionMax = 0 }
            sessionMax = max(sessionMax, count)
            lastMouseTouch = now
            if count >= 2 { lastTwoFinger = now }
        }
        if debug && count != mouseFingers { log("mouse fingers: \(count)") }
        mouseFingers = count
    } else if count > 0 {
        lastOtherTouch = now
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
        let isNew = knownDeviceIDs.insert(id).inserted
        if isNew && mouseFamilies.contains(fam) { mouseDevices.insert(UInt(bitPattern: dev)) }
        lock.unlock()
        if isNew {
            log("device id=\(id) family=\(fam) \(mouseFamilies.contains(fam) ? "-> MAGIC MOUSE" : "")")
            _ = Unmanaged.passRetained(obj) // keep alive
            MTRegisterContactFrameCallback(dev, touchCallback)
            MTDeviceStart(dev, 0)
        }
    }
}

if args.contains("--probe") {
    scanDevices()
    exit(0)
}

var gTap: CFMachPort?

let tapCallback: CGEventTapCallBack = { _, type, event, _ in
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let gTap { CGEvent.tapEnable(tap: gTap, enable: true) }
        return Unmanaged.passUnretained(event)
    }
    guard type == .scrollWheel,
          event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0 // real wheels pass
    else { return Unmanaged.passUnretained(event) }

    let now = CFAbsoluteTimeGetCurrent()
    let momentum = event.getIntegerValueField(.scrollWheelEventMomentumPhase) != 0
    lock.lock()
    let fingers = mouseFingers, smax = sessionMax, l2 = lastTwoFinger
    let mouseIsSource = lastMouseTouch >= lastOtherTouch && (fingers > 0 || momentum || now - lastMouseTouch < 1.0)
    lock.unlock()
    guard mouseIsSource else { return Unmanaged.passUnretained(event) }

    let allow = ScrollGate.allow(fingers: fingers, sessionMax: smax, lastTwoFinger: l2, now: now, momentum: momentum)
    if debug && !allow { log("blocked scroll (fingers=\(fingers) momentum=\(momentum))") }
    return allow ? Unmanaged.passUnretained(event) : nil
}

func startTap() -> Bool {
    let mask = CGEventMask(1 << CGEventType.scrollWheel.rawValue)
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
    lock.lock(); knownDeviceIDs.removeAll(); mouseDevices.removeAll(); lock.unlock()
    scanDevices()
}
RunLoop.main.run()
