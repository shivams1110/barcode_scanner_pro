package com.karnival.barcode_scanner_pro

/**
 * Single source of truth for channel names and identifiers. These MUST stay in
 * sync with the Dart `Channels` / `ScannerMethod` definitions.
 */
internal object Channels {
    private const val BASE = "com.karnival.barcode_scanner_pro"
    const val VIEW_TYPE = "$BASE/view"
    const val GLOBAL = "$BASE/global"
    fun methods(id: Int) = "$BASE/methods/$id"
    fun events(id: Int) = "$BASE/events/$id"
}

internal object Method {
    const val INITIALIZE = "initialize"
    const val START = "start"
    const val STOP = "stop"
    const val PAUSE = "pause"
    const val RESUME = "resume"
    const val DISPOSE = "dispose"
    const val SET_FLASH = "setFlash"
    const val TOGGLE_FLASH = "toggleFlash"
    const val SWITCH_CAMERA = "switchCamera"
    const val SET_ZOOM = "setZoom"
    const val SET_EXPOSURE = "setExposure"
    const val SET_FOCUS = "setFocus"
    const val CAPTURE_FRAME = "captureFrame"
    const val DECODE_IMAGE = "decodeImage"
    const val REQUEST_PERMISSION = "requestPermission"
    const val CHECK_PERMISSION = "checkPermission"
}

internal object EventType {
    const val BARCODE_DETECTED = "barcodeDetected"
    const val SCANNER_STARTED = "scannerStarted"
    const val SCANNER_STOPPED = "scannerStopped"
    const val PERMISSION_DENIED = "permissionDenied"
    const val ERROR = "error"
    const val CAMERA_CHANGED = "cameraChanged"
    const val FLASH_CHANGED = "flashChanged"
    const val ZOOM_CHANGED = "zoomChanged"
}

/** Stable error codes mirrored in Dart `ScannerErrorCode`. */
internal object ErrorCode {
    const val PERMISSION_DENIED = "CAMERA_PERMISSION_DENIED"
    const val CAMERA_UNAVAILABLE = "CAMERA_UNAVAILABLE"
    const val INITIALIZATION_FAILED = "CAMERA_INITIALIZATION_FAILED"
    const val SCANNER_BUSY = "SCANNER_BUSY"
    const val DECODING_ERROR = "DECODING_ERROR"
    const val INVALID_CONFIGURATION = "INVALID_CONFIGURATION"
    const val UNSUPPORTED_DEVICE = "UNSUPPORTED_DEVICE"
}
