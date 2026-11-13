import 'package:flutter_bloc/flutter_bloc.dart';
import 'api_client.dart';
import '../models/api_product.dart';
import '../models/cart_line.dart';
import '../providers/local_store.dart';

typedef Json = Map<String, dynamic>;

List<Json> asJsonList(dynamic value) =>
    (value as List<dynamic>).map((v) => Map<String, dynamic>.from(v as Map)).toList();

class ShopState {
  final bool busy;
  final bool catalogLoading;
  final String? catalogError;
  final Json? user;
  final List<Json> products;
  final List<Json> orders;
  final List<Json> notifications;
  final List<Json> couriers;
  final Json stats;
  final Set<int> favorites;
  final List<CartLine> cart;
  final String? notice;
  final bool error;
  final int tab;

  const ShopState({
    this.busy = false,
    this.catalogLoading = false,
    this.catalogError,
    this.user,
    this.products = const [],
    this.orders = const [],
    this.notifications = const [],
    this.couriers = const [],
    this.stats = const {},
    this.favorites = const {},
    this.cart = const [],
    this.notice,
    this.error = false,
    this.tab = 0,
  });

  ShopState copyWith({
    bool? busy,
    bool? catalogLoading,
    String? catalogError,
    bool clearCatalogError = false,
    Json? user,
    bool clearUser = false,
    List<Json>? products,
    List<Json>? orders,
    List<Json>? notifications,
    List<Json>? couriers,
    Json? stats,
    Set<int>? favorites,
    List<CartLine>? cart,
    String? notice,
    bool clearNotice = false,
    bool? error,
    int? tab,
  }) {
    return ShopState(
      busy: busy ?? this.busy,
      catalogLoading: catalogLoading ?? this.catalogLoading,
      catalogError: clearCatalogError ? null : (catalogError ?? this.catalogError),
      user: clearUser ? null : (user ?? this.user),
      products: products ?? this.products,
      orders: orders ?? this.orders,
      notifications: notifications ?? this.notifications,
      couriers: couriers ?? this.couriers,
      stats: stats ?? this.stats,
      favorites: favorites ?? this.favorites,
      cart: cart ?? this.cart,
      notice: clearNotice ? null : (notice ?? this.notice),
      error: error ?? this.error,
      tab: tab ?? this.tab,
    );
  }
}

class ShopCubit extends Cubit<ShopState> {
  final ApiClient api;
  final LocalStore localStore;

  ShopCubit(this.api, this.localStore)
      : super(ShopState(
          cart: localStore.cart,
          favorites: localStore.favorites,
        ));

  List<Json> _parseProducts(dynamic data) {
    final maps = asJsonList(data);
    return maps.map((json) {
      final normalized = ApiProduct.normalize(json);
      ApiProduct.fromJson(normalized);
      return normalized;
    }).toList();
  }

  Future<void> initialize() async {
    emit(state.copyWith(catalogLoading: true, clearCatalogError: true));
    try {
      final products = _parseProducts(await api.get('/products'));
      emit(state.copyWith(
        products: products,
        catalogLoading: false,
        clearCatalogError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        catalogLoading: false,
        catalogError: e.toString(),
        error: true,
      ));
    }
  }

  Future<void> retryCatalog() => initialize();

  Future<void> run(Future<void> Function() action, {String? success}) async {
    emit(state.copyWith(busy: true, clearNotice: true));
    try {
      await action();
      emit(state.copyWith(busy: false, notice: success, clearNotice: success == null, error: false));
    } catch (e) {
      emit(state.copyWith(busy: false, notice: e.toString(), error: true));
    }
  }

  void clearNotice() => emit(state.copyWith(clearNotice: true));
  void selectTab(int value) => emit(state.copyWith(tab: value));

  Future<void> login(String email, String password, {bool register = false}) =>
      run(() async {
        final result = Map<String, dynamic>.from(await api.post(
            register ? '/auth/register' : '/auth/login',
            {'email': email, 'password': password}));
        api.token = result['token'] as String;
        emit(state.copyWith(user: Map<String, dynamic>.from(result['user'] as Map), tab: 0));
        await _refreshAll();
      }, success: 'Welcome to SneakerHub!');

  Future<void> logout() => run(() async {
        try {
          await api.post('/auth/logout');
        } finally {
          api.token = null;
          await localStore.clearShoppingData();
          emit(ShopState(products: state.products));
        }
      }, success: null);

  Future<void> _refreshAll() async {
    final products = _parseProducts(await api.get('/products'));
    if (api.token == null) {
      emit(state.copyWith(products: products));
      return;
    }
    final user = Map<String, dynamic>.from(await api.get('/me'));
    final orders = asJsonList(await api.get('/orders'));
    final notifications = asJsonList(await api.get('/notifications'));
    final role = user['role'];
    Set<int> favorites = {};
    List<Json> couriers = [];
    Json stats = {};
    if (role == 'customer') {
      favorites = (await api.get('/favorites') as List<dynamic>).map((e) => e as int).toSet();
    } else if (role == 'admin') {
      couriers = asJsonList(await api.get('/admin/couriers'));
      stats = Map<String, dynamic>.from(await api.get('/admin/stats'));
    }
    if (role == 'customer') {
      await localStore.saveFavorites(favorites);
    }
    emit(state.copyWith(user: user, products: products, orders: orders,
        notifications: notifications, favorites: favorites, couriers: couriers, stats: stats,
        clearCatalogError: true));
  }

  Future<void> refresh() => run(_refreshAll, success: 'Updated');

  Json? product(int id) {
    for (final p in state.products) {
      if (p['id'] == id) return p;
    }
    return null;
  }

  void addToCart(int productId, int size) {
    final list = [...state.cart];
    final index = list.indexWhere((v) => v.productId == productId && v.size == size);
    if (index < 0) {
      list.add(CartLine(productId, size, 1));
    } else {
      list[index] = list[index].withQuantity(list[index].quantity + 1);
    }
    emit(state.copyWith(cart: list, notice: 'Added to cart', error: false));
    localStore.saveCart(list);
  }

  void changeQuantity(CartLine line, int quantity) {
    final list = [...state.cart];
    final index = list.indexWhere((v) => v.productId == line.productId && v.size == line.size);
    if (index < 0) return;
    if (quantity <= 0) {
      list.removeAt(index);
    } else {
      list[index] = list[index].withQuantity(quantity);
    }
    emit(state.copyWith(cart: list));
    localStore.saveCart(list);
  }

  Future<void> toggleFavorite(int productId) => run(() async {
        await api.post('/favorites/$productId');
        final favorites = (await api.get('/favorites') as List<dynamic>).map((e) => e as int).toSet();
        emit(state.copyWith(favorites: favorites));
        await localStore.saveFavorites(favorites);
      }, success: 'Favorites updated');

  Future<void> checkout(String address, String promo, bool usePoints) => run(() async {
        await api.post('/orders', {
          'address': address,
          'promo_code': promo,
          'use_points': usePoints,
          'items': state.cart.map((line) => {
            'product_id': line.productId,
            'size': line.size,
            'quantity': line.quantity,
          }).toList(),
        });
        emit(state.copyWith(cart: [], tab: 3));
        await localStore.saveCart([]);
        await _refreshAll();
      }, success: 'Order placed!');

  Future<void> adminStatus(int orderId, String status, {int? courierId}) =>
      run(() async {
        await api.patch('/admin/orders/$orderId', {
          'status': status,
          if (courierId != null) 'courier_id': courierId,
        });
        await _refreshAll();
      }, success: 'Order updated');

  Future<void> courierArrive(int orderId) => run(() async {
        await api.post('/courier/orders/$orderId/arrive');
        await _refreshAll();
      }, success: 'Customer can now see their one-time delivery code');

  Future<void> courierDeliver(int orderId, String code) => run(() async {
        await api.post('/courier/orders/$orderId/deliver', {'code': code});
        await _refreshAll();
      }, success: 'Delivery confirmed!');

  Future<String> customerCode(int orderId) async {
    final value = Map<String, dynamic>.from(await api.get('/orders/$orderId/delivery-code'));
    return value['code'] as String;
  }

  Future<void> restock(int productId, int size, int quantity) => run(() async {
        await api.post('/admin/supplies', {
          'product_id': productId, 'size': size, 'quantity': quantity,
        });
        await _refreshAll();
      }, success: 'Supply received');

  Future<void> changeDiscount(int productId, int percent) => run(() async {
        await api.patch('/admin/products/$productId/discount', {'percent': percent});
        await _refreshAll();
      }, success: 'Discount updated; watchers notified in-app');

  Future<List<Json>> reviews(int productId) async =>
      asJsonList(await api.get('/products/$productId/reviews'));

  Future<void> submitReview(int productId, int rating, String comment) => run(() async {
        await api.post('/products/$productId/reviews', {'rating': rating, 'comment': comment});
        await _refreshAll();
      }, success: 'Thank you for your review!');

  Future<void> markRead(int notificationId) => run(() async {
        await api.post('/notifications/$notificationId/read');
        await _refreshAll();
      }, success: null);

  @override
  Future<void> close() {
    api.dispose();
    return super.close();
  }
}
