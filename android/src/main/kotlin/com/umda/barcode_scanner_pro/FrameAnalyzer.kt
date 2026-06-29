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
 *  - applies the **duplicate filter**;
 *  - honors **scan mode** (single / continuous / multi).
 *
 * Results are handed back through [onBarcodes] as already-serialized maps so the
 * platform view only has to forward them to the event channel.
 */
internal class FrameAnalyzer(
    private val scanner: BarcodeScanner,
    private val config: ScannerConfig,
    private val onBarcodes: (List<Map<String, Any?>>) -> Unit,
    private val onError: (String) -> Unit,
) : ImageAnalysis.Analyzer {

    private val dupFilter = DuplicateFilter(config.duplicateTimeoutMs)
    private var lastAnalyzedMs = 0L

    /** Gate toggled by start/pause/stop. When false, frames are dropped cheaply. */
    @Volatile
    var active: Boolean = false

    fun resetDuplicates() = dupFilter.reset()

    @ExperimentalGetImage
    override fun analyze(imageProxy: ImageProxy) {
        if (!active) {
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
        val width = mediaImage.width
        val height = mediaImage.height

        scanner.process(input)
            .addOnSuccessListener { barcodes ->
                handle(barcodes, width, height, rotation, now)
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

        val inArea = barcodes.filter {
            val box = it.boundingBox ?: return@filter false
            CoordinateMapper.isInside(box, config.scanArea, width, height, rotation)
        }
        if (inArea.isEmpty()) return

        val fresh = inArea.filter {
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
}
