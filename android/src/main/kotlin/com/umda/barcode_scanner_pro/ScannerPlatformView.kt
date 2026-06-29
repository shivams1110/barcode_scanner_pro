package com.umda.barcode_scanner_pro

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.view.View
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

/**
 * A single native scanner instance hosted inside a Flutter PlatformView.
 *
 * Responsibilities are intentionally thin: it wires the per-view method/event
 * channels, owns a [PreviewView], and delegates all camera work to
 * [CameraManager] and all decoding to [FrameAnalyzer]. It also acts as a
 * self-driven [LifecycleOwner] so CameraX can bind its use cases.
 */
internal class ScannerPlatformView(
    private val context: Context,
    id: Int,
    creationParams: Map<String, Any?>?,
    messenger: BinaryMessenger,
) : PlatformView, MethodChannel.MethodCallHandler, LifecycleOwner {

    private val previewView = PreviewView(context).apply {
        implementationMode = PreviewView.ImplementationMode.COMPATIBLE
        scaleType = PreviewView.ScaleType.FILL_CENTER
    }

    private val methodChannel = MethodChannel(messenger, Channels.methods(id))
    private val eventChannel = EventChannel(messenger, Channels.events(id))
    private val events = EventDispatcher()
    private val registry = LifecycleRegistry(this)

    private var config: ScannerConfig =
        ScannerConfig.fromMap(creationParams ?: emptyMap())
    private var cameraManager: CameraManager? = null
    private var feedback: FeedbackController? = null

    init {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(events)
        registry.currentState = Lifecycle.State.CREATED
    }

    override fun getView(): View = previewView
    override val lifecycle: Lifecycle get() = registry

    private fun hasCameraPermission(): Boolean =
        ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) ==
            PackageManager.PERMISSION_GRANTED

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                Method.INITIALIZE -> initialize(call, result)
                Method.START -> {
                    cameraManager?.resumeAnalysis()
                    events.send(mapOf("type" to EventType.SCANNER_STARTED))
                    result.success(null)
                }
                Method.STOP -> {
                    cameraManager?.stop()
                    events.send(mapOf("type" to EventType.SCANNER_STOPPED))
                    result.success(null)
                }
                Method.PAUSE -> {
                    cameraManager?.pauseAnalysis()
                    result.success(null)
                }
                Method.RESUME -> {
                    cameraManager?.resumeAnalysis()
                    result.success(null)
                }
                Method.SET_FLASH -> {
                    cameraManager?.setTorch(call.argument<Boolean>("enabled") ?: false)
                    result.success(null)
                }
                Method.TOGGLE_FLASH -> result.success(cameraManager?.toggleTorch() ?: false)
                Method.SWITCH_CAMERA -> {
                    cameraManager?.switchCamera(config)
                    result.success(null)
                }
                Method.SET_ZOOM -> {
                    cameraManager?.setZoom((call.argument<Double>("zoom") ?: 0.0).toFloat())
                    result.success(null)
                }
                Method.SET_EXPOSURE -> {
                    cameraManager?.setExposure((call.argument<Double>("exposure") ?: 0.0).toFloat())
                    result.success(null)
                }
                Method.SET_FOCUS -> {
                    val x = (call.argument<Double>("x") ?: 0.5).toFloat()
                    val y = (call.argument<Double>("y") ?: 0.5).toFloat()
                    cameraManager?.focusAt(x, y)
                    result.success(null)
                }
                Method.CAPTURE_FRAME -> result.success(cameraManager?.captureFrame())
                Method.DISPOSE -> {
                    disposeInternal()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error(ErrorCode.DECODING_ERROR, e.localizedMessage, null)
        }
    }

    @Suppress("UNCHECKED_CAST")
    private fun initialize(call: MethodCall, result: MethodChannel.Result) {
        (call.arguments as? Map<String, Any?>)?.let { config = ScannerConfig.fromMap(it) }

        if (!hasCameraPermission()) {
            events.send(mapOf("type" to EventType.PERMISSION_DENIED))
            result.error(ErrorCode.PERMISSION_DENIED, "Camera permission not granted", null)
            return
        }

        val options = BarcodeScannerOptions.Builder()
            .setBarcodeFormats(FormatMapper.toMlKitFlags(config.formatMask))
            .build()
        val scanner = BarcodeScanning.getClient(options)

        feedback?.dispose()
        feedback = FeedbackController(
            context = context,
            soundEnabled = config.enableSound,
            vibrationEnabled = config.enableVibration,
        )

        val analyzer = FrameAnalyzer(
            scanner = scanner,
            config = config,
            onBarcodes = { list ->
                feedback?.onDetection()
                events.send(mapOf("type" to EventType.BARCODE_DETECTED, "barcodes" to list))
            },
            onError = { msg -> events.sendError(ErrorCode.DECODING_ERROR, msg) },
        )

        val manager = CameraManager(context, previewView, this, analyzer, events)
        cameraManager = manager
        registry.currentState = Lifecycle.State.RESUMED

        manager.start(
            config = config,
            onReady = { result.success(null) },
            onError = { code, msg ->
                events.sendError(code, msg)
                result.error(code, msg, null)
            },
        )
    }

    private fun disposeInternal() {
        cameraManager?.dispose()
        cameraManager = null
        feedback?.dispose()
        feedback = null
        registry.currentState = Lifecycle.State.DESTROYED
        events.dispose()
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun dispose() = disposeInternal()
}
