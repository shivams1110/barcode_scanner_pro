package com.karnival.barcode_scanner_pro

import android.graphics.Rect

/**
 * Maps between ML Kit's unrotated image-buffer coordinate space and the upright,
 * normalized preview space that the Dart scan area is expressed in.
 *
 * The scan area arrives from Dart as a `[0,1]` rectangle relative to the upright
 * preview. ML Kit reports detections in the raw buffer (pre-rotation) space, so
 * we rotate a detection's center into upright space, normalize it by the
 * orientation-corrected image size, and test containment. This avoids any
 * per-frame bitmap cropping/allocation while still honoring the scan area.
 */
internal object CoordinateMapper {

    /** True when the center of [box] lies within the normalized [area]. */
    fun isInside(
        box: Rect,
        area: ScanAreaConfig,
        imageWidth: Int,
        imageHeight: Int,
        rotation: Int,
    ): Boolean {
        if (area.isFull) return true

        val cx = box.exactCenterX()
        val cy = box.exactCenterY()

        // Rotate the point into upright space and compute upright dimensions.
        val (ux, uy, uw, uh) = rotatePoint(cx, cy, imageWidth, imageHeight, rotation)

        val nx = ux / uw
        val ny = uy / uh
        return nx >= area.left && nx <= area.left + area.width &&
            ny >= area.top && ny <= area.top + area.height
    }

    private data class Mapped(val x: Float, val y: Float, val w: Float, val h: Float)

    private operator fun Mapped.component1() = x
    private operator fun Mapped.component2() = y
    private operator fun Mapped.component3() = w
    private operator fun Mapped.component4() = h

    private fun rotatePoint(
        x: Float,
        y: Float,
        w: Int,
        h: Int,
        rotation: Int,
    ): Mapped = when (rotation) {
        90 -> Mapped(h - y, x, h.toFloat(), w.toFloat())
        180 -> Mapped(w - x, h - y, w.toFloat(), h.toFloat())
        270 -> Mapped(y, w - x, h.toFloat(), w.toFloat())
        else -> Mapped(x, y, w.toFloat(), h.toFloat())
    }
}
