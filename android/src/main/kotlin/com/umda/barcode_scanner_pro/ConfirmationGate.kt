package com.umda.barcode_scanner_pro

/**
 * Withholds a detection until the same payload has been decoded [required]
 * times inside [windowMs] **and** has been seen more often than all competing
 * readings put together.
 *
 * Barcode engines report a decode with no confidence score, and symbologies
 * without a mandatory check digit (Code 39, Code 93, ITF, Codabar) can produce
 * a *structurally valid but wrong* payload from a marginal frame — e.g. Code 39
 * `A218219` read as `A218279`, or as ITF digits. A count alone does not stop that: while a code is
 * held in view, an occasional misread soon reaches any small count. The genuine
 * payload is still read far more often, so the misread loses the vote. And
 * when the engine flips between several values with none in the majority, the
 * image is too poor to trust and nothing is emitted at all.
 *
 * Two payloads decoded in the same frame are different physical codes, not
 * competing readings of one, and never outvote each other.
 *
 * Sits ahead of [DuplicateFilter] on the hot path: votes must be fed by every
 * decode, including the repeats the duplicate filter suppresses.
 */
internal class ConfirmationGate(
    private val required: Int,
    private val windowMs: Long = DEFAULT_WINDOW_MS,
) {
    /** payload key -> frame times still inside the window. */
    private val seen = HashMap<String, ArrayDeque<Long>>()

    /** Number of payloads currently tracked (test visibility). */
    val pendingCount: Int get() = seen.size

    /**
     * Records a sighting of [key] in the frame at [nowMs] and returns true when
     * it is trusted.
     */
    fun confirm(key: String, nowMs: Long): Boolean {
        if (required <= 1) return true
        prune(nowMs)

        val mine = seen.getOrPut(key) { ArrayDeque() }
        if (mine.lastOrNull() != nowMs) mine.addLast(nowMs)

        // ponytail: switching straight from one code to another waits (under
        // half the window) for the new one to overtake the previous one's
        // votes; shrink windowMs if that hand-off ever feels slow.
        val rivals = seen.entries.sumOf { (other, times) ->
            if (other == key || times.any { it in mine }) 0 else times.size
        }
        return mine.size >= required && mine.size > rivals
    }

    fun reset() = seen.clear()

    private fun prune(nowMs: Long) {
        for (times in seen.values) {
            while (times.isNotEmpty() && nowMs - times.first() > windowMs) times.removeFirst()
        }
        seen.values.removeAll { it.isEmpty() }
    }

    private companion object {
        const val DEFAULT_WINDOW_MS = 1000L
    }
}
