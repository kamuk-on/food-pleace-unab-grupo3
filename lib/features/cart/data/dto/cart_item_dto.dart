import '../../../menu/data/dto/menu_product_dto.dart';
import '../../../shared/domain/parsing.dart';
import '../../domain/entities/cart_item.dart';

class CartItemDto {
  const CartItemDto({required this.product, required this.quantity});

  factory CartItemDto.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? raw = json['product'] as Map<String, dynamic>?;
    if (raw == null) {
      throw ParsingException('product', 'Producto requerido en el cart item.');
    }
    return CartItemDto(
      product: MenuProductDto.fromJson(raw),
      quantity: JsonParser.requireInt(json, 'quantity'),
    );
  }

  factory CartItemDto.fromEntity(CartItem item) {
    return CartItemDto(
      product: MenuProductDto.fromEntity(item.product),
      quantity: item.quantity,
    );
  }

  final MenuProductDto product;
  final int quantity;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'product': product.toJson(), 'quantity': quantity};
  }

  CartItem toEntity() {
    return CartItem(product: product.toEntity(), quantity: quantity);
  }
}
