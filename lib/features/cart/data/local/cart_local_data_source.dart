import 'package:sqflite/sqflite.dart';

import '../../../../core/local/app_database.dart';
import '../../../menu/data/dto/menu_product_dto.dart';
import '../dto/cart_item_dto.dart';

class CartLocalDataSource {
  CartLocalDataSource({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<CartItemDto>> readItems() async {
    final database = await _database.database;
    final List<Map<String, Object?>> rows = await database.query(
      AppDatabaseTables.cartItems,
      orderBy: 'added_at ASC',
    );

    return rows.map(_mapCartItem).toList(growable: false);
  }

  Future<void> saveItems(List<CartItemDto> items) async {
    final database = await _database.database;
    await database.transaction((transaction) async {
      await transaction.delete(AppDatabaseTables.cartItems);

      final Batch batch = transaction.batch();
      final String timestamp = DateTime.now().toIso8601String();

      for (final CartItemDto item in items) {
        batch.insert(AppDatabaseTables.cartItems, <String, Object?>{
          'product_id': item.product.id,
          'product_name': item.product.name,
          'description': item.product.description,
          'unit_price': item.product.price,
          'category_id': item.product.categoryId,
          'category_name': item.product.categoryName,
          'image_url': item.product.imageUrl,
          'available': item.product.available ? 1 : 0,
          'quantity': item.quantity,
          'added_at': timestamp,
        });
      }

      await batch.commit(noResult: true);
    });
  }

  Future<void> clear() async {
    final database = await _database.database;
    await database.delete(AppDatabaseTables.cartItems);
  }

  CartItemDto _mapCartItem(Map<String, Object?> row) {
    return CartItemDto(
      product: MenuProductDto(
        id: row['product_id']! as String,
        name: row['product_name']! as String,
        description: row['description']! as String,
        price: (row['unit_price']! as num).toDouble(),
        categoryId: row['category_id']! as String,
        categoryName: row['category_name']! as String,
        imageUrl: row['image_url']! as String,
        available: (row['available']! as int) == 1,
      ),
      quantity: row['quantity']! as int,
    );
  }
}
