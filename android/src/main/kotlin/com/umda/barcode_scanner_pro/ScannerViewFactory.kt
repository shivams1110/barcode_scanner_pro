package com.umda.barcode_scanner_pro

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * Creates a [ScannerPlatformView] per Flutter `AndroidView`. The [messenger] is
 * captured so each view can open method/event channels scoped to its id.
 */
internal class ScannerViewFactory(
    private val messenger: BinaryMessenger,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    @Suppress("UNCHECKED_CAST")
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return ScannerPlatformView(
            context = context,
            id = viewId,
            creationParams = args as? Map<String, Any?>,
            messenger = messenger,
        )
    }
}
