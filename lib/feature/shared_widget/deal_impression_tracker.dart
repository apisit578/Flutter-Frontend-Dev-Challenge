import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../service/analytics_service.dart';

/// Wraps a deal widget to track `deal_impression` when it has been
/// ≥50% visible for at least 1 continuous second.
class DealImpressionTracker extends StatefulWidget {
  final int dealId;
  final String source;
  final int position;
  final Widget child;

  const DealImpressionTracker({
    super.key,
    required this.dealId,
    required this.source,
    required this.position,
    required this.child,
  });

  @override
  State<DealImpressionTracker> createState() => _DealImpressionTrackerState();
}

class _DealImpressionTrackerState extends State<DealImpressionTracker> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return;

    if (!Get.isRegistered<AnalyticsService>()) return;
    final analytics = Get.find<AnalyticsService>();

    if (analytics.isDealImpressed(widget.dealId)) {
      _timer?.cancel();
      return;
    }

    if (info.visibleFraction >= 0.5) {
      if (_timer == null || !_timer!.isActive) {
        _timer = Timer(const Duration(seconds: 1), () {
          if (mounted) {
            analytics.trackDealImpression(
              dealId: widget.dealId,
              source: widget.source,
              position: widget.position,
            );
          }
        });
      }
    } else {
      _timer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('deal-impression-${widget.source}-${widget.position}-${widget.dealId}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: widget.child,
    );
  }
}
