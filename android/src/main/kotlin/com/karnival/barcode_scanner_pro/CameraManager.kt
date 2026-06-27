package com.karnival.barcode_scanner_pro

import android.content.Context
import android.graphics.Bitmap
import android.util.Size
import androidx.camera.core.Camera
import androidx.camera.core.CameraSelector
import androidx.camera.core.FocusMeteringAction
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.core.resolutionselector.ResolutionSelector
import androidx.camera.core.resolutionselector.ResolutionStrategy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import java.io.ByteArrayOutputStream
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * Owns the CameraX pipeline for one scanner view:
 *
 *   ProcessCameraProvider -> Preview -> ImageAnalysis -> background Executor.
 *
 * Camera control (torch/zoom/exposure/focus) is delegated to [Camera.getCameraControl].
 * Binding happens on the main thread; analysis runs on a dedicated single-thread
 * executor so the UI thread is never blocked. `KEEP_ONLY_LATEST` backpressure
 * guarantees we always analyze the most recent frame and recycle the rest.
 */
internal class CameraManager(
    private val context: Context,
    private val previewView: PreviewView,
    private val lifecycleOwner: LifecycleOwner,
    private val analyzer: FrameAnalyzer,
    private val events: EventDispatcher,
) {
    private val analysisExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private var cameraProvider: ProcessCameraProvider? = null
    private var camera: Camera? = null
    private var imageAnalysis: ImageAnalysis? = null
    private var preview: Preview? = null

    private var lensFacing = CameraSelector.LENS_FACING_BACK

    /** Starts the camera with [config]. [onReady]/[onError] are invoked on main. */
    fun start(config: ScannerConfig, onReady: () -> Unit, onError: (String, String) -> Unit) {
        lensFacing = config.lensFacing
        val future = ProcessCameraProvider.getInstance(context)
        future.addListener({
            try {
                cameraProvider = future.get()
                bindUseCases(config)
                onReady()
            } catch (e: Exception) {
                onError(ErrorCode.INITIALIZATION_FAILED, e.localizedMessage ?: "Camera init failed")
            }
        }, ContextCompat.getMainExecutor(context))
    }

    private fun bindUseCases(config: ScannerConfig) {
        val provider = cameraProvider ?: return
        val res = config.targetResolution
        val resolutionSelector = ResolutionSelector.Builder()
            .setResolutionStrategy(
                ResolutionStrategy(Size(res.width, res.height),
                    ResolutionStrategy.FALLBACK_RULE_CLOSEST_HIGHER_THEN_LOWER),
            )
            .build()

        preview = Preview.Builder().build().also {
            it.setSurfaceProvider(previewView.surfaceProvider)
        }

        imageAnalysis = ImageAnalysis.Builder()
            .setResolutionSelector(resolutionSelector)
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_YUV_420_888)
            .build()
            .also { it.setAnalyzer(analysisExecutor, analyzer) }

        val selector = CameraSelector.Builder().requireLensFacing(lensFacing).build()
        provider.unbindAll()
        camera = provider.bindToLifecycle(lifecycleOwner, selector, preview, imageAnalysis)
    }

    fun switchCamera(config: ScannerConfig) {
        lensFacing = if (lensFacing == CameraSelector.LENS_FACING_BACK) {
            CameraSelector.LENS_FACING_FRONT
        } else {
            CameraSelector.LENS_FACING_BACK
        }
        bindUseCases(config)
        events.send(
            mapOf(
                "type" to EventType.CAMERA_CHANGED,
                "camera" to if (lensFacing == CameraSelector.LENS_FACING_FRONT) 1 else 0,
            ),
        )
    }

    // --- Controls --------------------------------------------------------------

    fun setTorch(enabled: Boolean) {
        camera?.cameraControl?.enableTorch(enabled)
        events.send(mapOf("type" to EventType.FLASH_CHANGED, "enabled" to enabled))
    }

    fun toggleTorch(): Boolean {
        val on = (camera?.cameraInfo?.torchState?.value ?: 0) == 1
        setTorch(!on)
        return !on
    }

    /** [value] normalized in `[0,1]`. */
    fun setZoom(value: Float) {
        camera?.cameraControl?.setLinearZoom(value.coerceIn(0f, 1f))
        events.send(mapOf("type" to EventType.ZOOM_CHANGED, "zoom" to value.toDouble()))
    }

    /** [value] in `[-1,1]` mapped onto the device EV range. */
    fun setExposure(value: Float) {
        val info = camera?.cameraInfo ?: return
        val range = info.exposureState.exposureCompensationRange
        val target = if (value >= 0) (value * range.upper) else (-value * range.lower)
        camera?.cameraControl?.setExposureCompensationIndex(target.toInt())
    }

    /** [nx]/[ny] normalized `[0,1]` in preview space. */
    fun focusAt(nx: Float, ny: Float) {
        val factory = previewView.meteringPointFactory
        val point = factory.createPoint(nx * previewView.width, ny * previewView.height)
        val action = FocusMeteringAction.Builder(point)
            .setAutoCancelDuration(3, TimeUnit.SECONDS)
            .build()
        camera?.cameraControl?.startFocusAndMetering(action)
    }

    /** Captures the current preview as JPEG bytes (best-effort). */
    fun captureFrame(): ByteArray? {
        val bitmap: Bitmap = previewView.bitmap ?: return null
        return ByteArrayOutputStream().use { out ->
            bitmap.compress(Bitmap.CompressFormat.JPEG, 85, out)
            out.toByteArray()
        }
    }

    fun pauseAnalysis() {
        analyzer.active = false
    }

    fun resumeAnalysis() {
        analyzer.resetDuplicates()
        analyzer.active = true
    }

    fun stop() {
        analyzer.active = false
        cameraProvider?.unbindAll()
    }

    fun dispose() {
        stop()
        analysisExecutor.shutdown()
        camera = null
        cameraProvider = null
    }
}
