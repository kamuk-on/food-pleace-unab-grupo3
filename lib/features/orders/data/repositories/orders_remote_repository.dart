// ignore_for_file: prefer_initializing_formals

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/orders_repository.dart';
import '../dto/order_dto.dart';
import '../local/orders_local_data_source.dart';

class OrdersRemoteRepository implements OrdersRepository {
  OrdersRemoteRepository({
    required ApiClient apiClient,
    required OrdersLocalDataSource localDataSource,
  }) : _apiClient = apiClient,
       _localDataSource = localDataSource;

  final ApiClient _apiClient;
  final OrdersLocalDataSource _localDataSource;

  @override
  Future<Order> cancelOrder(String orderId) async {
    final Map<String, dynamic> payload = await _apiClient.post(
      'orders/$orderId/cancel',
      authenticated: true,
    );
    final OrderDto order = OrderDto.fromJson(payload);
    await _localDataSource.upsertOrder(order);
    return order.toEntity();
  }

  @override
  Future<Order> createOrder({
    required List<CartItem> items,
    String? deliveryAddress,
    String? notes,
  }) async {
    final Map<String, dynamic> payload = await _apiClient.post(
      'orders',
      authenticated: true,
      body: <String, dynamic>{
        'delivery_address': deliveryAddress,
        'notes': notes,
        'items': items
            .map(
              (CartItem item) => <String, dynamic>{
                'product_id': item.product.id,
                'quantity': item.quantity,
              },
            )
            .toList(growable: false),
      },
    );
    final OrderDto order = OrderDto.fromJson(payload);
    await _localDataSource.upsertOrder(order);
    return order.toEntity();
  }

  @override
  Future<Order> getOrderById(String orderId) async {
    try {
      final Map<String, dynamic> payload = await _apiClient.get(
        'orders/$orderId',
        authenticated: true,
      );
      final OrderDto order = OrderDto.fromJson(payload);
      await _localDataSource.upsertOrder(order);
      return order.toEntity();
    } on ApiException {
      final OrderDto? cached = await _localDataSource.readOrderById(orderId);
      if (cached != null) {
        return cached.toEntity();
      }
      rethrow;
    }
  }

  @override
  Future<List<Order>> getOrders() async {
    try {
      final Map<String, dynamic> payload = await _apiClient.get(
        'orders',
        authenticated: true,
      );
      final List<dynamic> items =
          payload['items'] as List<dynamic>? ?? <dynamic>[];
      final List<OrderDto> orders = items
          .whereType<Map<String, dynamic>>()
          .map(OrderDto.fromJson)
          .toList(growable: false);
      await _localDataSource.saveOrders(orders);
      return orders
          .map((OrderDto dto) => dto.toEntity())
          .toList(growable: false);
    } on ApiException {
      final List<OrderDto> cached = await _localDataSource.readOrders();
      if (cached.isNotEmpty) {
        return cached
            .map((OrderDto dto) => dto.toEntity())
            .toList(growable: false);
      }
      rethrow;
    }
  }

  @override
  Future<Order> updateOrder({
    required String orderId,
    required List<OrderItemDraft> items,
    String? deliveryAddress,
    String? notes,
  }) async {
    final Map<String, dynamic> payload = await _apiClient.put(
      'orders/$orderId',
      authenticated: true,
      body: <String, dynamic>{
        'delivery_address': deliveryAddress,
        'notes': notes,
        'items': items
            .map(
              (OrderItemDraft item) => <String, dynamic>{
                'product_id': item.productId,
                'quantity': item.quantity,
              },
            )
            .toList(growable: false),
      },
    );
    final OrderDto order = OrderDto.fromJson(payload);
    await _localDataSource.upsertOrder(order);
    return order.toEntity();
  }
}
