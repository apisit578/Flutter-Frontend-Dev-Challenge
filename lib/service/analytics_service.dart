import 'dart:async';

import 'package:get/get.dart';

import '../service/fake_api_service.dart';
import '../util/log_service.dart';

class AnalyticsEvent {
  final String name;
  final Map<String, dynamic> properties;
  final DateTime at;

  AnalyticsEvent(this.name, this.properties) : at = DateTime.now();

  Map<String, dynamic> toJson() => {
        'name': name,
        'properties': properties,
        'at': at.toIso8601String(),
      };
}

/// In-memory analytics sink. Events are visible on the debug screen
/// (overflow menu on Home -> "Analytics debug") and in the console.
class AnalyticsService extends GetxService {
  final events = <AnalyticsEvent>[].obs;
  final Set<int> _impressedDealIds = {};
  final List<AnalyticsEvent> _pendingBatch = [];
  Timer? _batchTimer;

  bool isDealImpressed(int dealId) => _impressedDealIds.contains(dealId);

  void trackDealImpression({
    required int dealId,
    required String source,
    required int position,
  }) {
    if (_impressedDealIds.contains(dealId)) return;
    _impressedDealIds.add(dealId);

    logEvent('deal_impression', {
      'deal_id': dealId,
      'source': source,
      'position': position,
    });
  }

  void logEvent(String name, [Map<String, dynamic> properties = const {}]) {
    final event = AnalyticsEvent(name, properties);
    events.add(event);
    LogService.log('analytics: $name $properties');

    _queueForBatching(event);
  }

  void _queueForBatching(AnalyticsEvent event) {
    _pendingBatch.add(event);

    // If this is the first item in the batch, start the 15-second timer
    if (_pendingBatch.length == 1) {
      _batchTimer?.cancel();
      _batchTimer = Timer(const Duration(seconds: 15), () {
        _flushBatch();
      });
    }

    // If 10 items have accumulated, flush immediately
    if (_pendingBatch.length >= 10) {
      _flushBatch();
    }
  }

  Future<void> _flushBatch() async {
    _batchTimer?.cancel();
    if (_pendingBatch.isEmpty) return;

    final batchToSend = List<AnalyticsEvent>.from(_pendingBatch);
    _pendingBatch.clear();

    try {
      if (Get.isRegistered<FakeApiService>()) {
        final api = Get.find<FakeApiService>();
        final jsonBatch = batchToSend.map((e) => e.toJson()).toList();
        await api.sendAnalyticsBatch(jsonBatch);
      }
    } catch (e) {
      LogService.error('sendAnalyticsBatch failed', e);
    }
  }

  @override
  void onClose() {
    _batchTimer?.cancel();
    _flushBatch();
    super.onClose();
  }
}
