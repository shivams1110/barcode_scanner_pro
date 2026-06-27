package com.karnival.barcode_scanner_pro

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
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
}
