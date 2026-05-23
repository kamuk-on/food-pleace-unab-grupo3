import '../../../menu/domain/entities/menu_product.dart';
import '../entities/cart_item.dart';
import '../repositories/cart_repository.dart';

class GetCartItemsUseCase {
  const GetCartItemsUseCase(this._repository);

  final CartRepository _repository;

  Future<List<CartItem>> call() {
    return _repository.getItems();
  }
}

class AddProductToCartUseCase {
  const AddProductToCartUseCase(this._repository);

  final CartRepository _repository;

  Future<void> call(MenuProduct product, {int quantity = 1}) {
    return _repository.addProduct(product, quantity: quantity);
  }
}

class UpdateCartItemQuantityUseCase {
  const UpdateCartItemQuantityUseCase(this._repository);

  final CartRepository _repository;

  Future<void> call(String productId, int quantity) {
    return _repository.updateQuantity(productId, quantity);
  }
}

class RemoveCartItemUseCase {
  const RemoveCartItemUseCase(this._repository);

  final CartRepository _repository;

  Future<void> call(String productId) {
    return _repository.removeProduct(productId);
  }
}

class ClearCartUseCase {
  const ClearCartUseCase(this._repository);

  final CartRepository _repository;

  Future<void> call() {
    return _repository.clear();
  }
}
