import '../models/barcode_gen_result.dart';
import '../models/barcode_request.dart';

/// A bounded least-recently-used cache of rendered barcodes, keyed by
/// [BarcodeRequest] value equality. Dart's `LinkedHashMap` preserves insertion
/// order; re-inserting on access moves a key to most-recently-used.
class RenderCache {
  RenderCache({this.capacity = 256}) : assert(capacity > 0);

  final int capacity;
  final Map<BarcodeRequest, BarcodeGenResult> _entries = {};

  BarcodeGenResult? get(BarcodeRequest key) {
    final value = _entries.remove(key);
    if (value != null) _entries[key] = value; // mark most-recently-used
    return value;
  }

  void put(BarcodeRequest key, BarcodeGenResult value) {
    _entries.remove(key);
    _entries[key] = value;
    if (_entries.length > capacity) {
      _entries.remove(_entries.keys.first); // evict least-recently-used
    }
  }

  int get length => _entries.length;
}
