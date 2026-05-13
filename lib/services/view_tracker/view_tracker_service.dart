import 'dart:async';
import 'package:twizzy_app/services/twizz_service/twizz_service.dart';

class ViewTrackerService {
  final TwizzService _twizzService;
  final Set<String> _pendingViewIds = {};
  final Map<String, Timer> _viewTimers = {};
  Timer? _flushTimer;

  ViewTrackerService(this._twizzService);

  void reportVisibility(String twizzId, double fraction) {
    if (fraction >= 0.5) {
      if (!_pendingViewIds.contains(twizzId) && !_viewTimers.containsKey(twizzId)) {
        _viewTimers[twizzId] = Timer(const Duration(seconds: 2), () {
          _viewTimers.remove(twizzId);
          markAsViewed(twizzId);
        });
      }
    } else {
      _viewTimers[twizzId]?.cancel();
      _viewTimers.remove(twizzId);
    }
  }

  void markAsViewed(String twizzId) {
    if (_pendingViewIds.contains(twizzId)) return;

    _pendingViewIds.add(twizzId);

    if (_pendingViewIds.length >= 10) {
      _flush();
    } else {
      _flushTimer?.cancel();
      _flushTimer = Timer(const Duration(seconds: 30), _flush);
    }
  }

  Future<void> _flush() async {
    if (_pendingViewIds.isEmpty) return;

    final ids = List<String>.from(_pendingViewIds);
    _pendingViewIds.clear();

    try {
      await _twizzService.markTwizzsAsViewed(ids);
    } catch (e) {
      print('Failed to mark views: $e');
      // Thêm lại vào buffer nếu lỗi (tuỳ chiến lược)
      // _pendingViewIds.addAll(ids);
    }
  }

  Future<void> flushNow() async {
    _flushTimer?.cancel();
    await _flush();
  }

  void dispose() {
    for (var timer in _viewTimers.values) {
      timer.cancel();
    }
    _viewTimers.clear();
    flushNow();
  }
}
