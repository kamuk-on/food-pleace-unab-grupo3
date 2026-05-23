// ignore_for_file: prefer_initializing_formals

import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repository.dart';
import '../../../menu/domain/entities/menu_product.dart';
import '../dto/cart_item_dto.dart';
import '../local/cart_local_data_source.dart';

class CartLocalRepository implements CartRepository {
  CartLocalRepository({required CartLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  final CartLocalDataSource _localDataSource;

  @override
  Future<void> addProduct(MenuProduct product, {int quantity = 1}) async {
    final List<CartItemDto> current = List<CartItemDto>.of(
      await _localDataSource.readItems(),
    );
    final int existingIndex = current.indexWhere(
      (CartItemDto item) => item.product.id == product.id,
    );

    if (existingIndex == -1) {
      current.add(
        CartItemDto.fromEntity(CartItem(product: product, quantity: quantity)),
      );
    } else {
      final CartItemDto existing = current[existingIndex];
      current[existingIndex] = CartItemDto(
        product: existing.product,
        quantity: existing.quantity + quantity,
      );
    }

    await _localDataSource.saveItems(current);
  }

  @override
  Future<void> clear() {
    return _localDataSource.clear();
  }

  @override
  Future<List<CartItem>> getItems() async {
    final List<CartItemDto> items = await _localDataSource.readItems();
    return items
        .map((CartItemDto dto) => dto.toEntity())
        .toList(growable: false);
  }

  @override
  Future<void> removeProduct(String productId) async {
    final List<CartItemDto> current = List<CartItemDto>.of(
      await _localDataSource.readItems(),
    );
    current.removeWhere((CartItemDto item) => item.product.id == productId);
    await _localDataSource.saveItems(current);
  }

  @override
  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity <= 0) {
      await removeProduct(productId);
      return;
    }

    final List<CartItemDto> current = List<CartItemDto>.of(
      await _localDataSource.readItems(),
    );
    final int existingIndex = current.indexWhere(
      (CartItemDto item) => item.product.id == productId,
    );
    if (existingIndex == -1) {
      return;
    }

    final CartItemDto existing = current[existingIndex];
    current[existingIndex] = CartItemDto(
      product: existing.product,
      quantity: quantity,
    );
    await _localDataSource.saveItems(current);
  }
}
