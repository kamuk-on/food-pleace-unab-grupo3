import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../shared/presentation/widgets/app_feedback.dart';
import '../../../shared/presentation/widgets/empty_state_card.dart';
import '../../../shared/presentation/widgets/error_state_card.dart';
import '../../../shared/presentation/widgets/loading_state.dart';
import '../../../shared/presentation/widgets/section_scaffold.dart';
import '../controllers/orders_controller.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_status.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({required this.orderId, super.key});

  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  OrdersController get _controller => AppServices.ordersController;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SectionScaffold(
          title: 'Detalle del pedido',
          child: _buildContent(context),
        );
      },
    );
  }

  bool get _canEdit => _controller.canEditSelected;

  bool get _canCancel => _controller.canCancelSelected;

  Widget _buildContent(BuildContext context) {
    if (_controller.detailLoading) {
      return const LoadingState(message: 'Cargando detalle del pedido...');
    }

    if (_controller.detailErrorMessage != null) {
      return ErrorStateCard(
        message: _controller.detailErrorMessage!,
        onRetry: _loadOrder,
      );
    }

    final Order? order = _controller.selectedOrder;
    if (order == null) {
      return const EmptyStateCard(
        icon: Icons.receipt_long_outlined,
        title: 'Pedido no disponible',
        message: 'No fue posible recuperar el detalle del pedido solicitado.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextButton.icon(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Volver a pedidos'),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _shortOrderId(order.id),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _StatusChip(status: order.status),
                    Text(_formatDate(order.createdAt)),
                  ],
                ),
                if (order.deliveryAddress != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text('Entrega: ${order.deliveryAddress}'),
                ],
                if (order.notes != null &&
                    order.notes!.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Text('Notas: ${order.notes}'),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Articulos', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (_controller.editableItems.isEmpty)
          const EmptyStateCard(
            icon: Icons.remove_shopping_cart_outlined,
            title: 'Este pedido no tiene articulos',
            message: 'Agrega al menos un articulo para poder guardar cambios.',
          )
        else
          ..._controller.editableItems.map(
            (EditableOrderItem item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OrderItemCard(
                item: item,
                editable:
                    _canEdit && !_controller.saving && !_controller.cancelling,
                onIncrease: () =>
                    _changeQuantity(item.productId, item.quantity + 1),
                onDecrease: () =>
                    _changeQuantity(item.productId, item.quantity - 1),
                onRemove: () => _removeItem(item.productId),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _SummaryRow(
                  label: 'Items',
                  value: '${_controller.editableItemCount}',
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'Total',
                  value: CurrencyFormatter.clp(_controller.editableTotal),
                  emphasize: true,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed:
                      _canEdit && !_controller.saving && !_controller.cancelling
                      ? _saveChanges
                      : null,
                  child: _controller.saving
                      ? const InlineLoader()
                      : const Text('Guardar cambios'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed:
                      _canCancel &&
                          !_controller.saving &&
                          !_controller.cancelling
                      ? _confirmCancel
                      : null,
                  child: _controller.cancelling
                      ? const InlineLoader()
                      : const Text('Cancelar pedido'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadOrder() async {
    await _controller.loadOrderDetail(widget.orderId);
  }

  void _changeQuantity(String productId, int quantity) {
    _controller.changeEditableQuantity(productId, quantity);
  }

  void _removeItem(String productId) {
    _controller.removeEditableItem(productId);
  }

  Future<void> _saveChanges() async {
    try {
      await _controller.saveSelectedOrder();

      if (!mounted) {
        return;
      }

      AppFeedback.showSuccess(context, 'Cambios guardados correctamente.');
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
    }
  }

  Future<void> _confirmCancel() async {
    final bool confirmed = await AppFeedback.confirmDestructiveAction(
      context,
      title: 'Cancelar pedido',
      message:
          'Esta accion cambiara el estado del pedido a cancelado. ¿Deseas continuar?',
      cancelLabel: 'Volver',
      confirmLabel: 'Cancelar pedido',
    );

    if (!confirmed) {
      return;
    }

    await _cancelOrder();
  }

  Future<void> _cancelOrder() async {
    try {
      await _controller.cancelSelectedOrder();

      if (!mounted) {
        return;
      }

      AppFeedback.showSuccess(context, 'Pedido cancelado correctamente.');
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
    }
  }

  String _shortOrderId(String value) {
    if (value.length <= 10) {
      return value;
    }
    return '${value.substring(0, 10)}...';
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} · $hour:$minute';
  }
}

class _OrderItemCard extends StatelessWidget {
  const _OrderItemCard({
    required this.item,
    required this.editable,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  final EditableOrderItem item;
  final bool editable;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          '${item.productName}, cantidad ${item.quantity}, subtotal ${CurrencyFormatter.clpSemantics(item.subtotal)}',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.productName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  IconButton(
                    onPressed: editable ? onDecrease : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '${item.quantity}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    onPressed: editable ? onIncrease : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  const Spacer(),
                  if (editable)
                    IconButton(
                      onPressed: onRemove,
                      icon: const Icon(Icons.delete_outline),
                    ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('Unitario: ${CurrencyFormatter.clp(item.unitPrice)}'),
                  Text(
                    'Subtotal: ${CurrencyFormatter.clp(item.subtotal)}',
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final ({Color background, Color foreground}) visual = switch (status) {
      OrderStatus.pending => (
        background: colors.primaryContainer,
        foreground: colors.onPrimaryContainer,
      ),
      OrderStatus.preparing => (
        background: colors.tertiaryContainer,
        foreground: colors.onTertiaryContainer,
      ),
      OrderStatus.ready => (
        background: colors.secondaryContainer,
        foreground: colors.onSecondaryContainer,
      ),
      OrderStatus.delivered => (
        background: colors.surfaceContainerHighest,
        foreground: colors.onSurfaceVariant,
      ),
      OrderStatus.cancelled => (
        background: colors.errorContainer,
        foreground: colors.onErrorContainer,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: visual.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: visual.foreground, fontWeight: FontWeight.w600),
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
