import '../../../shared/domain/parsing.dart';
import '../../domain/entities/order_item.dart';

class OrderItemDto {
  const OrderItemDto({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  factory OrderItemDto.fromJson(Map<String, dynamic> json) {
    return OrderItemDto(
      productId: JsonParser.requireString(json, 'product_id'),
      productName: JsonParser.requireString(json, 'product_name'),
      unitPrice: JsonParser.requireDouble(json, 'unit_price'),
      quantity: JsonParser.requireInt(json, 'quantity'),
    );
  }

  factory OrderItemDto.fromEntity(OrderItem item) {
    return OrderItemDto(
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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'product_id': productId,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
    };
  }

  OrderItem toEntity() {
    return OrderItem(
      productId: productId,
      productName: productName,
      unitPrice: unitPrice,
      quantity: quantity,
    );
  }
}
