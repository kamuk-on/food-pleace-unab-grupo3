import '../entities/menu_category.dart';
import '../entities/menu_product.dart';

abstract interface class MenuRepository {
  Future<List<MenuCategory>> getCategories();

  Future<List<MenuProduct>> getProducts({String? categoryId});
}
