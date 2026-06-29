package com.umda.barcode_scanner_pro

/**
 * Suppresses repeat emissions of the same (value+format) within a timeout
 * window. Cheap and allocation-free on the hot path: a single map keyed by the
 * decoded payload. Pruned lazily to avoid unbounded growth.
 */
internal class DuplicateFilter(private val timeoutMs: Long) {
    private val lastSeen = HashMap<String, Long>()
    private var lastPrune = 0L

    /** Returns true if [key] should be emitted (i.e. not a recent duplicate). */
    fun shouldEmit(key: String, nowMs: Long): Boolean {
        val previous = lastSeen[key]
        if (previous != null && nowMs - previous < timeoutMs) return false
        lastSeen[key] = nowMs
        prune(nowMs)
        return true
    }

    private fun prune(nowMs: Long) {
        if (nowMs - lastPrune < timeoutMs) return
        lastPrune = nowMs
        val it = lastSeen.entries.iterator()
        while (it.hasNext()) {
            if (nowMs - it.next().value > timeoutMs) it.remove()
        }
    }

    fun reset() = lastSeen.clear()
}
