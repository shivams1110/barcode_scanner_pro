package com.umda.barcode_scanner_pro

import kotlin.math.max

/**
 * Tests ML Kit detections against the Dart scan area.
 *
 * The scan area arrives from Dart as a `[0,1]` rectangle relative to the
 * **visible preview**. ML Kit, given an `InputImage` built with its rotation
 * degrees, reports geometry in the **upright** (already rotated) analysis
 * image. The preview is `FILL_CENTER`: the image is scaled to cover the view
 * and the overflow is cropped equally on both sides, so on a tall phone a 4:3
 * frame loses a large slice of its width. Detections are mapped into that
 * visible region before comparing against the area.
 */
internal object CoordinateMapper {

    /**
     * True when the point ([cx], [cy]) — a detection's center in upright pixels
     * of an [imageWidth] x [imageHeight] image — lies within the normalized
     * [area] of a [viewWidth] x [viewHeight] FILL_CENTER preview. A zero view
     * size (not laid out yet) falls back to the uncropped image.
     */
    fun isInside(
        cx: Float,
        cy: Float,
        area: ScanAreaConfig,
        imageWidth: Int,
        imageHeight: Int,
        viewWidth: Int,
        viewHeight: Int,
    ): Boolean {
        if (area.isFull) return true
        // Fraction of the image width/height the view actually shows.
        var visibleW = 1.0
        var visibleH = 1.0
        if (viewWidth > 0 && viewHeight > 0) {
            val scale = max(viewWidth.toDouble() / imageWidth, viewHeight.toDouble() / imageHeight)
            visibleW = viewWidth / scale / imageWidth
            visibleH = viewHeight / scale / imageHeight
        }
        val nx = (cx / imageWidth - (1 - visibleW) / 2) / visibleW
        val ny = (cy / imageHeight - (1 - visibleH) / 2) / visibleH
        return nx >= area.left && nx <= area.left + area.width &&
            ny >= area.top && ny <= area.top + area.height
    }
}
