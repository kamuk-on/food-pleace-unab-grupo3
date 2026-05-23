import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../shared/presentation/widgets/app_feedback.dart';
import '../../../shared/presentation/widgets/empty_state_card.dart';
import '../../../shared/presentation/widgets/error_state_card.dart';
import '../../../shared/presentation/widgets/loading_state.dart';
import '../../../shared/presentation/widgets/remote_image.dart';
import '../../../shared/presentation/widgets/section_scaffold.dart';
import '../controllers/cart_controller.dart';
import '../../domain/entities/cart_item.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  CartController get _controller => AppServices.cartController;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SectionScaffold(title: 'Carrito', child: _buildContent(context));
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_controller.loading) {
      return const LoadingState(message: 'Cargando tu carrito...');
    }

    if (_controller.errorMessage != null) {
      return ErrorStateCard(
        message: _controller.errorMessage!,
        onRetry: _loadCart,
      );
    }

    if (_controller.isEmpty) {
      return EmptyStateCard(
        icon: Icons.shopping_bag_outlined,
        title: 'Tu carrito esta vacio',
        message:
            'Agrega productos desde el menu para ver aqui cantidades, subtotales y el total de tu pedido.',
        action: ElevatedButton.icon(
          onPressed: () => context.go(AppRoutes.menu),
          icon: const Icon(Icons.restaurant_menu_outlined),
          label: const Text('Ir al menu'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              '${_controller.productCount} productos en tu pedido',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton.icon(
              onPressed: _controller.busy ? null : _clearCart,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Vaciar carrito'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _controller.items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _CartItemCard(
            item: _controller.items[index],
            enabled: !_controller.busy,
            onIncrease: () => _changeQuantity(
              _controller.items[index],
              _controller.items[index].quantity + 1,
            ),
            onDecrease: () => _changeQuantity(
              _controller.items[index],
              _controller.items[index].quantity - 1,
            ),
            onRemove: () => _removeItem(_controller.items[index]),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _SummaryRow(label: 'Items', value: '${_controller.itemCount}'),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'Total',
                  value: CurrencyFormatter.clp(_controller.total),
                  emphasize: true,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _controller.busy ? null : _checkout,
                  child: _controller.checkingOut
                      ? const InlineLoader()
                      : const Text('Confirmar pedido'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadCart() async {
    await _controller.loadCart();
  }

  Future<void> _changeQuantity(CartItem item, int quantity) async {
    try {
      await _controller.changeQuantity(item.id, quantity);
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppFeedback.showError(context, 'No fue posible actualizar la cantidad.');
    }
  }

  Future<void> _removeItem(CartItem item) async {
    try {
      await _controller.removeProduct(item.id);
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppFeedback.showError(context, 'No fue posible eliminar el producto.');
    }
  }

  Future<void> _clearCart() async {
    final bool confirmed = await AppFeedback.confirmDestructiveAction(
      context,
      title: 'Vaciar carrito',
      message:
          'Se eliminaran todos los productos de tu carrito actual. ¿Deseas continuar?',
      confirmLabel: 'Vaciar carrito',
    );

    if (!confirmed) {
      return;
    }

    try {
      await _controller.clearCart();

      if (!mounted) {
        return;
      }

      AppFeedback.showSuccess(context, 'Carrito vaciado correctamente.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppFeedback.showError(context, 'No fue posible vaciar el carrito.');
    }
  }

  Future<void> _checkout() async {
    if (_controller.isEmpty) {
      AppFeedback.showError(context, 'Tu carrito esta vacio.');
      return;
    }

    try {
      await _controller.checkout();
      await AppServices.ordersController.loadOrders();

      if (!mounted) {
        return;
      }

      AppFeedback.showSuccess(context, 'Pedido creado correctamente.');
      context.go(AppRoutes.orders);
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }
      AppFeedback.showError(context, error.message);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      AppFeedback.showError(context, error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppFeedback.showError(context, 'No fue posible confirmar el pedido.');
    }
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.enabled,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  final CartItem item;
  final bool enabled;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          '${item.product.name}, cantidad ${item.quantity}, subtotal ${CurrencyFormatter.clpSemantics(item.subtotal)}',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              RemoteImage(
                imageUrl: item.product.imageUrl,
                width: 88,
                height: 88,
                borderRadius: BorderRadius.circular(16),
                fallbackIcon: Icons.fastfood,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.product.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.product.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        IconButton(
                          onPressed: enabled ? onDecrease : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '${item.quantity}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          onPressed: enabled ? onIncrease : null,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: enabled ? onRemove : null,
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    CurrencyFormatter.clp(item.unitPrice),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.clp(item.subtotal),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final TextStyle? baseStyle = emphasize
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label, style: baseStyle),
        Text(
          value,
          style: baseStyle?.copyWith(
            fontWeight: emphasize ? FontWeight.w700 : baseStyle.fontWeight,
          ),
        ),
      ],
    );
  }
}
