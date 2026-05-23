import 'dart:async';

import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../../features/account/data/repositories/account_remote_repository.dart';
import '../../features/account/presentation/controllers/profile_controller.dart';
import '../../features/account/domain/usecases/account_use_cases.dart';
import '../../features/auth/data/local/auth_local_data_source.dart';
import '../../features/auth/data/repositories/auth_remote_repository.dart';
import '../../features/auth/data/session_storage.dart';
import '../../features/auth/domain/usecases/auth_use_cases.dart';
import '../../features/auth/presentation/controllers/session_controller.dart';
import '../../features/cart/data/repositories/cart_local_repository.dart';
import '../../features/cart/domain/usecases/cart_use_cases.dart';
import '../../features/cart/presentation/controllers/cart_controller.dart';
import '../../features/menu/data/repositories/menu_remote_repository.dart';
import '../../features/menu/domain/usecases/menu_use_cases.dart';
import '../../features/orders/data/repositories/orders_remote_repository.dart';
import '../../features/orders/domain/usecases/orders_use_cases.dart';
import '../../features/orders/presentation/controllers/orders_controller.dart';
import '../config/app_environment.dart';
import '../../features/cart/data/local/cart_local_data_source.dart';
import '../../features/menu/data/local/menu_local_data_source.dart';
import '../../features/orders/data/local/orders_local_data_source.dart';
import '../local/app_database.dart';
import '../network/api_client.dart';

abstract final class AppServices {
  static bool _initialized = false;
  static bool _wasAuthenticated = false;

  static final AppDatabase database = AppDatabase.instance;
  static final AuthLocalDataSource authLocalDataSource = AuthLocalDataSource(
    database: database,
  );
  static final MenuLocalDataSource menuLocalDataSource = MenuLocalDataSource(
    database: database,
  );
  static final CartLocalDataSource cartLocalDataSource = CartLocalDataSource(
    database: database,
  );
  static final OrdersLocalDataSource ordersLocalDataSource =
      OrdersLocalDataSource(database: database);
  static final SessionStorage sessionStorage = SessionStorage(
    localDataSource: authLocalDataSource,
  );
  static final ApiClient apiClient = ApiClient(
    environment: AppEnvironmentX.current,
    tokenProvider: authLocalDataSource.readAccessToken,
  );

  static final AuthRemoteRepository authRepository = AuthRemoteRepository(
    apiClient: apiClient,
    storage: sessionStorage,
  );
  static final MenuRemoteRepository menuRepository = MenuRemoteRepository(
    apiClient: apiClient,
    localDataSource: menuLocalDataSource,
  );
  static final CartLocalRepository cartRepository = CartLocalRepository(
    localDataSource: cartLocalDataSource,
  );
  static final OrdersRemoteRepository ordersRepository = OrdersRemoteRepository(
    apiClient: apiClient,
    localDataSource: ordersLocalDataSource,
  );
  static final AccountRemoteRepository accountRepository =
      AccountRemoteRepository(
        apiClient: apiClient,
        authLocalDataSource: authLocalDataSource,
        sessionStorage: sessionStorage,
      );

  static final RestoreSessionUseCase restoreSessionUseCase =
      RestoreSessionUseCase(authRepository);
  static final SignInUseCase signInUseCase = SignInUseCase(authRepository);
  static final SignOutUseCase signOutUseCase = SignOutUseCase(authRepository);
  static final GetMenuCategoriesUseCase getMenuCategoriesUseCase =
      GetMenuCategoriesUseCase(menuRepository);
  static final GetMenuUseCase getMenuUseCase = GetMenuUseCase(menuRepository);
  static final FilterMenuByCategoryUseCase filterMenuByCategoryUseCase =
      FilterMenuByCategoryUseCase(menuRepository);
  static final GetCartItemsUseCase getCartItemsUseCase = GetCartItemsUseCase(
    cartRepository,
  );
  static final AddProductToCartUseCase addProductToCartUseCase =
      AddProductToCartUseCase(cartRepository);
  static final UpdateCartItemQuantityUseCase updateCartItemQuantityUseCase =
      UpdateCartItemQuantityUseCase(cartRepository);
  static final RemoveCartItemUseCase removeCartItemUseCase =
      RemoveCartItemUseCase(cartRepository);
  static final ClearCartUseCase clearCartUseCase = ClearCartUseCase(
    cartRepository,
  );
  static final CreateOrderUseCase createOrderUseCase = CreateOrderUseCase(
    ordersRepository,
  );
  static final GetOrdersUseCase getOrdersUseCase = GetOrdersUseCase(
    ordersRepository,
  );
  static final GetOrderDetailUseCase getOrderDetailUseCase =
      GetOrderDetailUseCase(ordersRepository);
  static final UpdateOrderUseCase updateOrderUseCase = UpdateOrderUseCase(
    ordersRepository,
  );
  static final CancelOrderUseCase cancelOrderUseCase = CancelOrderUseCase(
    ordersRepository,
  );
  static final GetProfileUseCase getProfileUseCase = GetProfileUseCase(
    accountRepository,
  );
  static final UpdateProfileUseCase updateProfileUseCase = UpdateProfileUseCase(
    accountRepository,
  );
  static final DeleteAccountUseCase deleteAccountUseCase = DeleteAccountUseCase(
    accountRepository,
  );
  static final SessionController sessionController = SessionController(
    signInUseCase: signInUseCase,
    signOutUseCase: signOutUseCase,
    restoreSessionUseCase: restoreSessionUseCase,
  );
  static final CartController cartController = CartController(
    getCartItemsUseCase: getCartItemsUseCase,
    addProductToCartUseCase: addProductToCartUseCase,
    updateCartItemQuantityUseCase: updateCartItemQuantityUseCase,
    removeCartItemUseCase: removeCartItemUseCase,
    clearCartUseCase: clearCartUseCase,
    createOrderUseCase: createOrderUseCase,
  );
  static final OrdersController ordersController = OrdersController(
    getOrdersUseCase: getOrdersUseCase,
    getOrderDetailUseCase: getOrderDetailUseCase,
    updateOrderUseCase: updateOrderUseCase,
    cancelOrderUseCase: cancelOrderUseCase,
  );
  static final ProfileController profileController = ProfileController(
    getProfileUseCase: getProfileUseCase,
    updateProfileUseCase: updateProfileUseCase,
    deleteAccountUseCase: deleteAccountUseCase,
    sessionController: sessionController,
  );
  static late final GoRouter router;

  /// Inicializa servicios globales y resuelve la sesion persistida.
  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await database.database;
    await sessionController.restore();
    _wasAuthenticated = sessionController.isAuthenticated;
    profileController.syncFromSession(sessionController.currentUser);
    if (_wasAuthenticated) {
      await cartController.loadCart();
    }
    sessionController.addListener(_handleSessionChanged);
    router = buildRouter(sessionController);
    _initialized = true;
  }

  static void _handleSessionChanged() {
    final bool isAuthenticated = sessionController.isAuthenticated;

    if (!isAuthenticated) {
      _wasAuthenticated = false;
      cartController.reset();
      ordersController.reset();
      profileController.reset();
      return;
    }

    profileController.syncFromSession(sessionController.currentUser);

    if (!_wasAuthenticated) {
      _wasAuthenticated = true;
      unawaited(cartController.loadCart());
      ordersController.reset();
    }
  }
}
