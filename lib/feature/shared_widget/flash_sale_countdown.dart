import 'dart:async';
import 'package:flutter/material.dart';

/// Live countdown widget for flash sales (`mm:ss`, or `hh:mm:ss` if > 1 hour).
/// Scoped to update only its own text every second to maintain performance.
class FlashSaleCountdown extends StatefulWidget {
  final DateTime flashSaleEndsAt;
  final VoidCallback? onExpired;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;
  final BoxDecoration? decoration;

  const FlashSaleCountdown({
    super.key,
    required this.flashSaleEndsAt,
    this.onExpired,
    this.textStyle,
    this.padding,
    this.decoration,
  });

  @override
  State<FlashSaleCountdown> createState() => _FlashSaleCountdownState();
}

class _FlashSaleCountdownState extends State<FlashSaleCountdown> {
  Timer? _timer;
  bool _hasFiredExpired = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(FlashSaleCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flashSaleEndsAt != widget.flashSaleEndsAt) {
      _hasFiredExpired = false;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _checkExpiration();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
        _checkExpiration();
      }
    });
  }

  void _checkExpiration() {
    final remaining = widget.flashSaleEndsAt.difference(DateTime.now());
    if (remaining.isNegative || remaining == Duration.zero) {
      if (!_hasFiredExpired) {
        _hasFiredExpired = true;
        widget.onExpired?.call();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d.isNegative || d == Duration.zero) return 'Expired';
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.flashSaleEndsAt.difference(DateTime.now());
    final isExpired = remaining.isNegative || remaining == Duration.zero;

    final defaultDecoration = BoxDecoration(
      color: isExpired ? Colors.grey.shade600 : Colors.red.shade600,
      borderRadius: BorderRadius.circular(6),
    );

    final defaultTextStyle = const TextStyle(
      color: Colors.white,
      fontSize: 11,
      fontWeight: FontWeight.bold,
    );

    return Container(
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: widget.decoration ?? defaultDecoration,
      child: Text(
        _formatDuration(remaining),
        style: widget.textStyle ?? defaultTextStyle,
      ),
    );
  }
}
