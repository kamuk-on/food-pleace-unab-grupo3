/// Categoria a la que pertenece un producto del menu.
class MenuCategory {
  const MenuCategory({required this.id, required this.name, this.icon});

  final String id;
  final String name;
  final String? icon;
}
