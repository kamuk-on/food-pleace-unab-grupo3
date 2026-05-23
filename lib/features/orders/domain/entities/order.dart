import 'order_item.dart';
import 'order_status.dart';
import '../../../../core/business/app_business_rules.dart';

/// Pedido realizado por un usuario.
class Order {
  const Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
    this.deliveryAddress,
    this.notes,
  });

  final String id;
  final String userId;
  final List<OrderItem> items;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
  final String? deliveryAddress;
  final String? notes;

  int get itemCount => AppBusinessRules.calculateTotalQuantity(
    items.map((OrderItem item) => item.quantity),
  );
}
