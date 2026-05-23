import '../../../shared/domain/parsing.dart';
import '../../domain/entities/menu_category.dart';

class MenuCategoryDto {
  const MenuCategoryDto({required this.id, required this.name, this.icon});

  factory MenuCategoryDto.fromJson(Map<String, dynamic> json) {
    return MenuCategoryDto(
      id: JsonParser.requireString(json, 'id'),
      name: JsonParser.requireString(json, 'name'),
      icon: JsonParser.optionalString(json, 'icon'),
    );
  }

  factory MenuCategoryDto.fromEntity(MenuCategory category) {
    return MenuCategoryDto(
      id: category.id,
      name: category.name,
      icon: category.icon,
    );
  }

  final String id;
  final String name;
  final String? icon;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      if (icon != null) 'icon': icon,
    };
  }

  MenuCategory toEntity() {
    return MenuCategory(id: id, name: name, icon: icon);
  }
}
