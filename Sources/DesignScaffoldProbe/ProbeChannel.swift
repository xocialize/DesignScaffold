//
//  ⚠️ macOS-only. This target is wrapped in `#if os(macOS)` because it is built on AppKit
//  API with no iOS equivalent — see `Docs/PLATFORMS.md`. On iOS the module compiles to
//  nothing, so an app that adds this product by mistake gets "cannot find X in scope"
//  rather than a wall of AppKit errors, and the package as a whole still builds.
//
#if os(macOS)

//
//  ProbeChannel.swift
//  DesignScaffoldProbe
//
//  The probe's other half: what a driver outside the app can ASK (named state), TELL (named
//  commands), and READ BACK (numbered events, main-thread stalls), with no stdout to capture.
//

import AppKit
import Foundation

/// State, commands and events an outside driver reads through the probe host
/// (`.designScaffoldProbeHost()`), over accessibility.
///
/// ## Why accessibility is the wire
///
/// A test driver already speaks it (it reads the app's menus and sheets that way), it needs no
/// entitlement in a sandboxed app (a socket or a loopback port would), and it reaches an app
/// however it was launched, Xcode included, where stdout isn't the driver's to read. The host is
/// one invisible element whose AX value is this channel's JSON snapshot; setting its value to a
/// JSON command runs the command, and the next read carries the reply.
///
/// ## Register what a check needs, nothing more
///
/// ```swift
/// HitTestProbe.state("document") {
///     ["size": [doc.width, doc.height], "layers": doc.layers.map(\.name),
///      "undo": undoManager.undoActionName]
/// }
/// HitTestProbe.command("canvas.drag") { args in
///     try canvas.drag(from: args.point("from"), to: args.point("to"))
///     return ["delivered": true]
/// }
/// ```
///
/// Providers run on the main thread, at read time, so a read is never stale. Keep them cheap:
/// a driver may read many times a second while it waits.
@MainActor
public extension HitTestProbe {

    /// Named state, computed fresh on every read. Return JSON-able values: strings, numbers,
    /// booleans, arrays, dictionaries, `nil`; `CGRect`, `CGPoint` and `CGSize` are converted.
    static func state(_ name: String, _ provider: @escaping @MainActor () -> Any?) {
        guard isEnabled else { return }
        ProbeChannel.states[name] = provider
        ProbeChannel.startIfNeeded()
    }

    /// A named command a driver can run. Runs on the main thread when the driver sets it; throw
    /// to report a failure the driver will read as such.
    static func command(_ name: String, _ handler: @escaping @MainActor (ProbeArgs) throws -> Any?) {
        guard isEnabled else { return }
        ProbeChannel.commands[name] = handler
        ProbeChannel.startIfNeeded()
    }

    /// An outcome of the app's own kind, numbered with the built-in ones (SELECTION, COMMIT…).
    static func event(_ kind: String, _ detail: String = "") {
        guard isEnabled else { return }
        emit("PROBE \(kind)\(detail.isEmpty ? "" : " " + detail)")
        ProbeChannel.append(kind, detail)
    }

    static func removeState(_ name: String) { ProbeChannel.states[name] = nil }
    static func removeCommand(_ name: String) { ProbeChannel.commands[name] = nil }
}

/// A command's arguments, with the conversions a driver's JSON needs.
public struct ProbeArgs: Sendable {
    public let raw: [String: ProbeValue]

    public func string(_ key: String) -> String? { raw[key]?.string }
    public func double(_ key: String) -> Double? { raw[key]?.double }
    public func int(_ key: String) -> Int? { raw[key]?.double.map { Int($0) } }
    public func bool(_ key: String) -> Bool? { raw[key]?.bool }

    /// `[x, y]` or `{"x": …, "y": …}`.
    public func point(_ key: String) throws -> CGPoint {
        if let a = raw[key]?.array, a.count == 2, let x = a[0].double, let y = a[1].double { return CGPoint(x: x, y: y) }
        if let o = raw[key]?.object, let x = o["x"]?.double, let y = o["y"]?.double { return CGPoint(x: x, y: y) }
        throw ProbeError("'\(key)' must be [x, y] or {\"x\":…, \"y\":…}")
    }

    public func points(_ key: String) throws -> [CGPoint] {
        guard let a = raw[key]?.array else { throw ProbeError("'\(key)' must be a list of points") }
        return try a.map { try ProbeArgs(raw: ["p": $0]).point("p") }
    }
}

/// A JSON value as a command receives it.
public enum ProbeValue: Sendable {
    case null, bool(Bool), number(Double), string(String), array([ProbeValue]), object([String: ProbeValue])

    init(_ any: Any) {
        switch any {
        case let n as NSNumber where CFGetTypeID(n) == CFBooleanGetTypeID(): self = .bool(n.boolValue)
        case let n as NSNumber: self = .number(n.doubleValue)
        case let s as String: self = .string(s)
        case let a as [Any]: self = .array(a.map(ProbeValue.init))
        case let o as [String: Any]: self = .object(o.mapValues(ProbeValue.init))
        default: self = .null
        }
    }

    public var string: String? { if case .string(let s) = self { return s }; return nil }
    public var double: Double? {
        switch self {
        case .number(let n): return n
        case .string(let s): return Double(s)
        default: return nil
        }
    }
    public var bool: Bool? { if case .bool(let b) = self { return b }; return nil }
    public var array: [ProbeValue]? { if case .array(let a) = self { return a }; return nil }
    public var object: [String: ProbeValue]? { if case .object(let o) = self { return o }; return nil }
}

/// A command's failure, as the driver reads it.
public struct ProbeError: Error, CustomStringConvertible, Sendable {
    public let description: String
    public init(_ description: String) { self.description = description }
}

/// The channel's storage, and the JSON the host serves.
@MainActor
enum ProbeChannel {
    static var states: [String: @MainActor () -> Any?] = [:]
    static var commands: [String: @MainActor (ProbeArgs) throws -> Any?] = [:]

    struct Event { let seq: Int; let kind: String; let detail: String; let time: TimeInterval }
    static var events: [Event] = []
    static var lastSeq = 0
    static let eventLimit = 1000

    static var reply: [String: Any]?

    static func append(_ kind: String, _ detail: String) {
        lastSeq += 1
        events.append(Event(seq: lastSeq, kind: kind, detail: detail, time: Heartbeat.now))
        if events.count > eventLimit { events.removeFirst(events.count - eventLimit) }
    }

    static func startIfNeeded() { Heartbeat.start() }

    /// What a read of the host returns: everything a driver polls, minus the event history,
    /// which it asks for with the `events` command so a wait doesn't move a thousand lines.
    static func snapshot() -> [String: Any] {
        var state: [String: Any] = [:]
        for (name, provider) in states { state[name] = jsonable(provider()) }
        var out: [String: Any] = [
            "v": 1,
            "app": Bundle.main.bundleIdentifier ?? ProcessInfo.processInfo.processName,
            "last_seq": lastSeq,
            "targets": HitTestProbe.currentTargets().map { ["name": $0.name, "x": $0.x, "y": $0.y, "w": $0.w, "h": $0.h] },
            "state": state,
            "commands": (commands.keys.sorted() + ["events", "ping"]),
            "heartbeat": Heartbeat.summary(),
        ]
        if let reply { out["reply"] = reply }
        return out
    }

    static func serialized() -> String {
        let data = (try? JSONSerialization.data(withJSONObject: snapshot(), options: [.sortedKeys])) ?? Data("{}".utf8)
        return String(decoding: data, as: UTF8.self)
    }

    /// Runs a command the driver wrote: `{"id": "…", "command": "name", "args": {…}}`.
    static func run(_ text: String) {
        guard let object = try? JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any] else {
            reply = ["id": NSNull(), "ok": false, "error": "not a JSON command object"]
            return
        }
        let id = object["id"] ?? NSNull()
        let name = object["command"] as? String ?? ""
        let args = ProbeArgs(raw: (object["args"] as? [String: Any] ?? [:]).mapValues(ProbeValue.init))
        do {
            let result: Any?
            switch name {
            case "ping": result = ["pong": true]
            case "events":
                let since = args.int("since") ?? 0
                result = ["last_seq": lastSeq,
                          "events": events.filter { $0.seq > since }.map {
                              ["seq": $0.seq, "kind": $0.kind, "detail": $0.detail, "t": $0.time] }]
            default:
                guard let handler = commands[name] else {
                    throw ProbeError("no command '\(name)'; this app has: \(commands.keys.sorted().joined(separator: ", "))")
                }
                result = try handler(args)
            }
            reply = ["id": id, "ok": true, "result": jsonable(result), "last_seq": lastSeq]
        } catch {
            reply = ["id": id, "ok": false, "error": String(describing: error), "last_seq": lastSeq]
        }
    }

    /// Anything a provider returns, as something JSONSerialization accepts.
    static func jsonable(_ value: Any?) -> Any {
        switch value {
        case nil: return NSNull()
        case let v as String: return v
        case let v as Bool: return v
        case let v as Int: return v
        case let v as Double: return v.isFinite ? v : NSNull()
        case let v as CGFloat: return v.isFinite ? Double(v) : NSNull()
        case let v as Float: return v.isFinite ? Double(v) : NSNull()
        case let v as NSNumber: return v
        case let v as CGRect: return ["x": v.minX, "y": v.minY, "w": v.width, "h": v.height]
        case let v as CGPoint: return ["x": v.x, "y": v.y]
        case let v as CGSize: return ["w": v.width, "h": v.height]
        case let v as [Any?]: return v.map(jsonable)
        case let v as [String: Any?]: return v.mapValues(jsonable)
        case let v as URL: return v.path
        case let v?: return String(describing: v)
        }
    }
}

// MARK: - Main-thread heartbeat

/// How long the main thread kept the app from answering, measured from outside it.
///
/// A background timer asks the main queue to note the time every 50 ms; when the answer comes late,
/// that's a stall. A checklist's "the app stays responsive while it runs" becomes a number: the
/// longest stall since the action started. The driver can't read the app *during* a stall (its
/// accessibility requests wait for the same main thread), so stalls are kept and read after.
enum Heartbeat {
    static let interval = 0.05
    static let threshold = 0.1
    nonisolated(unsafe) private static var timer: DispatchSourceTimer?
    private static let lock = NSLock()
    nonisolated(unsafe) private static var stalls: [(at: Double, ms: Double)] = []
    nonisolated(unsafe) private static var worst = 0.0
    nonisolated(unsafe) private static var beats = 0

    static var now: Double { ProcessInfo.processInfo.systemUptime }

    static func start() {
        lock.lock(); defer { lock.unlock() }
        guard timer == nil else { return }
        let t = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInteractive))
        t.schedule(deadline: .now() + interval, repeating: interval, leeway: .milliseconds(5))
        t.setEventHandler {
            let asked = now
            DispatchQueue.main.async {
                let late = now - asked
                lock.lock(); defer { lock.unlock() }
                beats += 1
                // One blocked stretch delays every beat queued behind it; count it once, as the
                // first (longest) late beat measured it, not once per beat.
                if late > threshold, stalls.last.map({ $0.at + $0.ms / 1000 < asked }) ?? true {
                    stalls.append((at: asked, ms: (late * 1000).rounded()))
                    if stalls.count > 200 { stalls.removeFirst(stalls.count - 200) }
                }
                worst = max(worst, late)
            }
        }
        t.resume()
        timer = t
    }

    /// `now` is the app's uptime clock, the same one events carry, so a driver can ask for the
    /// stalls after a moment it noted.
    static func summary() -> [String: Any] {
        lock.lock(); defer { lock.unlock() }
        return ["now": now, "interval_ms": interval * 1000, "threshold_ms": threshold * 1000,
                "beats": beats, "worst_ms": (worst * 1000).rounded(),
                "stalls": stalls.suffix(50).map { ["at": $0.at, "ms": $0.ms] }]
    }
}

#endif
