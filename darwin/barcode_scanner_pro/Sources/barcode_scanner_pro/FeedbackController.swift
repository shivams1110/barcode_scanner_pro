import AudioToolbox
import Foundation
import QuartzCore
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Plays a short beep and/or a haptic tick when a barcode is detected, mirroring
/// the "scan accepted" cue commercial scanners (Scandit et al.) give the user.
///
/// Driven from the `FrameAnalyzer` emission path, which is already duplicate-
/// filtered, so each accepted (value+format) detection produces one cue. A local
/// throttle guards against cues piling up when several distinct codes land in the
/// same frame burst.
///
/// macOS has no haptic engine, so `vibrationEnabled` is a no-op there and the
/// audible cue falls back to the system beep.
final class FeedbackController {
  private let soundEnabled: Bool
  private let vibrationEnabled: Bool

  // 1057 = the camera-shutter style "Tink"/beep system sound, a close match to a
  // scanner accept tone without bundling an audio asset.
  private let beepSoundId: SystemSoundID = 1057
  #if os(iOS)
  private let generator = UIImpactFeedbackGenerator(style: .medium)
  #endif

  private var lastCue: CFTimeInterval = 0
  private let minInterval: CFTimeInterval = 0.2

  init(soundEnabled: Bool, vibrationEnabled: Bool) {
    self.soundEnabled = soundEnabled
    self.vibrationEnabled = vibrationEnabled
    #if os(iOS)
    if vibrationEnabled { generator.prepare() }
    #endif
  }

  /// Fires the configured cue, throttled to `minInterval`.
  func onDetection() {
    guard soundEnabled || vibrationEnabled else { return }
    let now = CACurrentMediaTime()
    guard now - lastCue >= minInterval else { return }
    lastCue = now

    if soundEnabled {
      #if os(iOS)
      AudioServicesPlaySystemSound(beepSoundId)
      #elseif os(macOS)
      NSSound.beep()
      #endif
    }
    #if os(iOS)
    if vibrationEnabled {
      DispatchQueue.main.async { [generator] in
        generator.impactOccurred()
        generator.prepare()
      }
    }
    #endif
  }
}
