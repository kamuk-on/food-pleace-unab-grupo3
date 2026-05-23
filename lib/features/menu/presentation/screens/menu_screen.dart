import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../shared/presentation/widgets/empty_state_card.dart';
import '../../../shared/presentation/widgets/error_state_card.dart';
import '../../../shared/presentation/widgets/loading_state.dart';
import '../../../shared/presentation/widgets/remote_image.dart';
import '../../../shared/presentation/widgets/section_scaffold.dart';
import '../../domain/entities/menu_category.dart';
import '../../domain/entities/menu_product.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  static const MenuCategory _allCategory = MenuCategory(
    id: 'all',
    name: 'Todos',
  );

  bool _loading = true;
  bool _addingToCart = false;
  String? _errorMessage;
  String? _selectedCategoryId;
  List<MenuCategory> _categories = const <MenuCategory>[_allCategory];
  List<MenuProduct> _products = const <MenuProduct>[];

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  @override
  Widget build(BuildContext context) {
    return SectionScaffold(
      title: 'Menu disponible',
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_loading) {
      return const LoadingState(message: 'Cargando menu disponible...');
    }

    if (_errorMessage != null) {
      return ErrorStateCard(message: _errorMessage!, onRetry: _loadMenu);
    }

    if (_products.isEmpty) {
      return EmptyStateCard(
        icon: Icons.no_food_outlined,
        title: 'No hay productos disponibles',
        message:
            'Prueba cambiando de categoria o recarga el menu para intentarlo otra vez.',
        action: OutlinedButton.icon(
          onPressed: _loadMenu,
          icon: const Icon(Icons.refresh),
          label: const Text('Recargar menu'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final MenuCategory category = _categories[index];
              final bool selected =
                  (_selectedCategoryId ?? _allCategory.id) == category.id;
              return ChoiceChip(
                selected: selected,
                label: Text(category.name),
                onSelected: (_) => _handleCategorySelected(category.id),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _products.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _MenuCard(
              item: _products[index],
              addingToCart: _addingToCart,
              onAdd: _addProductToCart,
            );
          },
        ),
      ],
    );
  }

  Future<void> _loadMenu() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final Future<List<MenuCategory>> categoriesFuture =
          AppServices.getMenuCategoriesUseCase();
      final Future<List<MenuProduct>> productsFuture =
          AppServices.getMenuUseCase();
      final List<Object> results = await Future.wait<Object>(<Future<Object>>[
        categoriesFuture,
        productsFuture,
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _categories = <MenuCategory>[
          _allCategory,
          ...(results[0] as List<MenuCategory>),
        ];
        _products = results[1] as List<MenuProduct>;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = 'No fue posible cargar el menu.';
      });
    }
  }

  Future<void> _handleCategorySelected(String categoryId) async {
    final String? selected = categoryId == _allCategory.id ? null : categoryId;

    setState(() {
      _selectedCategoryId = selected;
      _loading = true;
      _errorMessage = null;
    });

    try {
      final List<MenuProduct> products =
          await AppServices.filterMenuByCategoryUseCase(selected);

      if (!mounted) {
        return;
      }

      setState(() {
        _products = products;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = 'No fue posible filtrar el menu.';
      });
    }
  }

  Future<void> _addProductToCart(MenuProduct product) async {
    if (!product.available || _addingToCart) {
      return;
    }

    setState(() {
      _addingToCart = true;
    });

    try {
      await AppServices.cartController.addProduct(product);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('${product.name} se agrego al carrito.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'No fue posible agregar el producto al carrito. $error',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _addingToCart = false;
        });
      }
    }
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.item,
    required this.addingToCart,
    required this.onAdd,
  });

  final MenuProduct item;
  final bool addingToCart;
  final ValueChanged<MenuProduct> onAdd;

  @override
  Widget build(BuildContext context) {
    final bool isCompact = MediaQuery.of(context).size.width < 360;
    final bool canAdd = item.available && !addingToCart;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            RemoteImage(
              imageUrl: item.imageUrl,
              width: isCompact ? 72 : 88,
              height: isCompact ? 72 : 88,
              borderRadius: BorderRadius.circular(16),
              fallbackIcon: Icons.fastfood,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(item.categoryName),
                      ),
                      if (!item.available)
                        Chip(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.errorContainer,
                          label: Text(
                            'No disponible',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        CurrencyFormatter.clp(item.price),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: canAdd ? () => onAdd(item) : null,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: addingToCart && item.available
                              ? const InlineLoader(size: 16, strokeWidth: 2)
                              : Text(item.available ? 'Agregar' : 'Agotado'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
