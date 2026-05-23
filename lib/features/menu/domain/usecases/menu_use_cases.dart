import '../entities/menu_category.dart';
import '../entities/menu_product.dart';
import '../repositories/menu_repository.dart';

class GetMenuCategoriesUseCase {
  const GetMenuCategoriesUseCase(this._repository);

  final MenuRepository _repository;

  Future<List<MenuCategory>> call() {
    return _repository.getCategories();
  }
}

class GetMenuUseCase {
  const GetMenuUseCase(this._repository);

  final MenuRepository _repository;

  Future<List<MenuProduct>> call() {
    return _repository.getProducts();
  }
}

class FilterMenuByCategoryUseCase {
  const FilterMenuByCategoryUseCase(this._repository);

  final MenuRepository _repository;

  Future<List<MenuProduct>> call(String? categoryId) {
    return _repository.getProducts(categoryId: categoryId);
  }
}
