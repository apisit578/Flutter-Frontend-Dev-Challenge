import 'dart:async';
import 'package:flutter/material.dart';

import '../../../model/reservation_model.dart';

/// Shows a live countdown of remaining reservation time for a cart line item.
class ReservationCountdown extends StatefulWidget {
  final ReservationModel reservation;
  final VoidCallback? onExpired;

  const ReservationCountdown({
    super.key,
    required this.reservation,
    this.onExpired,
  });

  @override
  State<ReservationCountdown> createState() => _ReservationCountdownState();
}

class _ReservationCountdownState extends State<ReservationCountdown> {
  Timer? _timer;
  bool _hasFiredExpired = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(ReservationCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reservation.id != widget.reservation.id) {
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
    if (widget.reservation.isExpired) {
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

  @override
  Widget build(BuildContext context) {
    final remaining = widget.reservation.expiresAt.difference(DateTime.now().toUtc());
    if (remaining.isNegative) {
      return Text(
        'Hold expired',
        style: TextStyle(
          fontSize: 11.5,
          color: Colors.red.shade700,
          fontWeight: FontWeight.w500,
        ),
      );
    }
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_clock, size: 13, color: Colors.orange.shade800),
        const SizedBox(width: 3),
        Text(
          'Held for $timeStr',
          style: TextStyle(
            fontSize: 11.5,
            color: Colors.orange.shade800,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
