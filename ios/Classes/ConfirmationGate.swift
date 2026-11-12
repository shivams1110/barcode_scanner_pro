import Foundation

/// Withholds a detection until the same payload has been decoded `required`
/// times inside `window` **and** has been seen more often than all competing
/// readings put together. Mirrors the Android implementation.
///
/// Barcode engines report a decode with no confidence score, and symbologies
/// without a mandatory check digit (Code 39, Code 93, ITF, Codabar) can produce
/// a *structurally valid but wrong* payload from a marginal frame — e.g. Code 39
/// `A218219` read as `A218279`. A count alone does not stop that: while a code is
/// held in view, an occasional misread soon reaches any small count. The genuine
/// payload is still read far more often, so the misread loses the vote. And
/// when the engine flips between several values with none in the majority, the
/// image is too poor to trust and nothing is emitted at all.
///
/// Two payloads decoded in the same frame are different physical codes, not
/// competing readings of one, and never outvote each other.
///
/// Sits ahead of `DuplicateFilter`: votes must be fed by every decode, including
/// the repeats the duplicate filter suppresses.
final class ConfirmationGate {
  private let required: Int
  private let window: CFTimeInterval
  /// payload key -> frame times still inside the window.
  private var seen: [String: [CFTimeInterval]] = [:]

  init(required: Int, window: CFTimeInterval = 1.0) {
    self.required = required
    self.window = window
  }

  /// Records a sighting of `key` in the frame at `now`; true once it is
  /// trusted.
  func confirm(_ key: String, now: CFTimeInterval) -> Bool {
    if required <= 1 { return true }
    prune(now)

    var mine = seen[key] ?? []
    if mine.last != now { mine.append(now) }
    seen[key] = mine

    // ponytail: switching straight from one code to another waits (under half
    // the window) for the new one to overtake the previous one's votes; shrink
    // `window` if that hand-off ever feels slow.
    let rivals = seen.reduce(0) { sum, entry in
      entry.key == key || entry.value.contains(where: mine.contains)
        ? sum : sum + entry.value.count
    }
    return mine.count >= required && mine.count > rivals
  }

  func reset() { seen.removeAll() }

  private func prune(_ now: CFTimeInterval) {
    seen = seen.compactMapValues { times in
      let fresh = times.filter { now - $0 <= window }
      return fresh.isEmpty ? nil : fresh
    }
  }
}
