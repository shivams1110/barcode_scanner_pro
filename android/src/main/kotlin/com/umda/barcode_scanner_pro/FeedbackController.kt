package com.umda.barcode_scanner_pro

import android.content.Context
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

/**
 * Plays a short beep and/or a haptic tick when a barcode is detected, mirroring
 * the "scan accepted" cue commercial scanners (Scandit et al.) give the user.
 *
 * Fired from the [FrameAnalyzer] emission path, which is already duplicate-
 * filtered, so each accepted (value+format) detection produces one cue. A local
 * throttle guards against tones piling up when several distinct codes land in
 * the same frame burst.
 */
internal class FeedbackController(
    context: Context,
    private val soundEnabled: Boolean,
    private val vibrationEnabled: Boolean,
) {
    private val appContext = context.applicationContext

    private val toneGenerator: ToneGenerator? =
        if (soundEnabled) {
            runCatching {
                ToneGenerator(AudioManager.STREAM_MUSIC, TONE_VOLUME)
            }.getOrNull()
        } else null

    private val vibrator: Vibrator? =
        if (vibrationEnabled) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val mgr = appContext.getSystemService(VibratorManager::class.java)
                mgr?.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                appContext.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            }
        } else null

    private var lastCueMs = 0L

    /** Fires the configured cue, throttled to [MIN_INTERVAL_MS]. */
    fun onDetection() {
        if (toneGenerator == null && vibrator == null) return
        val now = System.currentTimeMillis()
        if (now - lastCueMs < MIN_INTERVAL_MS) return
        lastCueMs = now

        toneGenerator?.startTone(ToneGenerator.TONE_PROP_BEEP, TONE_DURATION_MS)
        vibrate()
    }

    private fun vibrate() {
        val v = vibrator ?: return
        if (!v.hasVibrator()) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            v.vibrate(
                VibrationEffect.createOneShot(VIBRATION_MS, VibrationEffect.DEFAULT_AMPLITUDE),
            )
        } else {
            @Suppress("DEPRECATION")
            v.vibrate(VIBRATION_MS)
        }
    }

    fun dispose() {
        toneGenerator?.release()
    }

    private companion object {
        const val TONE_VOLUME = 80
        const val TONE_DURATION_MS = 150
        const val VIBRATION_MS = 80L
        const val MIN_INTERVAL_MS = 200L
    }
}
