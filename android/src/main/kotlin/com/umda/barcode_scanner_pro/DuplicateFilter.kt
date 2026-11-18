package com.umda.barcode_scanner_pro

/**
 * Suppresses repeat emissions of the same (value+format) until it has gone
 * unseen for the timeout. Every sighting refreshes the timer, so a code held
 * in view emits once rather than every timeout. Cheap and allocation-free on the hot path: a single map keyed by the
 * decoded payload. Pruned lazily to avoid unbounded growth.
 */
internal class DuplicateFilter(private val timeoutMs: Long) {
    private val lastSeen = HashMap<String, Long>()
    private var lastPrune = 0L

    /** Records a sighting of [key]; true if it was unseen for at least the timeout. */
    fun shouldEmit(key: String, nowMs: Long): Boolean {
        val previous = lastSeen.put(key, nowMs)
        prune(nowMs)
        return previous == null || nowMs - previous >= timeoutMs
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
