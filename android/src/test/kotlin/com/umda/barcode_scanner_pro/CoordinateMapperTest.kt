package com.umda.barcode_scanner_pro

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class CoordinateMapperTest {
    // Portrait phone: 1280x720 buffer rotated 90 -> upright 720x1280.
    private val square = ScanAreaConfig(0.125, 0.125, 0.75, 0.75)

    @Test
    fun `centered code in an upright portrait frame is inside a centered area`() {
        assertTrue(CoordinateMapper.isInside(360f, 640f, square, 720, 1280))
    }

    @Test
    fun `code near the bottom edge is outside`() {
        assertFalse(CoordinateMapper.isInside(360f, 1250f, square, 720, 1280))
    }

    @Test
    fun `full area accepts everything`() {
        assertTrue(CoordinateMapper.isInside(5f, 5f, ScanAreaConfig(0.0, 0.0, 1.0, 1.0), 720, 1280))
    }
}
