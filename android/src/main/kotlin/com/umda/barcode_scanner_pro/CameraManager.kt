package com.umda.barcode_scanner_pro

import android.content.Context
import android.graphics.Bitmap
import android.util.Size
import androidx.camera.core.Camera
import androidx.camera.core.CameraSelector
import androidx.camera.core.FocusMeteringAction
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.core.SurfaceOrientedMeteringPointFactory
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

    /** True while the zoom is where ML Kit auto-zoom put it. */
    @Volatile
    private var autoZoomed = false

    /** Max zoom of the bound lens; 1 before binding. */
    val maxZoomRatio: Float
        get() = camera?.cameraInfo?.zoomState?.value?.maxZoomRatio ?: 1f

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
        val strategy = if (config.useHighestResolution) {
            ResolutionStrategy.HIGHEST_AVAILABLE_STRATEGY
        } else {
            ResolutionStrategy(
                Size(res.width, res.height),
                ResolutionStrategy.FALLBACK_RULE_CLOSEST_HIGHER_THEN_LOWER,
            )
        }
        val resolutionSelector = ResolutionSelector.Builder()
            .setResolutionStrategy(strategy)
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

    /**
     * Applies an absolute zoom [ratio] (ML Kit auto-zoom), clamped to what the
     * lens supports. Returns false when no camera is bound yet.
     */
    // ponytail: in continuous mode zoom stays where auto-zoom left it until the
    // next start/resume (ML Kit only zooms in); reset per detection if that bites.
    fun setZoomRatio(ratio: Float): Boolean {
        val cam = camera ?: return false
        val max = maxZoomRatio
        val applied = ratio.coerceIn(1f, max)
        cam.cameraControl.setZoomRatio(applied)
        autoZoomed = true
        sendZoom(applied, max)
        // Zooming throws the lens out of focus; refocus on the centre (where the
        // zoom lands) now instead of waiting for continuous AF to notice.
        val center = SurfaceOrientedMeteringPointFactory(1f, 1f).createPoint(0.5f, 0.5f)
        cam.cameraControl.startFocusAndMetering(
            FocusMeteringAction.Builder(center)
                .setAutoCancelDuration(3, TimeUnit.SECONDS)
                .build(),
        )
        return true
    }

    /**
     * Reports a zoom [ratio] as the `[0,1]` value `setZoom` takes, so the Dart
     * zoom slider follows auto-zoom. Same mapping as CameraX `setLinearZoom`.
     */
    private fun sendZoom(ratio: Float, max: Float) {
        val linear = if (max <= 1f) 0f else (1f / ratio - 1f) / (1f / max - 1f)
        events.send(
            mapOf("type" to EventType.ZOOM_CHANGED, "zoom" to linear.coerceIn(0f, 1f).toDouble()),
        )
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
        // Start each scan wide again: ML Kit never suggests zooming out, so a
        // near code after a far one would otherwise overflow the frame.
        if (autoZoomed) {
            camera?.cameraControl?.setZoomRatio(1f)
            autoZoomed = false
            sendZoom(1f, maxZoomRatio)
        }
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
        analyzer.scanner = null
        camera = null
        cameraProvider = null
    }
}
