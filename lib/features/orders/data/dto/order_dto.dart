import '../../../shared/domain/parsing.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_status.dart';
import 'order_item_dto.dart';

class OrderDto {
  const OrderDto({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
    this.deliveryAddress,
    this.notes,
  });

  factory OrderDto.fromJson(Map<String, dynamic> json) {
    final List<Map<String, dynamic>> rawItems = JsonParser.requireObjectList(
      json,
      'items',
    );
    return OrderDto(
      id: JsonParser.requireString(json, 'id'),
      userId: JsonParser.requireString(json, 'user_id'),
      items: rawItems.map(OrderItemDto.fromJson).toList(growable: false),
      total: JsonParser.requireDouble(json, 'total'),
      status: JsonParser.requireString(json, 'status'),
      createdAt: JsonParser.requireDateTime(json, 'created_at'),
      deliveryAddress: JsonParser.optionalString(json, 'delivery_address'),
      notes: JsonParser.optionalString(json, 'notes'),
    );
  }

  factory OrderDto.fromEntity(Order order) {
    return OrderDto(
      id: order.id,
      userId: order.userId,
      items: order.items.map(OrderItemDto.fromEntity).toList(growable: false),
      total: order.total,
      status: order.status.apiValue,
      createdAt: order.createdAt,
      deliveryAddress: order.deliveryAddress,
      notes: order.notes,
    );
  }

  final String id;
  final String userId;
  final List<OrderItemDto> items;
  final double total;
  final String status;
  final DateTime createdAt;
  final String? deliveryAddress;
  final String? notes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'items': items
          .map((OrderItemDto e) => e.toJson())
          .toList(growable: false),
      'total': total,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      if (deliveryAddress != null) 'delivery_address': deliveryAddress,
      if (notes != null) 'notes': notes,
    };
  }

  Order toEntity() {
    return Order(
      id: id,
      userId: userId,
      items: items
          .map((OrderItemDto e) => e.toEntity())
          .toList(growable: false),
      total: total,
      status: OrderStatus.fromApiValue(status),
      createdAt: createdAt,
      deliveryAddress: deliveryAddress,
      notes: notes,
    );
  }
}
