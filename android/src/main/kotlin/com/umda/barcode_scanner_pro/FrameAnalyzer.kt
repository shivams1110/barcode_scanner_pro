package com.umda.barcode_scanner_pro

import android.os.SystemClock
import androidx.camera.core.ExperimentalGetImage
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import com.google.mlkit.vision.barcode.BarcodeScanner
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage

/**
 * The decoding hot path. Runs on a background executor (see [CameraManager]) and:
 *
 *  - **skips frames** so decoding never exceeds the configured FPS cap, while the
 *    preview keeps running at the camera's native rate;
 *  - reuses a single [BarcodeScanner] instance (no per-frame allocation of the
 *    detector);
 *  - filters detections to the configured **scan area**;
 *  - requires **multi-frame confirmation** before a payload is trusted;
 *  - applies the **duplicate filter**;
 *  - honors **scan mode** (single / continuous / multi).
 *
 * Results are handed back through [onBarcodes] as already-serialized maps so the
 * platform view only has to forward them to the event channel.
 */
internal class FrameAnalyzer(
    private val config: ScannerConfig,
    /** Current preview view size (width, height); read on the main thread. */
    private val viewSize: () -> Pair<Int, Int>,
    private val onBarcodes: (List<Map<String, Any?>>) -> Unit,
    private val onError: (String) -> Unit,
) : ImageAnalysis.Analyzer {

    private val dupFilter = DuplicateFilter(config.duplicateTimeoutMs)
    private val confirmGate = ConfirmationGate(config.confirmations)
    private var lastAnalyzedMs = 0L

    /**
     * Set once the camera is bound: auto-zoom needs the lens' max zoom ratio
     * at build time. Frames are dropped until then. Replacing closes the old one.
     */
    @Volatile
    var scanner: BarcodeScanner? = null
        set(value) {
            field?.close()
            field = value
        }

    /** Gate toggled by start/pause/stop. When false, frames are dropped cheaply. */
    @Volatile
    var active: Boolean = false

    fun resetDuplicates() {
        dupFilter.reset()
        confirmGate.reset()
    }

    @ExperimentalGetImage
    override fun analyze(imageProxy: ImageProxy) {
        val scanner = scanner
        if (!active || scanner == null) {
            imageProxy.close()
            return
        }
        val now = SystemClock.elapsedRealtime()
        if (now - lastAnalyzedMs < config.frameIntervalMs) {
            imageProxy.close() // frame skip
            return
        }
        lastAnalyzedMs = now

        val mediaImage = imageProxy.image
        if (mediaImage == null) {
            imageProxy.close()
            return
        }
        val rotation = imageProxy.imageInfo.rotationDegrees
        val input = InputImage.fromMediaImage(mediaImage, rotation)
        // ML Kit reports geometry in the upright (rotated) image, so hand the
        // rest of the pipeline upright dimensions and no residual rotation.
        val sideways = rotation == 90 || rotation == 270
        val width = if (sideways) mediaImage.height else mediaImage.width
        val height = if (sideways) mediaImage.width else mediaImage.height

        scanner.process(input)
            .addOnSuccessListener { barcodes ->
                handle(barcodes, width, height, 0, now)
            }
            .addOnFailureListener { e ->
                onError(e.localizedMessage ?: "Barcode decoding failed")
            }
            .addOnCompleteListener {
                imageProxy.close() // release buffer back to the pool
            }
    }

    private fun handle(
        barcodes: List<Barcode>,
        width: Int,
        height: Int,
        rotation: Int,
        nowMs: Long,
    ) {
        if (!active || barcodes.isEmpty()) return

        // ML Kit delivers results on the main thread, so the view size is safe to read.
        val (viewW, viewH) = viewSize()
        val inArea = barcodes.filter {
            val box = it.boundingBox ?: return@filter false
            CoordinateMapper.isInside(
                box.exactCenterX(), box.exactCenterY(), config.scanArea, width, height, viewW, viewH,
            )
        }
        if (inArea.isEmpty()) return

        // Trust a payload only once it has out-voted competing reads across
        // frames; see [ConfirmationGate]. Must run before the duplicate filter,
        // which would otherwise swallow the repeats that confirm a code.
        // Codes with a built-in checksum emit on the first decode; only the
        // checksum-free symbologies wait for votes.
        val confirmed = inArea.filter {
            it.format in SELF_CHECKING || confirmGate.confirm(BarcodeMapper.dedupKey(it), nowMs)
        }
        if (confirmed.isEmpty()) return

        val fresh = confirmed.filter {
            dupFilter.shouldEmit(BarcodeMapper.dedupKey(it), nowMs)
        }
        if (fresh.isEmpty()) return

        val epochMs = System.currentTimeMillis()
        when (config.scanMode) {
            // Single: emit only the first and stop decoding.
            0 -> {
                active = false
                onBarcodes(
                    listOf(BarcodeMapper.toMap(fresh.first(), width, height, rotation, epochMs)),
                )
            }
            // MultiBarcode: emit the whole batch at once.
            2 -> onBarcodes(
                fresh.map { BarcodeMapper.toMap(it, width, height, rotation, epochMs) },
            )
            // Continuous (default).
            else -> {
                if (!config.continuousScanning) active = false
                onBarcodes(
                    fresh.map { BarcodeMapper.toMap(it, width, height, rotation, epochMs) },
                )
            }
        }
    }

    private companion object {
        /**
         * Formats whose decode is already verified by ECC or a strong checksum.
         * EAN/UPC are deliberately absent: a single mod-10 digit still lets
         * misreads through (e.g. a partial EAN-13 decoded as UPC-E).
         */
        val SELF_CHECKING = setOf(
            Barcode.FORMAT_QR_CODE, Barcode.FORMAT_DATA_MATRIX, Barcode.FORMAT_AZTEC,
            Barcode.FORMAT_PDF417, Barcode.FORMAT_CODE_128,
        )
    }
}
