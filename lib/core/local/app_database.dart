import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

typedef DatabaseMigration = Future<void> Function(DatabaseExecutor database);

abstract final class AppDatabaseTables {
  static const String appSession = 'app_session';
  static const String users = 'users';
  static const String menuCategories = 'menu_categories';
  static const String menuProducts = 'menu_products';
  static const String cartItems = 'cart_items';
  static const String orders = 'orders';
  static const String orderItems = 'order_items';
}

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static const int currentVersion = 3;
  static const String _databaseName = 'food_please.db';

  final Map<int, DatabaseMigration> _migrations = <int, DatabaseMigration>{
    1: _createV1,
    2: _createV2,
    3: _createV3,
  };

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final String databasePath;
    if (kIsWeb) {
      databasePath = _databaseName;
    } else {
      final String databasesPath = await getDatabasesPath();
      databasePath = path.join(databasesPath, _databaseName);
    }

    _database = await openDatabase(
      databasePath,
      version: currentVersion,
      onConfigure: (Database database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (Database database, int version) async {
        await _runMigrations(database, fromVersion: 0, toVersion: version);
      },
      onUpgrade: (Database database, int oldVersion, int newVersion) async {
        await _runMigrations(
          database,
          fromVersion: oldVersion,
          toVersion: newVersion,
        );
      },
    );

    return _database!;
  }

  Future<void> _runMigrations(
    DatabaseExecutor database, {
    required int fromVersion,
    required int toVersion,
  }) async {
    for (int version = fromVersion + 1; version <= toVersion; version++) {
      final DatabaseMigration? migration = _migrations[version];
      if (migration != null) {
        await migration(database);
      }
    }
  }

  static Future<void> _createV1(DatabaseExecutor database) async {
    await database.execute('''
      CREATE TABLE ${AppDatabaseTables.users} (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL UNIQUE,
        name TEXT,
        phone TEXT,
        address TEXT,
        updated_at TEXT NOT NULL
      )
    ''');

    await database.execute('''
      CREATE TABLE ${AppDatabaseTables.appSession} (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        user_id TEXT NOT NULL,
        email TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES ${AppDatabaseTables.users}(id)
          ON DELETE CASCADE
      )
    ''');

    await database.execute('''
      CREATE TABLE ${AppDatabaseTables.menuCategories} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT,
        cached_at TEXT NOT NULL
      )
    ''');

    await database.execute('''
      CREATE TABLE ${AppDatabaseTables.menuProducts} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        price REAL NOT NULL,
        category_id TEXT NOT NULL,
        category_name TEXT NOT NULL,
        image_url TEXT NOT NULL,
        available INTEGER NOT NULL DEFAULT 1,
        cached_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES ${AppDatabaseTables.menuCategories}(id)
          ON DELETE RESTRICT
      )
    ''');

    await database.execute('''
      CREATE TABLE ${AppDatabaseTables.cartItems} (
        product_id TEXT PRIMARY KEY,
        product_name TEXT NOT NULL,
        description TEXT NOT NULL,
        unit_price REAL NOT NULL,
        category_id TEXT NOT NULL,
        category_name TEXT NOT NULL,
        image_url TEXT NOT NULL,
        available INTEGER NOT NULL DEFAULT 1,
        quantity INTEGER NOT NULL CHECK (quantity > 0),
        added_at TEXT NOT NULL
      )
    ''');

    await database.execute('''
      CREATE TABLE ${AppDatabaseTables.orders} (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        total REAL NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        delivery_address TEXT,
        notes TEXT,
        synced_at TEXT
      )
    ''');

    await database.execute('''
      CREATE TABLE ${AppDatabaseTables.orderItems} (
        order_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        unit_price REAL NOT NULL,
        quantity INTEGER NOT NULL CHECK (quantity > 0),
        PRIMARY KEY (order_id, product_id),
        FOREIGN KEY (order_id) REFERENCES ${AppDatabaseTables.orders}(id)
          ON DELETE CASCADE
      )
    ''');

    await database.execute(
      'CREATE INDEX idx_menu_products_category ON '
      '${AppDatabaseTables.menuProducts}(category_id)',
    );
    await database.execute(
      'CREATE INDEX idx_orders_user_created ON '
      '${AppDatabaseTables.orders}(user_id, created_at DESC)',
    );
  }

  static Future<void> _createV2(DatabaseExecutor database) async {
    await database.execute(
      'ALTER TABLE ${AppDatabaseTables.appSession} '
      'ADD COLUMN access_token TEXT',
    );
  }

  static Future<void> _createV3(DatabaseExecutor database) async {
    await database.delete(AppDatabaseTables.orderItems);
    await database.delete(AppDatabaseTables.orders);
    await database.delete(AppDatabaseTables.cartItems);
    await database.delete(AppDatabaseTables.menuProducts);
    await database.delete(AppDatabaseTables.menuCategories);
  }
}
