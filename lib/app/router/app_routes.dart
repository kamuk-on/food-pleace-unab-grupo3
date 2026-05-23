abstract final class AppRoutes {
  static const String login = '/login';
  static const String menu = '/menu';
  static const String cart = '/cart';
  static const String orders = '/orders';
  static const String account = '/account';

  static String orderDetail(String orderId) => '/orders/$orderId';
}
