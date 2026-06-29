package com.umda.barcode_scanner_pro

import android.util.Size
import androidx.camera.core.CameraSelector

/** Normalized scan-area rectangle in [0,1] preview space. */
internal data class ScanAreaConfig(
    val left: Double,
    val top: Double,
    val width: Double,
    val height: Double,
) {
    val isFull: Boolean get() = left == 0.0 && top == 0.0 && width == 1.0 && height == 1.0
}

/**
 * Parsed, type-safe representation of the configuration map sent from Dart
 * (`ScannerConfiguration.toMap`). Keeps channel-key strings confined to one place.
 */
internal data class ScannerConfig(
    val cameraFacing: Int,
    val resolution: Int,
    val formatMask: Int,
    val scanMode: Int,
    val scanArea: ScanAreaConfig,
    val continuousScanning: Boolean,
    val duplicateTimeoutMs: Long,
    val enableAutoFocus: Boolean,
    val enableAutoZoom: Boolean,
    val enableSound: Boolean,
    val enableVibration: Boolean,
    val enablePinchZoom: Boolean,
    val enableTapFocus: Boolean,
    val frameRateLimit: Int,
    val returnImage: Boolean,
    val detectInverted: Boolean,
) {
    val lensFacing: Int
        get() = if (cameraFacing == 1) CameraSelector.LENS_FACING_FRONT
        else CameraSelector.LENS_FACING_BACK

    /** Target analysis resolution; CameraX picks the nearest supported size. */
    val targetResolution: Size
        get() = when (resolution) {
            0 -> Size(480, 640)
            1 -> Size(720, 1280)
            2 -> Size(1080, 1920)
            else -> Size(1080, 1920)
        }

    /** Minimum interval between decoded frames, derived from the FPS cap. */
    val frameIntervalMs: Long get() = (1000L / frameRateLimit.coerceAtLeast(1))

    companion object {
        @Suppress("UNCHECKED_CAST")
        fun fromMap(map: Map<String, Any?>): ScannerConfig {
            val area = map["scanArea"] as? Map<String, Any?> ?: emptyMap()
            fun d(v: Any?, def: Double) = (v as? Number)?.toDouble() ?: def
            return ScannerConfig(
                cameraFacing = (map["camera"] as? Number)?.toInt() ?: 0,
                resolution = (map["resolution"] as? Number)?.toInt() ?: 1,
                formatMask = (map["formats"] as? Number)?.toInt() ?: 0,
                scanMode = (map["scanMode"] as? Number)?.toInt() ?: 1,
                scanArea = ScanAreaConfig(
                    d(area["left"], 0.0), d(area["top"], 0.0),
                    d(area["width"], 1.0), d(area["height"], 1.0),
                ),
                continuousScanning = map["continuousScanning"] as? Boolean ?: true,
                duplicateTimeoutMs = (map["duplicateTimeoutMs"] as? Number)?.toLong() ?: 1000L,
                enableAutoFocus = map["enableAutoFocus"] as? Boolean ?: true,
                enableAutoZoom = map["enableAutoZoom"] as? Boolean ?: false,
                enableSound = map["enableSound"] as? Boolean ?: true,
                enableVibration = map["enableVibration"] as? Boolean ?: true,
                enablePinchZoom = map["enablePinchZoom"] as? Boolean ?: true,
                enableTapFocus = map["enableTapFocus"] as? Boolean ?: true,
                frameRateLimit = (map["frameRateLimit"] as? Number)?.toInt() ?: 15,
                returnImage = map["returnImage"] as? Boolean ?: false,
                detectInverted = map["detectInverted"] as? Boolean ?: false,
            )
        }
    }
}
