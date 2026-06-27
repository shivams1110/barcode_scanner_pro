import Foundation

/// Suppresses repeat emissions of the same payload within a timeout window.
/// Mirrors the Android implementation; lazily pruned to bound memory.
final class DuplicateFilter {
  private let timeout: TimeInterval
  private var lastSeen: [String: TimeInterval] = [:]
  private var lastPrune: TimeInterval = 0

  init(timeoutMs: Double) {
    self.timeout = timeoutMs / 1000.0
  }

  func shouldEmit(_ key: String, now: TimeInterval) -> Bool {
    if let prev = lastSeen[key], now - prev < timeout { return false }
    lastSeen[key] = now
    prune(now)
    return true
  }

  private func prune(_ now: TimeInterval) {
    guard now - lastPrune >= timeout else { return }
    lastPrune = now
    lastSeen = lastSeen.filter { now - $0.value <= timeout }
  }

  func reset() { lastSeen.removeAll() }
}
