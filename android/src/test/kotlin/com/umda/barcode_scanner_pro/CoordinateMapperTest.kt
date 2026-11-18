package com.umda.barcode_scanner_pro

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class CoordinateMapperTest {
    // Portrait phone: 640x480 buffer rotated 90 -> upright 480x640 (4:3),
    // shown FILL_CENTER in a 1080x2340 view: only the middle ~61.5% of the
    // image width is visible.
    private val square = ScanAreaConfig(0.125, 0.125, 0.75, 0.75)

    @Test
    fun `centered code is inside a centered area`() {
        assertTrue(CoordinateMapper.isInside(240f, 320f, square, 480, 640, 1080, 2340))
    }

    @Test
    fun `code near the bottom edge is outside`() {
        assertFalse(CoordinateMapper.isInside(240f, 630f, square, 480, 640, 1080, 2340))
    }

    @Test
    fun `code cropped off-screen by FILL_CENTER is outside`() {
        // x = 0.15 of the image: inside the area if the crop were ignored,
        // but left of the visible region on this screen.
        assertFalse(CoordinateMapper.isInside(72f, 320f, square, 480, 640, 1080, 2340))
    }

    @Test
    fun `code inside the visible box is inside`() {
        // x = 0.35 of the image -> ~0.26 of the visible width -> inside.
        assertTrue(CoordinateMapper.isInside(168f, 320f, square, 480, 640, 1080, 2340))
    }

    @Test
    fun `unlaid-out view falls back to the full image`() {
        assertTrue(CoordinateMapper.isInside(72f, 320f, square, 480, 640, 0, 0))
    }

    @Test
    fun `full area accepts everything`() {
        assertTrue(
            CoordinateMapper.isInside(5f, 5f, ScanAreaConfig(0.0, 0.0, 1.0, 1.0), 480, 640, 1080, 2340),
        )
    }
}
