import 'package:sqflite/sqflite.dart';

import '../../../../core/local/app_database.dart';
import '../dto/menu_category_dto.dart';
import '../dto/menu_product_dto.dart';

class MenuLocalDataSource {
  MenuLocalDataSource({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<void> saveCatalog({
    required List<MenuCategoryDto> categories,
    required List<MenuProductDto> products,
  }) async {
    final database = await _database.database;
    final String timestamp = DateTime.now().toIso8601String();

    await database.transaction((transaction) async {
      await transaction.delete(AppDatabaseTables.menuProducts);
      await transaction.delete(AppDatabaseTables.menuCategories);

      final Batch batch = transaction.batch();

      for (final MenuCategoryDto category in categories) {
        batch.insert(AppDatabaseTables.menuCategories, <String, Object?>{
          'id': category.id,
          'name': category.name,
          'icon': category.icon,
          'cached_at': timestamp,
        });
      }

      for (final MenuProductDto product in products) {
        batch.insert(AppDatabaseTables.menuProducts, <String, Object?>{
          'id': product.id,
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'category_id': product.categoryId,
          'category_name': product.categoryName,
          'image_url': product.imageUrl,
          'available': product.available ? 1 : 0,
          'cached_at': timestamp,
        });
      }

      await batch.commit(noResult: true);
    });
  }

  Future<List<MenuCategoryDto>> readCategories() async {
    final database = await _database.database;
    final List<Map<String, Object?>> rows = await database.query(
      AppDatabaseTables.menuCategories,
      orderBy: 'name ASC',
    );

    return rows.map(_mapCategory).toList(growable: false);
  }

  Future<List<MenuProductDto>> readProducts({String? categoryId}) async {
    final database = await _database.database;
    final List<Map<String, Object?>> rows = await database.query(
      AppDatabaseTables.menuProducts,
      where: categoryId == null ? null : 'category_id = ?',
      whereArgs: categoryId == null ? null : <Object?>[categoryId],
      orderBy: 'name ASC',
    );

    return rows.map(_mapProduct).toList(growable: false);
  }

  MenuCategoryDto _mapCategory(Map<String, Object?> row) {
    return MenuCategoryDto(
      id: row['id']! as String,
      name: row['name']! as String,
      icon: row['icon'] as String?,
    );
  }

  MenuProductDto _mapProduct(Map<String, Object?> row) {
    return MenuProductDto(
      id: row['id']! as String,
      name: row['name']! as String,
      description: row['description']! as String,
      price: (row['price']! as num).toDouble(),
      categoryId: row['category_id']! as String,
      categoryName: row['category_name']! as String,
      imageUrl: row['image_url']! as String,
      available: (row['available']! as int) == 1,
    );
  }
}
