import Foundation

/// What a ``LoadingCard`` displays: the fraction complete, a status line, and the
/// dot-separated detail fields under it. Engine-agnostic on purpose — the app maps
/// its loader's callbacks (e.g. MLXEngine download/materialise/compile phases) into
/// one of these per update.
///
/// ```swift
/// LoadingProgress(
///     fraction: 0.29,
///     status: "Streaming weights",
///     fields: ["1.13 / 3.79 GB", "Tensor 193/851", "25 MB/s", "ETA 1:17"])
/// ```
public struct LoadingProgress: Equatable, Sendable {

    /// Fraction complete, clamped to 0...1 on display.
    public var fraction: Double
    /// The phase line ("Checking device support", "Streaming weights"). Rendered
    /// uppercase in the fleet's micro-header treatment.
    public var status: String
    /// Detail segments joined with " · " ("1.13 / 3.79 GB", "ETA 1:17"). Empty
    /// segments are dropped.
    public var fields: [String]

    public init(fraction: Double, status: String, fields: [String] = []) {
        self.fraction = fraction
        self.status = status
        self.fields = fields
    }

    // MARK: Display projections (pure, unit-tested)

    /// `fraction` clamped to the displayable range.
    public var clampedFraction: Double {
        fraction.isFinite ? min(max(fraction, 0), 1) : 0
    }

    /// The whole-number percentage, floored — 99.9% reads "99", and "100" appears
    /// only when the load is actually complete (the reference behaviour). The epsilon
    /// absorbs binary representation: 0.29 × 100 is 28.999999999999996, which must
    /// read "29", not "28".
    public var percent: Int {
        Int((clampedFraction * 100 + 1e-9).rounded(.down))
    }

    /// The fields line: non-empty segments joined with " · ", nil when there are none.
    public var fieldsLine: String? {
        let parts = fields
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
