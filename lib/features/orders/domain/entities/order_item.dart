import '../../../../core/business/app_business_rules.dart';

/// Linea de detalle de un pedido. Conserva precio y nombre al momento de la compra.
class OrderItem {
  const OrderItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  }) : assert(
         quantity >= AppBusinessRules.minimumQuantity,
         'La cantidad debe ser mayor a cero.',
       );

  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;

  double get subtotal => AppBusinessRules.calculateSubtotal(
    unitPrice: unitPrice,
    quantity: quantity,
  );
}
