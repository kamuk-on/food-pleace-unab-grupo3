import 'package:sqflite/sqflite.dart';

import '../../../../core/local/app_database.dart';
import '../dto/order_dto.dart';
import '../dto/order_item_dto.dart';

class OrdersLocalDataSource {
  OrdersLocalDataSource({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<OrderDto>> readOrders({String? userId}) async {
    final database = await _database.database;
    final List<Map<String, Object?>> rows = await database.query(
      AppDatabaseTables.orders,
      where: userId == null ? null : 'user_id = ?',
      whereArgs: userId == null ? null : <Object?>[userId],
      orderBy: 'created_at DESC',
    );

    final List<OrderDto> orders = <OrderDto>[];
    for (final Map<String, Object?> row in rows) {
      orders.add(await _mapOrder(database, row));
    }

    return orders;
  }

  Future<OrderDto?> readOrderById(String orderId) async {
    final database = await _database.database;
    final List<Map<String, Object?>> rows = await database.query(
      AppDatabaseTables.orders,
      where: 'id = ?',
      whereArgs: <Object?>[orderId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _mapOrder(database, rows.first);
  }

  Future<void> saveOrders(List<OrderDto> orders) async {
    final database = await _database.database;
    await database.transaction((transaction) async {
      await transaction.delete(AppDatabaseTables.orderItems);
      await transaction.delete(AppDatabaseTables.orders);

      for (final OrderDto order in orders) {
        await _writeOrder(transaction, order);
      }
    });
  }

  Future<void> upsertOrder(OrderDto order) async {
    final database = await _database.database;
    await database.transaction((transaction) async {
      await transaction.delete(
        AppDatabaseTables.orderItems,
        where: 'order_id = ?',
        whereArgs: <Object?>[order.id],
      );
      await _writeOrder(transaction, order);
    });
  }

  Future<void> clear() async {
    final database = await _database.database;
    await database.transaction((transaction) async {
      await transaction.delete(AppDatabaseTables.orderItems);
      await transaction.delete(AppDatabaseTables.orders);
    });
  }

  Future<void> _writeOrder(Transaction transaction, OrderDto order) async {
    await transaction.insert(AppDatabaseTables.orders, <String, Object?>{
      'id': order.id,
      'user_id': order.userId,
      'total': order.total,
      'status': order.status,
      'created_at': order.createdAt.toIso8601String(),
      'delivery_address': order.deliveryAddress,
      'notes': order.notes,
      'synced_at': null,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    final Batch batch = transaction.batch();
    for (final OrderItemDto item in order.items) {
      batch.insert(AppDatabaseTables.orderItems, <String, Object?>{
        'order_id': order.id,
        'product_id': item.productId,
        'product_name': item.productName,
        'unit_price': item.unitPrice,
        'quantity': item.quantity,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<OrderDto> _mapOrder(
    Database database,
    Map<String, Object?> row,
  ) async {
    final List<Map<String, Object?>> itemRows = await database.query(
      AppDatabaseTables.orderItems,
      where: 'order_id = ?',
      whereArgs: <Object?>[row['id']],
      orderBy: 'product_name ASC',
    );

    return OrderDto(
      id: row['id']! as String,
      userId: row['user_id']! as String,
      items: itemRows.map(_mapOrderItem).toList(growable: false),
      total: (row['total']! as num).toDouble(),
      status: row['status']! as String,
      createdAt: DateTime.parse(row['created_at']! as String),
      deliveryAddress: row['delivery_address'] as String?,
      notes: row['notes'] as String?,
    );
  }

  OrderItemDto _mapOrderItem(Map<String, Object?> row) {
    return OrderItemDto(
      productId: row['product_id']! as String,
      productName: row['product_name']! as String,
      unitPrice: (row['unit_price']! as num).toDouble(),
      quantity: row['quantity']! as int,
    );
  }
}
