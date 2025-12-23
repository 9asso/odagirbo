import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_config.dart';

class IAPService {
  static IAPService? _instance;
  final InAppPurchase _iap = InAppPurchase.instance;
  late AppConfig _config;
  late SharedPreferences _prefs;
  
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  Map<String, ProductDetails> _products = {};
  bool _purchaseInProgress = false;
  bool _hasActiveSubscription = false;
  DateTime? _subscriptionExpiryDate;
  String? _activeSubscriptionType;

  // Keys for SharedPreferences
  static const String _keyHasSubscription = 'has_subscription';
  static const String _keySubscriptionExpiry = 'subscription_expiry';
  static const String _keySubscriptionType = 'subscription_type';

  static Future<IAPService> getInstance() async {
    if (_instance == null) {
      _instance = IAPService._();
      await _instance!._initialize();
    }
    return _instance!;
  }

  IAPService._();

  Future<void> _initialize() async {
    _config = await AppConfig.getInstance();
    _prefs = await SharedPreferences.getInstance();
    
    // Load subscription status from local storage
    await _loadSubscriptionStatus();
    
    _isAvailable = await _iap.isAvailable();
    
    if (!_isAvailable) {
      print('In-app purchase is not available');
      return;
    }

    // Load products
    await _loadProducts();

    // Listen to purchase updates
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => print('Purchase error: $error'),
    );

    // Restore purchases on init to check active subscriptions
    await _silentRestorePurchases();
  }

  Future<void> _loadSubscriptionStatus() async {
    _hasActiveSubscription = _prefs.getBool(_keyHasSubscription) ?? false;
    final expiryString = _prefs.getString(_keySubscriptionExpiry);
    _activeSubscriptionType = _prefs.getString(_keySubscriptionType);
    
    if (expiryString != null) {
      _subscriptionExpiryDate = DateTime.parse(expiryString);
      
      // Check if subscription has expired
      if (_subscriptionExpiryDate!.isBefore(DateTime.now())) {
        await _clearSubscriptionStatus();
      }
    }
    
    print('Subscription status loaded: active=$_hasActiveSubscription, type=$_activeSubscriptionType, expiry=$_subscriptionExpiryDate');
  }

  Future<void> _saveSubscriptionStatus(String type, DateTime? expiryDate) async {
    _hasActiveSubscription = true;
    _activeSubscriptionType = type;
    _subscriptionExpiryDate = expiryDate;
    
    await _prefs.setBool(_keyHasSubscription, true);
    await _prefs.setString(_keySubscriptionType, type);
    if (expiryDate != null) {
      await _prefs.setString(_keySubscriptionExpiry, expiryDate.toIso8601String());
    }
    
    print('Subscription status saved: type=$type, expiry=$expiryDate');
  }

  Future<void> _clearSubscriptionStatus() async {
    _hasActiveSubscription = false;
    _activeSubscriptionType = null;
    _subscriptionExpiryDate = null;
    
    await _prefs.remove(_keyHasSubscription);
    await _prefs.remove(_keySubscriptionType);
    await _prefs.remove(_keySubscriptionExpiry);
    
    print('Subscription status cleared');
  }

  Future<void> _loadProducts() async {
    if (!_isAvailable) return;

    final Set<String> productIds = {};
    final platform = Platform.isAndroid ? 'android' : 'ios';
    
    // Load all subscription types
    for (final type in _config.subscriptionTypes) {
      final productId = _config.getSubscriptionProductId(type, platform);
      if (productId.isNotEmpty) {
        productIds.add(productId);
      }
    }

    if (productIds.isEmpty) {
      print('No product IDs configured');
      return;
    }

    print('Loading products: $productIds');
    final ProductDetailsResponse response = await _iap.queryProductDetails(productIds);
    
    if (response.notFoundIDs.isNotEmpty) {
      print('Products not found: ${response.notFoundIDs}');
    }

    if (response.error != null) {
      print('Error loading products: ${response.error}');
      return;
    }

    for (final product in response.productDetails) {
      _products[product.id] = product;
    }
    
    print('Loaded ${_products.length} products');
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      print('Purchase status: ${purchaseDetails.status} for ${purchaseDetails.productID}');
      
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _showPendingUI();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          _handleError(purchaseDetails.error!);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          _verifyPurchase(purchaseDetails);
        }

        if (purchaseDetails.pendingCompletePurchase) {
          _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  void _showPendingUI() {
    print('Purchase is pending...');
  }

  void _handleError(IAPError error) {
    _purchaseInProgress = false;
    print('Purchase error: ${error.message}');
  }

  Future<void> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    print('Verifying purchase: ${purchaseDetails.productID}');
    _purchaseInProgress = false;
    
    // Determine subscription type from product ID
    String? subscriptionType;
    for (final type in _config.subscriptionTypes) {
      final platform = Platform.isAndroid ? 'android' : 'ios';
      final productId = _config.getSubscriptionProductId(type, platform);
      if (productId == purchaseDetails.productID) {
        subscriptionType = type;
        break;
      }
    }
    
    if (subscriptionType == null) {
      print('Unknown product ID: ${purchaseDetails.productID}');
      return;
    }
    
    // Calculate expiry date
    DateTime? expiryDate;
    if (subscriptionType == 'lifetime') {
      // Lifetime never expires
      expiryDate = null;
    } else if (subscriptionType == 'weekly') {
      expiryDate = DateTime.now().add(const Duration(days: 7));
    } else if (subscriptionType == 'monthly') {
      expiryDate = DateTime.now().add(const Duration(days: 30));
    }
    
    await _saveSubscriptionStatus(subscriptionType, expiryDate);
  }

  Future<bool> purchaseSubscription({
    required String type,
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    if (!_isAvailable) {
      onError('In-app purchase is not available');
      return false;
    }

    if (_purchaseInProgress) {
      onError('Purchase already in progress');
      return false;
    }

    if (_products.isEmpty) {
      await _loadProducts();
      if (_products.isEmpty) {
        onError('Products not found');
        return false;
      }
    }

    final platform = Platform.isAndroid ? 'android' : 'ios';
    final productId = _config.getSubscriptionProductId(type, platform);
    
    if (productId.isEmpty) {
      onError('Product ID not configured for $type');
      return false;
    }

    final ProductDetails? productDetails = _products[productId];
    if (productDetails == null) {
      onError('Product not found: $productId');
      return false;
    }

    _purchaseInProgress = true;

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );

    try {
      bool success;
      if (type == 'lifetime') {
        // Lifetime is non-consumable
        success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        // Weekly and monthly are subscriptions
        success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
        // Note: On iOS, use buyConsumable for auto-renewable subscriptions
        // On Android, all are treated similarly
      }

      if (!success) {
        _purchaseInProgress = false;
        onError('Failed to initiate purchase');
        return false;
      }

      return true;
    } catch (e) {
      _purchaseInProgress = false;
      onError('Purchase error: $e');
      return false;
    }
  }

  Future<void> _silentRestorePurchases() async {
    if (!_isAvailable) return;

    try {
      await _iap.restorePurchases();
    } catch (e) {
      print('Silent restore error: $e');
    }
  }

  Future<void> restorePurchases({
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    if (!_isAvailable) {
      onError('In-app purchase is not available');
      return;
    }

    try {
      await _iap.restorePurchases();
      if (_hasActiveSubscription) {
        onSuccess();
      } else {
        onError('No active subscriptions found');
      }
    } catch (e) {
      onError('Restore error: $e');
    }
  }

  String? getProductPrice(String type) {
    final platform = Platform.isAndroid ? 'android' : 'ios';
    final productId = _config.getSubscriptionProductId(type, platform);
    return _products[productId]?.price;
  }

  bool get hasActiveSubscription => _hasActiveSubscription;
  String? get activeSubscriptionType => _activeSubscriptionType;
  DateTime? get subscriptionExpiryDate => _subscriptionExpiryDate;
  bool get isPurchaseInProgress => _purchaseInProgress;
  Map<String, ProductDetails> get products => _products;

  void dispose() {
    _subscription?.cancel();
  }
}
