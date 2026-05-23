import '../../../cart/domain/entities/cart_item.dart';
import '../entities/order.dart';

class OrderItemDraft {
  const OrderItemDraft({required this.productId, required this.quantity});

  final String productId;
  final int quantity;
}

abstract interface class OrdersRepository {
  Future<Order> createOrder({
    required List<CartItem> items,
    String? deliveryAddress,
    String? notes,
  });

  Future<List<Order>> getOrders();

  Future<Order> getOrderById(String orderId);

  Future<Order> updateOrder({
    required String orderId,
    required List<OrderItemDraft> items,
    String? deliveryAddress,
    String? notes,
  });

  Future<Order> cancelOrder(String orderId);
}
