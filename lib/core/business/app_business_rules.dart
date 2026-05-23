import '../../features/orders/domain/entities/order_status.dart';

abstract final class AppBusinessRules {
  static const int minimumQuantity = 1;

  static double calculateSubtotal({
    required double unitPrice,
    required int quantity,
  }) {
    return unitPrice * quantity;
  }

  static double calculateTotalAmount(Iterable<double> subtotals) {
    return subtotals.fold(0, (double sum, double value) => sum + value);
  }

  static int calculateTotalQuantity(Iterable<int> quantities) {
    return quantities.fold(0, (int sum, int value) => sum + value);
  }

  static bool hasMinimumQuantity(int quantity) {
    return quantity >= minimumQuantity;
  }

  static bool hasLineItems(int itemCount) {
    return itemCount > 0;
  }

  static bool hasRequiredText(String value) {
    return value.trim().isNotEmpty;
  }

  static bool canEditOrder(OrderStatus status) {
    return status == OrderStatus.pending;
  }

  static bool canCancelOrder(OrderStatus status) {
    return status == OrderStatus.pending || status == OrderStatus.preparing;
  }
}
