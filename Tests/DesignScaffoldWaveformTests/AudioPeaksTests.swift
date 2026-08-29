import XCTest
@testable import DesignScaffoldWaveform

/// What the user SEES of their audio. A waveform that misrepresents the signal is worse than
/// none, because it is trusted — someone trims to what the picture shows.
final class AudioPeaksTests: XCTestCase {

    // MARK: Bucketing

    /// The load-bearing choice. Averaging would smear a transient into its neighbours and
    /// render the file as softer than it is, moving the target for anyone trimming to a beat.
    func testBucketTakesThePeakNotTheMean() {
        let samples: [Float] = [0.1, 0.1, 0.9, 0.1,  0.2, 0.2, 0.2, 0.2]
        XCTAssertEqual(AudioPeaks.bucket(samples, into: 2), [0.9, 0.2])
    }

    func testBucketReturnsExactlyTheRequestedCount() {
        let samples = (0..<1000).map { Float($0) / 1000 }
        for bars in [1, 7, 64, 999] {
            XCTAssertEqual(AudioPeaks.bucket(samples, into: bars).count, bars, "bars=\(bars)")
        }
    }

    /// Fewer samples than bars must NOT be stretched. Three measured levels are three bars,
    /// not three smeared across two hundred — that would claim detail never captured.
    func testFewerSamplesThanBarsAreNotStretched() {
        XCTAssertEqual(AudioPeaks.bucket([0.2, 0.4, 0.6], into: 200), [0.2, 0.4, 0.6])
    }

    /// Empty and silent are different states: the renderer draws a baseline for silence and
    /// nothing for absence, so the model must not conflate them.
    func testEmptyInputYieldsEmptyOutputNotZeros() {
        XCTAssertTrue(AudioPeaks.bucket([], into: 50).isEmpty)
        XCTAssertEqual(AudioPeaks.bucket([0, 0, 0, 0], into: 2), [0, 0])
    }

    func testZeroOrNegativeBarsIsEmpty() {
        XCTAssertTrue(AudioPeaks.bucket([0.5, 0.5], into: 0).isEmpty)
        XCTAssertTrue(AudioPeaks.bucket([0.5, 0.5], into: -3).isEmpty)
    }

    /// Signed PCM arrives with troughs as well as crests; a waveform draws magnitude.
    func testNegativeSamplesUseMagnitude() {
        XCTAssertEqual(AudioPeaks.bucket([-0.8, 0.2], into: 1), [0.8])
    }

    /// ⚠️ Non-finite is NO MEASUREMENT, not maximum. An infinity in a level buffer is a bug in
    /// the producer — a divide by zero in a dB conversion is the usual one — and drawing it as
    /// a full-height bar makes a confident claim about the audio ("the loudest thing here")
    /// out of a broken number. Silence is the honest rendering of a value that means nothing.
    ///
    /// This assertion originally expected `1.0` for infinity and the implementation was right.
    func testValuesAreClampedAndNonFiniteIsTreatedAsSilence() {
        XCTAssertEqual(AudioPeaks.bucket([4.0], into: 1), [1.0], "a finite overshoot IS loud")
        XCTAssertEqual(AudioPeaks.bucket([.nan], into: 1), [0.0])
        XCTAssertEqual(AudioPeaks.bucket([.infinity], into: 1), [0.0])
        XCTAssertEqual(AudioPeaks.bucket([-.infinity], into: 1), [0.0])
    }

    /// Every sample must land in some bucket — a bucketing that drops the tail silently loses
    /// the end of the file, which is exactly where a trim happens.
    func testNoSampleIsDropped() {
        let samples = [Float](repeating: 0, count: 97) + [1.0]     // the peak is last
        XCTAssertEqual(AudioPeaks.bucket(samples, into: 10).last, 1.0)
    }

    // MARK: Bar count

    func testBarCountFitsThePitch() {
        XCTAssertEqual(AudioPeaks.barCount(width: 100, barWidth: 2, spacing: 1), 33)
        XCTAssertEqual(AudioPeaks.barCount(width: 0, barWidth: 2, spacing: 1), 0)
        XCTAssertEqual(AudioPeaks.barCount(width: 1, barWidth: 2, spacing: 1), 1,
                       "a sliver of width still draws one bar rather than none")
    }

    /// A zero-pitch theme would divide by zero and take the app with it.
    func testDegenerateBarPitchDoesNotDivideByZero() {
        XCTAssertGreaterThan(AudioPeaks.barCount(width: 100, barWidth: 0, spacing: 0), 0)
    }

    // MARK: Rolling window

    func testRollingKeepsTheNewestAndDropsTheOldest() {
        var w: [Float] = [0.1, 0.2, 0.3]
        w = AudioPeaks.rolling(w, appending: 0.4, limit: 3)
        XCTAssertEqual(w, [0.2, 0.3, 0.4])
    }

    func testRollingFillsBeforeItSlides() {
        var w: [Float] = []
        for v in [Float(0.1), 0.2] { w = AudioPeaks.rolling(w, appending: v, limit: 5) }
        XCTAssertEqual(w, [0.1, 0.2])
    }

    func testRollingClampsWhatItStores() {
        XCTAssertEqual(AudioPeaks.rolling([], appending: 9, limit: 2), [1.0])
    }

    /// A shrinking limit must trim to it in one step, not one sample per append.
    func testRollingHonoursAShrunkLimitImmediately() {
        XCTAssertEqual(AudioPeaks.rolling([0.1, 0.2, 0.3, 0.4], appending: 0.5, limit: 2),
                       [0.4, 0.5])
    }

    // MARK: Slicing

    func testSliceTakesTheRequestedSeconds() {
        let peaks = (0..<100).map { Float($0) / 100 }        // 10 s at 10 peaks/s
        let s = AudioPeaks.slice(peaks, duration: 10, range: 2...4)
        XCTAssertEqual(s.count, 20)
        XCTAssertEqual(s.first, 0.2)
    }

    /// Drawing the WRONG part of a file is worse than drawing none, so an out-of-range window
    /// yields nothing rather than clamping into whatever is nearest.
    func testOutOfRangeSliceIsEmpty() {
        let peaks = (0..<100).map { _ in Float(0.5) }
        XCTAssertTrue(AudioPeaks.slice(peaks, duration: 10, range: 20...30).isEmpty)
        XCTAssertTrue(AudioPeaks.slice(peaks, duration: 0, range: 0...1).isEmpty)
        XCTAssertTrue(AudioPeaks.slice([], duration: 10, range: 0...1).isEmpty)
    }

    func testSliceAtTheHeadAndTail() {
        let peaks = (0..<100).map { Float($0) / 100 }
        XCTAssertEqual(AudioPeaks.slice(peaks, duration: 10, range: 0...1).first, 0.0)
        XCTAssertEqual(AudioPeaks.slice(peaks, duration: 10, range: 9...10).last, 0.99)
    }
}
