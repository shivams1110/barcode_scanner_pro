package com.umda.barcode_scanner_pro

import com.google.mlkit.vision.barcode.common.Barcode

/**
 * Translates between the cross-platform format bitmask (defined in Dart
 * `BarcodeFormat`) and ML Kit's [Barcode] format constants.
 */
internal object FormatMapper {

    // Bit positions must match Dart `BarcodeFormat.bit`.
    private const val QR = 1 shl 0
    private const val CODE128 = 1 shl 1
    private const val CODE39 = 1 shl 2
    private const val CODE93 = 1 shl 3
    private const val EAN8 = 1 shl 4
    private const val EAN13 = 1 shl 5
    private const val UPC_A = 1 shl 6
    private const val UPC_E = 1 shl 7
    private const val PDF417 = 1 shl 8
    private const val AZTEC = 1 shl 9
    private const val DATA_MATRIX = 1 shl 10
    private const val ITF = 1 shl 11
    private const val CODABAR = 1 shl 12
    // Generator-added formats (bits must match Dart, even when ML Kit cannot
    // detect them as a distinct symbology). See toMlKitFlags for which collapse
    // onto a parent format and which are generate-only.
    private const val GS128 = 1 shl 13
    private const val ITF14 = 1 shl 14
    private const val ITF16 = 1 shl 15
    private const val EAN5 = 1 shl 16
    private const val EAN2 = 1 shl 17
    private const val ISBN = 1 shl 18
    private const val TELEPEN = 1 shl 19
    private const val RM4SCC = 1 shl 20
    private const val POSTNET = 1 shl 21

    /**
     * Builds the ML Kit format flags from our bitmask.
     *
     * ML Kit has no dedicated constant for several generator formats, so they
     * collapse onto the symbology ML Kit actually detects:
     *  - GS1-128 is a Code 128 application → [Barcode.FORMAT_CODE_128]
     *  - ITF-14 / ITF-16 are fixed-length ITF → [Barcode.FORMAT_ITF]
     *  - ISBN is encoded as EAN-13 → [Barcode.FORMAT_EAN_13]
     * A scan therefore reports the parent format's bit, not the requested subset.
     *
     * EAN-2, EAN-5, Telepen, RM4SCC and POSTNET are generate-only: ML Kit cannot
     * detect them, so requesting them adds no flag (silently ignored).
     */
    fun toMlKitFlags(mask: Int): Int {
        var flags = 0
        if (mask and QR != 0) flags = flags or Barcode.FORMAT_QR_CODE
        if (mask and CODE128 != 0) flags = flags or Barcode.FORMAT_CODE_128
        if (mask and CODE39 != 0) flags = flags or Barcode.FORMAT_CODE_39
        if (mask and CODE93 != 0) flags = flags or Barcode.FORMAT_CODE_93
        if (mask and EAN8 != 0) flags = flags or Barcode.FORMAT_EAN_8
        if (mask and EAN13 != 0) flags = flags or Barcode.FORMAT_EAN_13
        if (mask and UPC_A != 0) flags = flags or Barcode.FORMAT_UPC_A
        if (mask and UPC_E != 0) flags = flags or Barcode.FORMAT_UPC_E
        if (mask and PDF417 != 0) flags = flags or Barcode.FORMAT_PDF417
        if (mask and AZTEC != 0) flags = flags or Barcode.FORMAT_AZTEC
        if (mask and DATA_MATRIX != 0) flags = flags or Barcode.FORMAT_DATA_MATRIX
        if (mask and ITF != 0) flags = flags or Barcode.FORMAT_ITF
        if (mask and CODABAR != 0) flags = flags or Barcode.FORMAT_CODABAR
        // Subset formats collapse onto their detectable parent symbology.
        if (mask and GS128 != 0) flags = flags or Barcode.FORMAT_CODE_128
        if (mask and (ITF14 or ITF16) != 0) flags = flags or Barcode.FORMAT_ITF
        if (mask and ISBN != 0) flags = flags or Barcode.FORMAT_EAN_13
        return flags
    }

    /** Maps an ML Kit detected format back to our single-format bit value. */
    fun toBit(mlkitFormat: Int): Int = when (mlkitFormat) {
        Barcode.FORMAT_QR_CODE -> QR
        Barcode.FORMAT_CODE_128 -> CODE128
        Barcode.FORMAT_CODE_39 -> CODE39
        Barcode.FORMAT_CODE_93 -> CODE93
        Barcode.FORMAT_EAN_8 -> EAN8
        Barcode.FORMAT_EAN_13 -> EAN13
        Barcode.FORMAT_UPC_A -> UPC_A
        Barcode.FORMAT_UPC_E -> UPC_E
        Barcode.FORMAT_PDF417 -> PDF417
        Barcode.FORMAT_AZTEC -> AZTEC
        Barcode.FORMAT_DATA_MATRIX -> DATA_MATRIX
        Barcode.FORMAT_ITF -> ITF
        Barcode.FORMAT_CODABAR -> CODABAR
        else -> QR
    }
}
