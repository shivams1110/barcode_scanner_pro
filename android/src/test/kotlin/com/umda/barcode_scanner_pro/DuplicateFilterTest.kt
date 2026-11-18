package com.umda.barcode_scanner_pro

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class DuplicateFilterTest {
    @Test
    fun `code held in view emits once`() {
        val f = DuplicateFilter(1000)
        assertTrue(f.shouldEmit("a", 0))
        // Seen every 100ms for 3s: never re-emitted.
        for (t in 100L..3000L step 100) assertFalse(f.shouldEmit("a", t), "t=$t")
    }

    @Test
    fun `code emits again after being out of view for the timeout`() {
        val f = DuplicateFilter(1000)
        assertTrue(f.shouldEmit("a", 0))
        assertFalse(f.shouldEmit("a", 500))
        assertTrue(f.shouldEmit("a", 1500))
    }

    @Test
    fun `different codes are independent`() {
        val f = DuplicateFilter(1000)
        assertTrue(f.shouldEmit("a", 0))
        assertTrue(f.shouldEmit("b", 10))
    }
}
