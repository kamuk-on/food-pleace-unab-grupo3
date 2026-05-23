import 'package:flutter/material.dart';

import '../../../../core/business/app_business_rules.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/repositories/orders_repository.dart';
import '../../domain/usecases/orders_use_cases.dart';

class OrdersController extends ChangeNotifier {
  OrdersController({
    required this._getOrdersUseCase,
    required this._getOrderDetailUseCase,
    required this._updateOrderUseCase,
    required this._cancelOrderUseCase,
  });

  final GetOrdersUseCase _getOrdersUseCase;
  final GetOrderDetailUseCase _getOrderDetailUseCase;
  final UpdateOrderUseCase _updateOrderUseCase;
  final CancelOrderUseCase _cancelOrderUseCase;

  bool _loading = false;
  bool _detailLoading = false;
  bool _saving = false;
  bool _cancelling = false;
  String? _errorMessage;
  String? _detailErrorMessage;
  List<Order> _orders = const <Order>[];
  Order? _selectedOrder;
  List<EditableOrderItem> _editableItems = const <EditableOrderItem>[];

  bool get loading => _loading;
  bool get detailLoading => _detailLoading;
  bool get saving => _saving;
  bool get cancelling => _cancelling;
  String? get errorMessage => _errorMessage;
  String? get detailErrorMessage => _detailErrorMessage;
  List<Order> get orders => List<Order>.unmodifiable(_orders);
  Order? get selectedOrder => _selectedOrder;
  List<EditableOrderItem> get editableItems =>
      List<EditableOrderItem>.unmodifiable(_editableItems);
  bool get hasOrders => _orders.isNotEmpty;
  bool get canEditSelected =>
      _selectedOrder != null &&
      AppBusinessRules.canEditOrder(_selectedOrder!.status);
  bool get canCancelSelected =>
      _selectedOrder != null &&
      AppBusinessRules.canCancelOrder(_selectedOrder!.status);
  int get editableItemCount => AppBusinessRules.calculateTotalQuantity(
    _editableItems.map((EditableOrderItem item) => item.quantity),
  );
  double get editableTotal => AppBusinessRules.calculateTotalAmount(
    _editableItems.map((EditableOrderItem item) => item.subtotal),
  );

  Future<void> loadOrders() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _orders = await _getOrdersUseCase();
    } catch (_) {
      _errorMessage = 'No fue posible cargar tus pedidos.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadOrderDetail(String orderId) async {
    _detailLoading = true;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      final Order order = await _getOrderDetailUseCase(orderId);
      _selectedOrder = order;
      _editableItems = order.items
          .map(EditableOrderItem.fromOrderItem)
          .toList(growable: true);
      _replaceOrder(order);
    } catch (_) {
      _detailErrorMessage = 'No fue posible cargar el detalle del pedido.';
    } finally {
      _detailLoading = false;
      notifyListeners();
    }
  }

  void changeEditableQuantity(String productId, int quantity) {
    final int index = _editableItems.indexWhere(
      (EditableOrderItem item) => item.productId == productId,
    );
    if (index == -1) {
      return;
    }

    if (!AppBusinessRules.hasMinimumQuantity(quantity)) {
      removeEditableItem(productId);
      return;
    }

    _editableItems[index] = _editableItems[index].copyWith(quantity: quantity);
    notifyListeners();
  }

  void removeEditableItem(String productId) {
    _editableItems.removeWhere(
      (EditableOrderItem item) => item.productId == productId,
    );
    notifyListeners();
  }

  Future<Order> saveSelectedOrder() async {
    final Order? order = _selectedOrder;
    if (order == null) {
      throw StateError('Pedido no disponible.');
    }
    if (!AppBusinessRules.canEditOrder(order.status)) {
      throw StateError('El pedido ya no se puede editar.');
    }
    if (!AppBusinessRules.hasLineItems(_editableItems.length)) {
      throw StateError('El pedido no puede quedar vacio.');
    }

    _saving = true;
    notifyListeners();

    try {
      final Order updated = await _updateOrderUseCase(
        orderId: order.id,
        items: _editableItems
            .map(
              (EditableOrderItem item) => OrderItemDraft(
                productId: item.productId,
                quantity: item.quantity,
              ),
            )
            .toList(growable: false),
        deliveryAddress: order.deliveryAddress,
        notes: order.notes,
      );
      _selectedOrder = updated;
      _editableItems = updated.items
          .map(EditableOrderItem.fromOrderItem)
          .toList(growable: true);
      _replaceOrder(updated);
      return updated;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<Order> cancelSelectedOrder() async {
    final Order? order = _selectedOrder;
    if (order == null) {
      throw StateError('Pedido no disponible.');
    }
    if (!AppBusinessRules.canCancelOrder(order.status)) {
      throw StateError('El pedido ya no se puede cancelar.');
    }

    _cancelling = true;
    notifyListeners();

    try {
      final Order cancelled = await _cancelOrderUseCase(order.id);
      _selectedOrder = cancelled;
      _editableItems = cancelled.items
          .map(EditableOrderItem.fromOrderItem)
          .toList(growable: true);
      _replaceOrder(cancelled);
      return cancelled;
    } finally {
      _cancelling = false;
      notifyListeners();
    }
  }

  void reset() {
    _loading = false;
    _detailLoading = false;
    _saving = false;
    _cancelling = false;
    _errorMessage = null;
    _detailErrorMessage = null;
    _orders = const <Order>[];
    _selectedOrder = null;
    _editableItems = const <EditableOrderItem>[];
    notifyListeners();
  }

  void _replaceOrder(Order order) {
    final int index = _orders.indexWhere((Order item) => item.id == order.id);
    if (index == -1) {
      _orders = <Order>[order, ..._orders];
      return;
    }
    _orders[index] = order;
  }
}

class EditableOrderItem {
  const EditableOrderItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  factory EditableOrderItem.fromOrderItem(OrderItem item) {
    return EditableOrderItem(
      productId: item.productId,
      productName: item.productName,
      unitPrice: item.unitPrice,
      quantity: item.quantity,
    );
  }

  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;

  double get subtotal => AppBusinessRules.calculateSubtotal(
    unitPrice: unitPrice,
    quantity: quantity,
  );

  EditableOrderItem copyWith({int? quantity}) {
    return EditableOrderItem(
      productId: productId,
      productName: productName,
      unitPrice: unitPrice,
      quantity: quantity ?? this.quantity,
    );
  }
}
