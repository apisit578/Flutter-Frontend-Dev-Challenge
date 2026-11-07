import 'dart:async';

import 'package:get/get.dart';

import '../../model/deal_model.dart';
import '../../repository/deal_repo.dart';
import '../../util/log_service.dart';

class SearchDealsController extends GetxController {
  final DealRepo dealRepo;

  SearchDealsController({required this.dealRepo});

  final results = <DealModel>[].obs;
  final isLoading = false.obs;
  final hasSearched = false.obs;

  Timer? _debounceTimer;
  String _currentQuery = '';

  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
  }

  void onQueryChanged(String query) {
    _debounceTimer?.cancel();
    _currentQuery = query;

    if (query.trim().isEmpty) {
      results.clear();
      hasSearched.value = false;
      isLoading.value = false;
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    isLoading.value = true;
    hasSearched.value = true;
    try {
      final found = await dealRepo.search(query);
      if (query == _currentQuery) {
        results.assignAll(found);
        isLoading.value = false;
      }
    } catch (e) {
      if (query == _currentQuery) {
        LogService.error('search failed', e);
        isLoading.value = false;
      }
    }
  }
}
