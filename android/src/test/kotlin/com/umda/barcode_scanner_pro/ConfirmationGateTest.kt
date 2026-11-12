package com.umda.barcode_scanner_pro

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class ConfirmationGateTest {
    @Test
    fun `required 1 emits immediately`() {
        val gate = ConfirmationGate(required = 1)
        assertTrue(gate.confirm("a", 0))
        assertTrue(gate.confirm("a", 10))
    }

    @Test
    fun `two decodes of the same value are needed`() {
        val gate = ConfirmationGate(required = 2)
        assertFalse(gate.confirm("A218219", 0))
        assertTrue(gate.confirm("A218219", 66))
    }

    @Test
    fun `occasional misread of a held code never emits`() {
        // The reported bug: A218219 held in view, misread as A218279 in 3 of
        // every 15 frames. The misread reaches the count but loses the vote.
        val gate = ConfirmationGate(required = 2)
        var realEmitted = false
        for (frame in 0 until 60) {
            val now = frame * 66L
            if (frame % 5 == 4) {
                assertFalse(gate.confirm("A218279", now), "misread emitted at frame $frame")
            } else if (gate.confirm("A218219", now)) {
                realEmitted = true
            }
        }
        assertTrue(realEmitted)
    }

    @Test
    fun `unstable decoding with no majority emits nothing`() {
        // Seen on a tilted photo of a label: the engine cycles through values.
        val gate = ConfirmationGate(required = 2)
        val reads = listOf("A398276", "A39827W", "A398275", "A3DB276", "A398276", "A398275")
        for (frame in 0 until 60) {
            val value = reads[frame % reads.size]
            assertFalse(gate.confirm(value, frame * 66L), "$value emitted at frame $frame")
        }
    }

    @Test
    fun `two codes in the same frame do not block each other`() {
        val gate = ConfirmationGate(required = 2)
        gate.confirm("A", 0)
        gate.confirm("B", 0)
        assertTrue(gate.confirm("A", 66))
        assertTrue(gate.confirm("B", 66))
    }

    @Test
    fun `misread as another symbology is outvoted too`() {
        val gate = ConfirmationGate(required = 2)
        repeat(5) { gate.confirm("39:A106852", it * 66L) }
        assertFalse(gate.confirm("itf:780685", 330))
        assertFalse(gate.confirm("itf:780685", 396))
    }

    @Test
    fun `a new code takes over once the previous one leaves the window`() {
        val gate = ConfirmationGate(required = 2, windowMs = 1000)
        repeat(10) { gate.confirm("old", it * 66L) }
        assertFalse(gate.confirm("new", 2000))
        assertTrue(gate.confirm("new", 2066))
    }

    @Test
    fun `sightings older than the window do not accumulate`() {
        val gate = ConfirmationGate(required = 2, windowMs = 1000)
        assertFalse(gate.confirm("x", 0))
        assertFalse(gate.confirm("x", 5000))
        assertTrue(gate.confirm("x", 5100))
    }

    @Test
    fun `reset clears votes`() {
        val gate = ConfirmationGate(required = 2)
        assertFalse(gate.confirm("x", 0))
        gate.reset()
        assertFalse(gate.confirm("x", 60))
    }

    @Test
    fun `stale keys are pruned so misreads cannot grow unbounded`() {
        val gate = ConfirmationGate(required = 2, windowMs = 100)
        repeat(500) { gate.confirm("misread-$it", it.toLong() * 10) }
        assertTrue(gate.pendingCount <= 64)
    }
}
