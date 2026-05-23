import '../../../menu/domain/entities/menu_product.dart';
import '../entities/cart_item.dart';

abstract interface class CartRepository {
  Future<List<CartItem>> getItems();

  Future<void> addProduct(MenuProduct product, {int quantity = 1});

  Future<void> updateQuantity(String productId, int quantity);

  Future<void> removeProduct(String productId);

  Future<void> clear();
}
