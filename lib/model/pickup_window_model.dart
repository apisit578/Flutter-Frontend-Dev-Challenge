import 'package:intl/intl.dart';

/// A store's pickup window. The API sends instants as ISO-8601 UTC strings.
class PickupWindowModel {
  final DateTime start;
  final DateTime end;

  const PickupWindowModel({required this.start, required this.end});

  factory PickupWindowModel.fromJson(Map<String, dynamic> json) {
    return PickupWindowModel(
      start: DateTime.parse(json['start'] as String? ?? ''),
      end: DateTime.parse(json['end'] as String? ?? ''),
    );
  }

  /// Human readable label, e.g. "17:30 – 21:00".
  String get label {
    final localStart = start.toLocal();
    final localEnd = end.toLocal();
    return '${DateFormat('HH:mm').format(localStart)} – ${DateFormat('HH:mm').format(localEnd)}';
  }

  /// Whether pickup starts today.
  bool get isToday {
    final now = DateTime.now();
    final localStart = start.toLocal();
    return localStart.year == now.year &&
        localStart.month == now.month &&
        localStart.day == now.day;
  }

  /// Whether the store is currently accepting pickups.
  bool get isOpenNow {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }

  Duration get untilStart => start.difference(DateTime.now());
}
