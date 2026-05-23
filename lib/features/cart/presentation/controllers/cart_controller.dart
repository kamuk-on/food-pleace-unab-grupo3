import 'package:flutter/material.dart';

import '../../../../core/business/app_business_rules.dart';
import '../../../menu/domain/entities/menu_product.dart';
import '../../../orders/domain/entities/order.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/usecases/cart_use_cases.dart';
import '../../../orders/domain/usecases/orders_use_cases.dart';

class CartController extends ChangeNotifier {
  CartController({
    required this._getCartItemsUseCase,
    required this._addProductToCartUseCase,
    required this._updateCartItemQuantityUseCase,
    required this._removeCartItemUseCase,
    required this._clearCartUseCase,
    required this._createOrderUseCase,
  });

  final GetCartItemsUseCase _getCartItemsUseCase;
  final AddProductToCartUseCase _addProductToCartUseCase;
  final UpdateCartItemQuantityUseCase _updateCartItemQuantityUseCase;
  final RemoveCartItemUseCase _removeCartItemUseCase;
  final ClearCartUseCase _clearCartUseCase;
  final CreateOrderUseCase _createOrderUseCase;

  bool _loading = false;
  bool _updating = false;
  bool _checkingOut = false;
  String? _errorMessage;
  List<CartItem> _items = const <CartItem>[];

  bool get loading => _loading;
  bool get updating => _updating;
  bool get checkingOut => _checkingOut;
  bool get busy => _updating || _checkingOut;
  String? get errorMessage => _errorMessage;
  List<CartItem> get items => List<CartItem>.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  int get productCount => _items.length;
  int get itemCount => AppBusinessRules.calculateTotalQuantity(
    _items.map((CartItem item) => item.quantity),
  );
  double get total => AppBusinessRules.calculateTotalAmount(
    _items.map((CartItem item) => item.subtotal),
  );

  Future<void> loadCart() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _getCartItemsUseCase();
    } catch (_) {
      _errorMessage = 'No fue posible cargar el carrito.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addProduct(MenuProduct product) async {
    _updating = true;
    notifyListeners();

    try {
      await _addProductToCartUseCase(product);
      await _refreshItems();
    } finally {
      _updating = false;
      notifyListeners();
    }
  }

  Future<void> changeQuantity(String productId, int quantity) async {
    if (!AppBusinessRules.hasMinimumQuantity(quantity)) {
      await removeProduct(productId);
      return;
    }

    _updating = true;
    notifyListeners();

    try {
      await _updateCartItemQuantityUseCase(productId, quantity);
      await _refreshItems();
    } finally {
      _updating = false;
      notifyListeners();
    }
  }

  Future<void> removeProduct(String productId) async {
    _updating = true;
    notifyListeners();

    try {
      await _removeCartItemUseCase(productId);
      await _refreshItems();
    } finally {
      _updating = false;
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    _updating = true;
    notifyListeners();

    try {
      await _clearCartUseCase();
      _items = const <CartItem>[];
    } finally {
      _updating = false;
      notifyListeners();
    }
  }

  Future<Order> checkout({String? deliveryAddress, String? notes}) async {
    if (!AppBusinessRules.hasLineItems(_items.length)) {
      throw StateError('Tu carrito esta vacio.');
    }

    _checkingOut = true;
    notifyListeners();

    try {
      final Order order = await _createOrderUseCase(
        items: _items,
        deliveryAddress: deliveryAddress,
        notes: notes,
      );
      await _clearCartUseCase();
      _items = const <CartItem>[];
      return order;
    } finally {
      _checkingOut = false;
      notifyListeners();
    }
  }

  void reset() {
    _loading = false;
    _updating = false;
    _checkingOut = false;
    _errorMessage = null;
    _items = const <CartItem>[];
    notifyListeners();
  }

  Future<void> _refreshItems() async {
    _items = await _getCartItemsUseCase();
  }
}
