package com.umda.barcode_scanner_pro

/**
 * Tests ML Kit detections against the Dart scan area.
 *
 * The scan area arrives from Dart as a `[0,1]` rectangle relative to the upright
 * preview. ML Kit, given an `InputImage` built with its rotation degrees,
 * reports geometry in that same **upright** (already rotated) space — so a
 * detection only needs normalizing by the upright image size. Rotating it again
 * throws centered codes outside the area.
 */
internal object CoordinateMapper {

    /**
     * True when the point ([cx], [cy]) — a detection's center in upright pixels —
     * lies within the normalized [area] of an upright image [uprightWidth] x
     * [uprightHeight].
     */
    fun isInside(
        cx: Float,
        cy: Float,
        area: ScanAreaConfig,
        uprightWidth: Int,
        uprightHeight: Int,
    ): Boolean {
        if (area.isFull) return true
        // ponytail: normalizes against the full analysis image, not the part the
        // FILL_CENTER preview shows; pass the view size in if edge accuracy matters.
        val nx = cx / uprightWidth
        val ny = cy / uprightHeight
        return nx >= area.left && nx <= area.left + area.width &&
            ny >= area.top && ny <= area.top + area.height
    }
}
