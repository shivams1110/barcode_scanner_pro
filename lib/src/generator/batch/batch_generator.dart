import '../models/barcode_gen_result.dart';
import '../models/barcode_request.dart';
import 'render_cache.dart';

/// Runs barcode generation over a list with bounded concurrency, an optional
/// LRU cache (duplicate requests render once), and event-loop yields between
/// groups to keep the UI isolate responsive. Results are returned in input
/// order regardless of completion order.
///
/// Note: within a single concurrent group, two identical requests could both
/// miss the cache and render twice (best-effort de-dup, not a lock). Place
/// duplicates in later groups (or use a lower concurrency) to guarantee
/// cache hits.
class BatchGenerator {
  const BatchGenerator();

  Future<List<BarcodeGenResult>> run(
    List<BarcodeRequest> requests,
    Future<BarcodeGenResult> Function(BarcodeRequest) generateOne, {
    int concurrency = 4,
    RenderCache? cache,
  }) async {
    final results = List<BarcodeGenResult?>.filled(requests.length, null);
    final window = concurrency < 1 ? 1 : concurrency;

    for (var start = 0; start < requests.length; start += window) {
      final end = (start + window).clamp(0, requests.length);
      await Future.wait([
        for (var i = start; i < end; i++)
          _one(i, requests[i], generateOne, cache, results),
      ]);
      await Future<void>.value(); // yield to event loop between groups
    }
    return results.cast<BarcodeGenResult>();
  }

  Future<void> _one(
    int index,
    BarcodeRequest req,
    Future<BarcodeGenResult> Function(BarcodeRequest) generateOne,
    RenderCache? cache,
    List<BarcodeGenResult?> out,
  ) async {
    final cached = cache?.get(req);
    if (cached != null) {
      out[index] = cached;
      return;
    }
    final result = await generateOne(req);
    cache?.put(req, result);
    out[index] = result;
  }
}
