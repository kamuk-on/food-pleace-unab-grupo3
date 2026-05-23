import '../../../shared/domain/parsing.dart';
import '../../domain/entities/menu_product.dart';

class MenuProductDto {
  const MenuProductDto({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.categoryName,
    required this.imageUrl,
    required this.available,
  });

  factory MenuProductDto.fromJson(Map<String, dynamic> json) {
    return MenuProductDto(
      id: JsonParser.requireString(json, 'id'),
      name: JsonParser.requireString(json, 'name'),
      description: JsonParser.requireString(json, 'description'),
      price: JsonParser.requireDouble(json, 'price'),
      categoryId: JsonParser.requireString(json, 'category_id'),
      categoryName: JsonParser.requireString(json, 'category_name'),
      imageUrl: JsonParser.requireString(json, 'image_url'),
      available: JsonParser.optionalBool(json, 'available', defaultValue: true),
    );
  }

  factory MenuProductDto.fromEntity(MenuProduct product) {
    return MenuProductDto(
      id: product.id,
      name: product.name,
      description: product.description,
      price: product.price,
      categoryId: product.categoryId,
      categoryName: product.categoryName,
      imageUrl: product.imageUrl,
      available: product.available,
    );
  }

  final String id;
  final String name;
  final String description;
  final double price;
  final String categoryId;
  final String categoryName;
  final String imageUrl;
  final bool available;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category_id': categoryId,
      'category_name': categoryName,
      'image_url': imageUrl,
      'available': available,
    };
  }

  MenuProduct toEntity() {
    return MenuProduct(
      id: id,
      name: name,
      description: description,
      price: price,
      categoryId: categoryId,
      categoryName: categoryName,
      imageUrl: imageUrl,
      available: available,
    );
  }
}
