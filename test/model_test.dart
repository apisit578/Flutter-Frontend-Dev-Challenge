import 'package:flutter_test/flutter_test.dart';
import 'package:rescu/model/deal_model.dart';

void main() {
  test('DealModel parses API json', () {
    final deal = DealModel.fromJson({
      'id': 7,
      'name': 'Surprise Bakery Bag',
      'description': 'Assorted pastries',
      'imageUrl': 'https://example.com/img.jpg',
      'originalPrice': 150,
      'price': 49,
      'currencyCode': 'THB',
      'quantityLeft': 3,
      'storeId': 2,
      'storeName': 'Sunrise Bakehouse',
      'storeAddress': '1 Sukhumvit Soi 1, Bangkok',
      'lat': 13.75,
      'lng': 100.5,
      'rating': null,
      'tags': ['bestseller'],
      'pickupWindow': {
        'start': '2026-01-01T10:30:00.000Z',
        'end': '2026-01-01T14:00:00.000Z',
      },
      'flashSaleEndsAt': null,
    });

    expect(deal.id, 7);
    expect(deal.rating, isNull);
    expect(deal.discountPercent, 67);
    expect(deal.isFlashSale, isFalse);
    expect(deal.pickupWindow.start.isUtc, isTrue);
  });

  test('PickupWindowModel converts UTC to local for label and isToday', () {
    final now = DateTime.now();
    final todayLocalStart = DateTime(now.year, now.month, now.day, 10, 0);
    final todayLocalEnd = DateTime(now.year, now.month, now.day, 12, 0);

    final deal = DealModel.fromJson({
      'id': 1,
      'name': 'Test',
      'description': '',
      'imageUrl': '',
      'originalPrice': 100,
      'price': 50,
      'currencyCode': 'THB',
      'quantityLeft': 1,
      'storeId': 1,
      'storeName': '',
      'storeAddress': '',
      'lat': 0.0,
      'lng': 0.0,
      'rating': null,
      'tags': [],
      'pickupWindow': {
        'start': todayLocalStart.toUtc().toIso8601String(),
        'end': todayLocalEnd.toUtc().toIso8601String(),
      },
      'flashSaleEndsAt': null,
    });

    expect(deal.pickupWindow.label, '10:00 – 12:00');
    expect(deal.pickupWindow.isToday, isTrue);
  });
}
