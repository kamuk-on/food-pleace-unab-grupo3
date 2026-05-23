import '../../../cart/domain/entities/cart_item.dart';
import '../entities/order.dart';
import '../repositories/orders_repository.dart';

class CreateOrderUseCase {
  const CreateOrderUseCase(this._repository);

  final OrdersRepository _repository;

  Future<Order> call({
    required List<CartItem> items,
    String? deliveryAddress,
    String? notes,
  }) {
    return _repository.createOrder(
      items: items,
      deliveryAddress: deliveryAddress,
      notes: notes,
    );
  }
}

class GetOrdersUseCase {
  const GetOrdersUseCase(this._repository);

  final OrdersRepository _repository;

  Future<List<Order>> call() {
    return _repository.getOrders();
  }
}

class GetOrderDetailUseCase {
  const GetOrderDetailUseCase(this._repository);

  final OrdersRepository _repository;

  Future<Order> call(String orderId) {
    return _repository.getOrderById(orderId);
  }
}

class UpdateOrderUseCase {
  const UpdateOrderUseCase(this._repository);

  final OrdersRepository _repository;

  Future<Order> call({
    required String orderId,
    required List<OrderItemDraft> items,
    String? deliveryAddress,
    String? notes,
  }) {
    return _repository.updateOrder(
      orderId: orderId,
      items: items,
      deliveryAddress: deliveryAddress,
      notes: notes,
    );
  }
}

class CancelOrderUseCase {
  const CancelOrderUseCase(this._repository);

  final OrdersRepository _repository;

  Future<Order> call(String orderId) {
    return _repository.cancelOrder(orderId);
  }
}
