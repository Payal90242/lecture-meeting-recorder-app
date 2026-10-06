import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Subscription tier details
enum SubscriptionTier { free, pro }

/// Service managing RevenueCat SDK configuration, paywall offerings, and in-app subscriptions.
class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  // Public SDK Keys from RevenueCat Dashboard (Replace with real keys)
  static const _apiKeyAndroid = 'goog_sample_rc_android_key_placeholder';
  static const _apiKeyApple = 'appl_sample_rc_apple_key_placeholder';
  static const String entitlementId = 'pro_access';

  bool _isInitialized = false;
  bool _isProMember = false;
  bool get isProMember => _isProMember;

  final StreamController<bool> _subscriptionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get subscriptionStatusStream => _subscriptionStatusController.stream;

  /// Initialize RevenueCat SDK
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await Purchases.setLogLevel(LogLevel.debug);

        PurchasesConfiguration configuration;
        if (Platform.isAndroid) {
          configuration = PurchasesConfiguration(_apiKeyAndroid);
        } else {
          configuration = PurchasesConfiguration(_apiKeyApple);
        }

        await Purchases.configure(configuration);

        // Listen for real-time customer info updates
        Purchases.addCustomerInfoUpdateListener((customerInfo) {
          _updateCustomerStatus(customerInfo);
        });

        // Initial customer check
        final customerInfo = await Purchases.getCustomerInfo();
        _updateCustomerStatus(customerInfo);
        _isInitialized = true;
      }
    } catch (e) {
      debugPrint('RevenueCat initialization notice: $e (Running in test/mock mode)');
      _isInitialized = true;
    }
  }

  void _updateCustomerStatus(CustomerInfo customerInfo) {
    final entitlement = customerInfo.entitlements.all[entitlementId];
    _isProMember = entitlement?.isActive ?? false;
    _subscriptionStatusController.add(_isProMember);
  }

  /// Fetch current offerings configured in RevenueCat dashboard
  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('Error fetching RevenueCat offerings: $e');
      return null;
    }
  }

  /// Purchase selected subscription package
  Future<bool> purchasePackage(Package package) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      final isSubscribed = customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
      _isProMember = isSubscribed;
      _subscriptionStatusController.add(_isProMember);
      return isSubscribed;
    } catch (e) {
      debugPrint('Purchase error: $e');
      return false;
    }
  }

  /// Restore previous purchases (Required by App Store & Google Play guidelines)
  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      final isSubscribed = customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
      _isProMember = isSubscribed;
      _subscriptionStatusController.add(_isProMember);
      return isSubscribed;
    } catch (e) {
      debugPrint('Restore purchases error: $e');
      return false;
    }
  }

  /// Mock Purchase method for local testing and developer preview
  void mockUpgradeToPro() {
    _isProMember = true;
    _subscriptionStatusController.add(true);
  }

  /// Reset to Free tier for testing
  void mockDowngradeToFree() {
    _isProMember = false;
    _subscriptionStatusController.add(false);
  }

  void dispose() {
    _subscriptionStatusController.close();
  }
}
