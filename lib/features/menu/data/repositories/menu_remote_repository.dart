// ignore_for_file: prefer_initializing_formals

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/menu_category.dart';
import '../../domain/entities/menu_product.dart';
import '../../domain/repositories/menu_repository.dart';
import '../dto/menu_category_dto.dart';
import '../dto/menu_product_dto.dart';
import '../local/menu_local_data_source.dart';

class MenuRemoteRepository implements MenuRepository {
  MenuRemoteRepository({
    required ApiClient apiClient,
    required MenuLocalDataSource localDataSource,
  }) : _apiClient = apiClient,
       _localDataSource = localDataSource;

  final ApiClient _apiClient;
  final MenuLocalDataSource _localDataSource;

  @override
  Future<List<MenuCategory>> getCategories() async {
    try {
      final Map<String, dynamic> payload = await _apiClient.get(
        'menu/categories',
      );
      final List<dynamic> items =
          payload['items'] as List<dynamic>? ?? <dynamic>[];
      final List<MenuCategoryDto> categories = items
          .whereType<Map<String, dynamic>>()
          .map(MenuCategoryDto.fromJson)
          .toList(growable: false);
      final List<MenuProductDto> cachedProducts = await _localDataSource
          .readProducts();
      await _localDataSource.saveCatalog(
        categories: categories,
        products: cachedProducts,
      );
      return categories
          .map((MenuCategoryDto dto) => dto.toEntity())
          .toList(growable: false);
    } on ApiException {
      final List<MenuCategoryDto> cached = await _localDataSource
          .readCategories();
      if (cached.isNotEmpty) {
        return cached
            .map((MenuCategoryDto dto) => dto.toEntity())
            .toList(growable: false);
      }
      rethrow;
    }
  }

  @override
  Future<List<MenuProduct>> getProducts({String? categoryId}) async {
    try {
      final Map<String, dynamic> payload = await _apiClient.get(
        'menu/products',
        queryParameters: categoryId == null
            ? null
            : <String, String>{'category_id': categoryId},
      );
      final List<dynamic> items =
          payload['items'] as List<dynamic>? ?? <dynamic>[];
      final List<MenuProductDto> products = items
          .whereType<Map<String, dynamic>>()
          .map(MenuProductDto.fromJson)
          .toList(growable: false);
      final List<MenuCategoryDto> categories = await _localDataSource
          .readCategories();
      await _localDataSource.saveCatalog(
        categories: categories,
        products: products,
      );
      return products
          .map((MenuProductDto dto) => dto.toEntity())
          .toList(growable: false);
    } on ApiException {
      final List<MenuProductDto> cached = await _localDataSource.readProducts(
        categoryId: categoryId,
      );
      if (cached.isNotEmpty) {
        return cached
            .map((MenuProductDto dto) => dto.toEntity())
            .toList(growable: false);
      }
      rethrow;
    }
  }
}
