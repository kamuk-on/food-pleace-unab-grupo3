import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../shared/presentation/widgets/empty_state_card.dart';
import '../../../shared/presentation/widgets/error_state_card.dart';
import '../../../shared/presentation/widgets/loading_state.dart';
import '../../../shared/presentation/widgets/section_scaffold.dart';
import '../controllers/orders_controller.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/order_status.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  OrdersController get _controller => AppServices.ordersController;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SectionScaffold(
          title: 'Mis pedidos',
          child: _buildContent(context),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_controller.loading) {
      return const LoadingState(message: 'Cargando tus pedidos...');
    }

    if (_controller.errorMessage != null) {
      return ErrorStateCard(
        message: _controller.errorMessage!,
        onRetry: _loadOrders,
      );
    }

    if (!_controller.hasOrders) {
      return EmptyStateCard(
        icon: Icons.receipt_long_outlined,
        title: 'Aun no tienes pedidos',
        message:
            'Cuando confirmes una compra, aqui veras el historial ordenado del mas reciente al mas antiguo.',
      );
    }

    return Column(
      children: _controller.orders
          .map(
            (Order order) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OrderCard(
                order: order,
                onTap: () async {
                  await context.push(AppRoutes.orderDetail(order.id));
                  if (mounted) {
                    await _loadOrders();
                  }
                },
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Future<void> _loadOrders() async {
    await _controller.loadOrders();
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final _OrderVisualState visual = _visualForStatus(order.status, colors);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: visual.background,
                foregroundColor: visual.foreground,
                child: const Icon(Icons.receipt_long_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _shortOrderId(order.id),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(_formatDate(order.createdAt)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: visual.background,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            order.status.label,
                            style: TextStyle(
                              color: visual.foreground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          _buildItemSummary(order),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.clp(order.total),
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildItemSummary(Order order) {
    if (order.items.isEmpty) {
      return 'Sin articulos';
    }

    final OrderItem first = order.items.first;
    if (order.items.length == 1) {
      return '${first.quantity} x ${first.productName}';
    }

    return '${first.quantity} x ${first.productName} + ${order.items.length - 1} mas';
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} · $hour:$minute';
  }

  String _shortOrderId(String value) {
    if (value.length <= 10) {
      return value;
    }
    return '${value.substring(0, 10)}...';
  }

  _OrderVisualState _visualForStatus(OrderStatus status, ColorScheme colors) {
    switch (status) {
      case OrderStatus.pending:
        return _OrderVisualState(
          background: colors.primaryContainer,
          foreground: colors.onPrimaryContainer,
        );
      case OrderStatus.preparing:
        return _OrderVisualState(
          background: colors.tertiaryContainer,
          foreground: colors.onTertiaryContainer,
        );
      case OrderStatus.ready:
        return _OrderVisualState(
          background: colors.secondaryContainer,
          foreground: colors.onSecondaryContainer,
        );
      case OrderStatus.delivered:
        return _OrderVisualState(
          background: colors.surfaceContainerHighest,
          foreground: colors.onSurfaceVariant,
        );
      case OrderStatus.cancelled:
        return _OrderVisualState(
          background: colors.errorContainer,
          foreground: colors.onErrorContainer,
        );
    }
  }
}

class _OrderVisualState {
  const _OrderVisualState({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
