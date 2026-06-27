package com.karnival.barcode_scanner_pro

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/**
 * Plugin entry point. Registers the platform-view factory for the camera
 * preview and a single global method channel for camera-permission handling
 * (which requires an [Activity], obtained via [ActivityAware]).
 *
 * All scanning traffic flows through per-view channels owned by
 * [ScannerPlatformView]; this class deliberately holds no scanner state.
 */
class BarcodeScannerProPlugin :
    FlutterPlugin,
    ActivityAware,
    MethodChannel.MethodCallHandler,
    PluginRegistry.RequestPermissionsResultListener {

    private companion object {
        const val PERMISSION_REQUEST_CODE = 0xCA3 // arbitrary, unique to this plugin
    }

    private lateinit var globalChannel: MethodChannel
    private var binding: FlutterPlugin.FlutterPluginBinding? = null
    private var activity: Activity? = null
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        binding = flutterPluginBinding
        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            Channels.VIEW_TYPE,
            ScannerViewFactory(flutterPluginBinding.binaryMessenger),
        )
        globalChannel = MethodChannel(flutterPluginBinding.binaryMessenger, Channels.GLOBAL)
        globalChannel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        globalChannel.setMethodCallHandler(null)
        this.binding = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            Method.CHECK_PERMISSION -> result.success(isGranted())
            Method.REQUEST_PERMISSION -> requestPermission(result)
            Method.DECODE_IMAGE -> decodeImage(call, result)
            else -> result.notImplemented()
        }
    }

    private fun isGranted(): Boolean {
        val ctx = binding?.applicationContext ?: return false
        return ContextCompat.checkSelfPermission(ctx, Manifest.permission.CAMERA) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun requestPermission(result: MethodChannel.Result) {
        if (isGranted()) {
            result.success(true)
            return
        }
        val act = activity
        if (act == null) {
            result.success(false)
            return
        }
        if (pendingPermissionResult != null) {
            result.error(ErrorCode.SCANNER_BUSY, "A permission request is already in progress", null)
            return
        }
        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            act, arrayOf(Manifest.permission.CAMERA), PERMISSION_REQUEST_CODE,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST_CODE) return false
        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        pendingPermissionResult?.success(granted)
        pendingPermissionResult = null
        return true
    }

    // --- ActivityAware ---------------------------------------------------------

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    // --- decodeImage -----------------------------------------------------------

    /**
     * Decodes barcodes from raw image bytes using ML Kit.
     *
     * Args (from [MethodCall]):
     *   - `bytes`   : ByteArray — JPEG/PNG/etc. image bytes.
     *   - `formats` : Int      — bitmask of desired formats (0 = all formats).
     *
     * Returns a List of maps with keys: value, format, rawBytes, cornerPoints.
     *
     * ML Kit 17.3.0 API notes:
     *   - [BarcodeScanning.getClient()] with no arg scans all formats.
     *   - [BarcodeScannerOptions.Builder.setBarcodeFormats] takes (Int, vararg Int);
     *     passing a single OR-ed Int as the first arg (empty varargs) is valid.
     *   - [InputImage.fromBitmap] takes (Bitmap, rotationDegrees: Int).
     *   - [Barcode.cornerPoints] is Array<android.graphics.Point>? (.x/.y are Ints).
     */
    private fun decodeImage(call: MethodCall, result: MethodChannel.Result) {
        val bytes = call.argument<ByteArray>("bytes")
        if (bytes == null || bytes.isEmpty()) {
            result.error(ErrorCode.DECODING_ERROR, "Empty image bytes", null)
            return
        }
        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
        if (bitmap == null) {
            result.error(ErrorCode.DECODING_ERROR, "Could not decode image bytes", null)
            return
        }
        val mask = (call.argument<Number>("formats"))?.toInt() ?: 0
        val scanner = if (mask == 0) {
            BarcodeScanning.getClient()
        } else {
            val flags = FormatMapper.toMlKitFlags(mask)
            BarcodeScanning.getClient(
                BarcodeScannerOptions.Builder().setBarcodeFormats(flags).build(),
            )
        }
        val image = InputImage.fromBitmap(bitmap, 0)
        scanner.process(image)
            .addOnSuccessListener { barcodes ->
                result.success(barcodes.map { decodeMap(it) })
                scanner.close()
            }
            .addOnFailureListener { e ->
                result.error(ErrorCode.DECODING_ERROR, e.message, null)
                scanner.close()
            }
    }

    /**
     * Converts an ML Kit [Barcode] to the light result map expected by Dart's
     * `BarcodeDecodeResult.fromMap`. Key names MUST match exactly.
     *
     * [Barcode.cornerPoints] elements are [android.graphics.Point] with Int
     * .x/.y; they are promoted to Double to match the Dart contract.
     */
    private fun decodeMap(barcode: Barcode): Map<String, Any?> {
        val corners = barcode.cornerPoints?.map {
            mapOf("x" to it.x.toDouble(), "y" to it.y.toDouble())
        } ?: emptyList<Map<String, Double>>()
        return mapOf(
            "value" to (barcode.rawValue ?: ""),
            "format" to FormatMapper.toBit(barcode.format),
            "rawBytes" to barcode.rawBytes,
            "cornerPoints" to corners,
        )
    }
}
