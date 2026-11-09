import 'package:get/get.dart';

import '../model/cart_item_model.dart';
import '../model/deal_model.dart';
import '../repository/order_repo.dart';
import '../service/api_exception.dart';
import '../util/log_service.dart';

/// App-wide cart. Lives for the whole session.
class CartService extends GetxService {
  final items = <CartItemModel>[].obs;
  final itemCount = 0.obs;

  void add(DealModel deal) {
    final existing = items.firstWhereOrNull((i) => i.deal.id == deal.id);
    if (existing != null) {
      if (existing.quantity >= deal.quantityLeft) {
        LogService.log('cart: cannot add more of deal ${deal.id}');
        return;
      }
      existing.quantity++;
      items.refresh();
      _recount();
      _reserveOptimistically(existing, deal.id, existing.quantity);
    } else {
      final newItem = CartItemModel(deal: deal);
      items.add(newItem);
      _recount();
      _reserveOptimistically(newItem, deal.id, 1);
    }
  }

  Future<void> _reserveOptimistically(
      CartItemModel item, int dealId, int newQuantity) async {
    if (!Get.isRegistered<OrderRepo>()) return;
    final orderRepo = Get.find<OrderRepo>();

    if (item.reservation != null) {
      final oldResId = item.reservation!.id;
      item.reservation = null;
      orderRepo.releaseReservation(oldResId).catchError((e) {
        LogService.error('release old reservation failed', e);
      });
    }

    try {
      final reservation =
          await orderRepo.reserve(dealId, quantity: newQuantity);
      item.reservation = reservation;
      items.refresh();
    } on ApiException catch (e) {
      LogService.error('optimistic reservation failed', e);

      if (item.quantity > 1) {
        item.quantity--;
      } else {
        items.remove(item);
      }
      items.refresh();
      _recount();

      Get.snackbar(
        'Could not reserve stock',
        e.message.isNotEmpty
            ? e.message
            : 'Someone grabbed the item. It was removed from your bag.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      LogService.error('reservation error', e);
    }
  }

  void decrement(int dealId) {
    final existing = items.firstWhereOrNull((i) => i.deal.id == dealId);
    if (existing == null) return;

    if (existing.reservation != null && Get.isRegistered<OrderRepo>()) {
      Get.find<OrderRepo>()
          .releaseReservation(existing.reservation!.id)
          .catchError((e) => LogService.error('release reservation error', e));
    }

    existing.quantity--;
    if (existing.quantity <= 0) {
      items.removeWhere((i) => i.deal.id == dealId);
    } else {
      existing.reservation = null;
      items.refresh();
      _reserveOptimistically(existing, dealId, existing.quantity);
    }
    _recount();
  }

  void remove(int dealId) {
    final existing = items.firstWhereOrNull((i) => i.deal.id == dealId);
    if (existing?.reservation != null && Get.isRegistered<OrderRepo>()) {
      Get.find<OrderRepo>()
          .releaseReservation(existing!.reservation!.id)
          .catchError((e) => LogService.error('release reservation error', e));
    }
    items.removeWhere((i) => i.deal.id == dealId);
    _recount();
  }

  void purgeExpiredReservations() {
    final expired =
        items.where((i) => i.reservation?.isExpired ?? false).toList();
    if (expired.isNotEmpty) {
      for (final item in expired) {
        items.remove(item);
        Get.snackbar(
          'Hold Expired',
          '${item.deal.name} stock hold expired and was removed from your bag.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
      _recount();
    }
  }

  void clear() {
    items.clear();
    _recount();
  }

  num get total => items.fold(0, (sum, i) => sum + i.lineTotal);

  void _recount() {
    itemCount.value = items.fold(0, (sum, i) => sum + i.quantity);
  }
}
