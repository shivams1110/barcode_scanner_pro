package com.umda.barcode_scanner_pro

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/**
 * Thread-safe bridge to a Flutter [EventChannel]. Frames are analyzed on a
 * background executor, but [EventChannel.EventSink] must be invoked on the main
 * thread — this class marshals every emission via the main looper and tolerates
 * the sink being absent (no listener yet) without throwing.
 */
internal class EventDispatcher : EventChannel.StreamHandler {
    private val mainHandler = Handler(Looper.getMainLooper())
    @Volatile private var sink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    fun send(payload: Map<String, Any?>) {
        val s = sink ?: return
        if (Looper.myLooper() == Looper.getMainLooper()) {
            s.success(payload)
        } else {
            mainHandler.post { sink?.success(payload) }
        }
    }

    fun sendError(code: String, message: String?) {
        send(mapOf("type" to EventType.ERROR, "code" to code, "message" to message))
    }

    fun dispose() {
        sink = null
        mainHandler.removeCallbacksAndMessages(null)
    }
}
