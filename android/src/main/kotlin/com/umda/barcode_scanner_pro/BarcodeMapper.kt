package com.umda.barcode_scanner_pro

import com.google.mlkit.vision.barcode.common.Barcode

/**
 * Converts an ML Kit [Barcode] into the cross-platform result map consumed by
 * Dart `BarcodeResult.fromMap`.
 *
 * Geometry is reported in the **unrotated** image buffer coordinate space along
 * with [rotation] and the buffer dimensions, matching ML Kit's convention; the
 * Flutter overlay applies the rotation when mapping to widget space.
 */
internal object BarcodeMapper {

    fun toMap(
        barcode: Barcode,
        imageWidth: Int,
        imageHeight: Int,
        rotation: Int,
        timestampMs: Long,
    ): Map<String, Any?> {
        val box = barcode.boundingBox
        val corners = barcode.cornerPoints?.map {
            mapOf("x" to it.x.toDouble(), "y" to it.y.toDouble())
        } ?: emptyList()

        return mapOf(
            "value" to (barcode.rawValue ?: ""),
            "format" to FormatMapper.toBit(barcode.format),
            "boundingBox" to mapOf(
                "left" to (box?.left ?: 0).toDouble(),
                "top" to (box?.top ?: 0).toDouble(),
                "width" to (box?.width() ?: 0).toDouble(),
                "height" to (box?.height() ?: 0).toDouble(),
            ),
            "cornerPoints" to corners,
            "timestamp" to timestampMs,
            "rawBytes" to barcode.rawBytes,
            "imageWidth" to imageWidth,
            "imageHeight" to imageHeight,
            "rotation" to rotation,
            "confidence" to null, // ML Kit does not expose a confidence score.
        )
    }

    /** Stable dedup key for the duplicate filter. */
    fun dedupKey(barcode: Barcode): String =
        "${barcode.format}:${barcode.rawValue ?: ""}"
}
