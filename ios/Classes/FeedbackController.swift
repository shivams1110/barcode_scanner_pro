import AudioToolbox
import Foundation
import UIKit

/// Plays a short beep and/or a haptic tick when a barcode is detected, mirroring
/// the "scan accepted" cue commercial scanners (Scandit et al.) give the user.
///
/// Driven from the `FrameAnalyzer` emission path, which is already duplicate-
/// filtered, so each accepted (value+format) detection produces one cue. A local
/// throttle guards against cues piling up when several distinct codes land in the
/// same frame burst.
final class FeedbackController {
  private let soundEnabled: Bool
  private let vibrationEnabled: Bool

  // 1057 = the camera-shutter style "Tink"/beep system sound, a close match to a
  // scanner accept tone without bundling an audio asset.
  private let beepSoundId: SystemSoundID = 1057
  private let generator = UIImpactFeedbackGenerator(style: .medium)

  private var lastCue: CFTimeInterval = 0
  private let minInterval: CFTimeInterval = 0.2

  init(soundEnabled: Bool, vibrationEnabled: Bool) {
    self.soundEnabled = soundEnabled
    self.vibrationEnabled = vibrationEnabled
    if vibrationEnabled { generator.prepare() }
  }

  /// Fires the configured cue, throttled to `minInterval`.
  func onDetection() {
    guard soundEnabled || vibrationEnabled else { return }
    let now = CACurrentMediaTime()
    guard now - lastCue >= minInterval else { return }
    lastCue = now

    if soundEnabled {
      AudioServicesPlaySystemSound(beepSoundId)
    }
    if vibrationEnabled {
      DispatchQueue.main.async { [generator] in
        generator.impactOccurred()
        generator.prepare()
      }
    }
  }
}
