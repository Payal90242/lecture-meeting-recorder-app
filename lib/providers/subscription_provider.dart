import 'package:flutter/material.dart';
import '../services/revenuecat_service.dart';

class SubscriptionProvider with ChangeNotifier {
  final RevenueCatService _revenueCatService = RevenueCatService();

  bool _isPro = false;
  bool get isPro => _isPro;

  int _transcriptionUsageCount = 1; // Default 1 (the initial seed demo note)
  static const int freeTranscriptionLimit = 3;

  int get remainingFreeTranscriptions {
    final remaining = freeTranscriptionLimit - _transcriptionUsageCount;
    return remaining > 0 ? remaining : 0;
  }

  bool get canTranscribe => _isPro || _transcriptionUsageCount < freeTranscriptionLimit;

  SubscriptionProvider() {
    _init();
  }

  Future<void> _init() async {
    await _revenueCatService.init();
    _isPro = _revenueCatService.isProMember;
    _revenueCatService.subscriptionStatusStream.listen((status) {
      _isPro = status;
      notifyListeners();
    });
    notifyListeners();
  }

  void incrementUsage() {
    _transcriptionUsageCount++;
    notifyListeners();
  }

  Future<bool> restorePurchases() async {
    final restored = await _revenueCatService.restorePurchases();
    _isPro = restored;
    notifyListeners();
    return restored;
  }

  void toggleDevProStatus() {
    if (_isPro) {
      _revenueCatService.mockDowngradeToFree();
    } else {
      _revenueCatService.mockUpgradeToPro();
    }
  }
}
