import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../di/service_locator.dart';
import '../theme/app_colors.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    final int currentIndex = _indexFromLocation(location);

    return AnimatedBuilder(
      animation: AppServices.cartController,
      builder: (context, _) {
        final int cartItemCount = AppServices.cartController.itemCount;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: <Widget>[
                Semantics(
                  label: 'Logo de FoodPlease',
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const ExcludeSemantics(
                      child: Text(
                        'FP',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('FoodPlease'),
              ],
            ),
          ),
          body: SafeArea(child: child),
          bottomNavigationBar: Semantics(
            container: true,
            label: 'Navegacion principal',
            child: NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) => _onSelect(context, index),
              destinations: <NavigationDestination>[
                const NavigationDestination(
                  icon: Icon(Icons.restaurant_menu),
                  label: 'Menu',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: cartItemCount > 0,
                    label: Text('$cartItemCount'),
                    child: const Icon(Icons.shopping_cart_outlined),
                  ),
                  label: 'Carrito',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  label: 'Pedidos',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  label: 'Cuenta',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _indexFromLocation(String location) {
    if (location.startsWith(AppRoutes.cart)) {
      return 1;
    }
    if (location.startsWith(AppRoutes.orders)) {
      return 2;
    }
    if (location.startsWith(AppRoutes.account)) {
      return 3;
    }
    return 0;
  }

  void _onSelect(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.menu);
      case 1:
        context.go(AppRoutes.cart);
      case 2:
        context.go(AppRoutes.orders);
      case 3:
        context.go(AppRoutes.account);
    }
  }
}
