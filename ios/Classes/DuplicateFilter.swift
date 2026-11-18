import Foundation

/// Suppresses repeat emissions of the same payload until it has gone unseen for
/// the timeout. Every sighting refreshes the timer, so a code held in view
/// emits once rather than every timeout. Mirrors the Android implementation;
/// lazily pruned to bound memory.
final class DuplicateFilter {
  private let timeout: TimeInterval
  private var lastSeen: [String: TimeInterval] = [:]
  private var lastPrune: TimeInterval = 0

  init(timeoutMs: Double) {
    self.timeout = timeoutMs / 1000.0
  }

  /// Records a sighting of `key`; true if it was unseen for at least the timeout.
  func shouldEmit(_ key: String, now: TimeInterval) -> Bool {
    let prev = lastSeen.updateValue(now, forKey: key)
    prune(now)
    return prev.map { now - $0 >= timeout } ?? true
  }

  private func prune(_ now: TimeInterval) {
    guard now - lastPrune >= timeout else { return }
    lastPrune = now
    lastSeen = lastSeen.filter { now - $0.value <= timeout }
  }

  func reset() { lastSeen.removeAll() }
}
