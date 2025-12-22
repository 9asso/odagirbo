import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'app_config.dart';

class IAPService {
  static IAPService? _instance;
  final InAppPurchase _iap = InAppPurchase.instance;
  late AppConfig _config;
  
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  bool _purchaseInProgress = false;

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
  }

  Future<void> _loadProducts() async {
    if (!_isAvailable) return;

    final String productId = Platform.isAndroid 
        ? _config.androidSubscriptionProductId 
        : _config.iosSubscriptionProductId;

    if (productId.isEmpty) {
      print('Product ID not configured');
      return;
    }

    final ProductDetailsResponse response = await _iap.queryProductDetails({productId});
    
    if (response.notFoundIDs.isNotEmpty) {
      print('Products not found: ${response.notFoundIDs}');
    }

    if (response.error != null) {
      print('Error loading products: ${response.error}');
      return;
    }

    _products = response.productDetails;
    print('Loaded ${_products.length} products');
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      print('Purchase status: ${purchaseDetails.status}');
      
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
    // Here you would verify the purchase with your backend
    // For now, we'll just mark it as successful
    print('Purchase verified: ${purchaseDetails.productID}');
    _purchaseInProgress = false;
    
    // Save subscription status locally
    // You can use shared_preferences or your own state management
  }

  Future<bool> purchaseSubscription({
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
        onError('Product not found');
        return false;
      }
    }

    _purchaseInProgress = true;
    final ProductDetails productDetails = _products.first;

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );

    try {
      final bool success = await _iap.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

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
      onSuccess();
    } catch (e) {
      onError('Restore error: $e');
    }
  }

  String? get productPrice {
    if (_products.isEmpty) return null;
    return _products.first.price;
  }

  bool get isPurchaseInProgress => _purchaseInProgress;

  void dispose() {
    _subscription?.cancel();
  }
}
