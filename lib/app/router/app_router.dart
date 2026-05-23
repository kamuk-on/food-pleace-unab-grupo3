import 'package:go_router/go_router.dart';

import '../../core/widgets/app_shell.dart';
import '../../features/account/presentation/screens/account_screen.dart';
import '../../features/auth/presentation/controllers/session_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/menu/presentation/screens/menu_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import 'app_routes.dart';

GoRouter buildRouter(SessionController sessionController) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: sessionController,
    redirect: (context, state) {
      final bool isLoggedIn = sessionController.isAuthenticated;
      final bool isOnLogin = state.matchedLocation == AppRoutes.login;

      if (!isLoggedIn && !isOnLogin) {
        return AppRoutes.login;
      }

      if (isLoggedIn && isOnLogin) {
        return AppRoutes.menu;
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.menu,
            builder: (context, state) => const MenuScreen(),
          ),
          GoRoute(
            path: AppRoutes.cart,
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: AppRoutes.orders,
            builder: (context, state) => const OrdersScreen(),
            routes: <RouteBase>[
              GoRoute(
                path: ':orderId',
                builder: (context, state) {
                  final String orderId =
                      state.pathParameters['orderId'] ?? 'unknown';
                  return OrderDetailScreen(orderId: orderId);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.account,
            builder: (context, state) => const AccountScreen(),
          ),
        ],
      ),
    ],
  );
}
