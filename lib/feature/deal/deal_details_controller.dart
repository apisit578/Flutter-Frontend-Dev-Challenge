import 'package:get/get.dart';

import '../../model/deal_model.dart';
import '../../repository/deal_repo.dart';
import '../../service/analytics_service.dart';
import '../../service/cart_service.dart';
import '../../util/log_service.dart';

class DealDetailsController extends GetxController {
  final DealRepo dealRepo;
  final CartService cartService;
  final AnalyticsService analytics;

  DealDetailsController({
    required this.dealRepo,
    required this.cartService,
    required this.analytics,
  });

  final _deal = Rxn<DealModel>();
  DealModel? get deal => _deal.value;

  final isLoading = true.obs;
  final _quantityLeft = RxnInt();
  int? get quantityLeft => _quantityLeft.value;

  Worker? _cartWorker;

  @override
  void onInit() {
    super.onInit();
    _initDeal();
    _cartWorker = ever(cartService.itemCount, (_) => _recheckAvailability());
  }

  Future<void> _initDeal() async {
    if (Get.arguments is DealModel) {
      final initialDeal = Get.arguments as DealModel;
      _deal.value = initialDeal;
      _quantityLeft.value = initialDeal.quantityLeft;
      isLoading.value = false;
      _logAnalytics(initialDeal.id);
    } else {
      final idParam = Get.parameters['id'];
      final id = int.tryParse(idParam ?? '');
      if (id != null) {
        isLoading.value = true;
        try {
          final fetched = await dealRepo.fetchById(id);
          _deal.value = fetched;
          _quantityLeft.value = fetched.quantityLeft;
          _logAnalytics(fetched.id);
        } catch (e) {
          LogService.error('fetch deal by id failed', e);
        } finally {
          isLoading.value = false;
        }
      } else {
        isLoading.value = false;
      }
    }
  }

  void _logAnalytics(int dealId) {
    analytics.logEvent('deal_details_view', {
      'deal_id': dealId,
      'source': Get.parameters['source'] ?? 'unknown',
    });
  }

  Future<void> _recheckAvailability() async {
    final d = deal;
    if (d == null) return;
    LogService.log('re-checking availability for deal ${d.id}');
    try {
      final fresh = await dealRepo.fetchById(d.id);
      _quantityLeft.value = fresh.quantityLeft;
    } catch (e) {
      LogService.error('recheck availability failed', e);
    }
  }

  void addToCart() {
    final d = deal;
    if (d == null) return;
    cartService.add(d);
    Get.snackbar(
      'Added to bag',
      '${d.name} — pick up ${d.pickupWindow.label}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void onClose() {
    _cartWorker?.dispose();
    super.onClose();
  }
}
