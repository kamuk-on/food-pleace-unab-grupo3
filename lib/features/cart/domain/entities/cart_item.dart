import '../../../menu/domain/entities/menu_product.dart';
import '../../../../core/business/app_business_rules.dart';

/// Item agregado al carrito por el usuario.
class CartItem {
  const CartItem({required this.product, required this.quantity})
    : assert(
        quantity >= AppBusinessRules.minimumQuantity,
        'La cantidad debe ser mayor a cero.',
      );

  final MenuProduct product;
  final int quantity;

  String get id => product.id;
  double get unitPrice => product.price;
  double get subtotal => AppBusinessRules.calculateSubtotal(
    unitPrice: product.price,
    quantity: quantity,
  );

  CartItem copyWith({int? quantity}) {
    return CartItem(product: product, quantity: quantity ?? this.quantity);
  }
}
