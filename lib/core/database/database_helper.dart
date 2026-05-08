// Ubicación: lib/core/database/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Patrón Singleton
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kinetic_pos_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Incrementa la versión si en el futuro necesitas agregar más tablas
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNull = 'TEXT';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

    // Tabla de Productos (Inventario)
    await db.execute('''
      CREATE TABLE products (
        id $idType,
        name $textType,
        sku $textTypeNull,
        category $textType,
        price $realType,
        stock $intType,
        image_path $textTypeNull
      )
    ''');

    // 1. NUEVA TABLA: Categorías
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');
    // 2. Insertar categorías por defecto
    final defaultCategories = ['Comida', 'Bebidas', 'Postres', 'Otros'];
    for (String cat in defaultCategories) {
      await db.insert('categories', {'name': cat});
    }

    // Tabla de Ventas (Auditoría e Historial)
    await db.execute('''
      CREATE TABLE sales (
        id $idType,
        total $realType,
        payment_method $textType,
        user_id $textTypeNull,
        created_at $textType
      )
    ''');

    // Tabla de Detalle de Ventas (Qué productos se vendieron en cada transacción)
    await db.execute('''
      CREATE TABLE sale_items (
        id $idType,
        sale_id $intType,
        product_id $intType,
        quantity $intType,
        unit_price $realType,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');


   // 1. NUEVA TABLA: Usuarios
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');

    // 2. Insertar el usuario administrador por defecto
    await db.insert('users', {
      'username': 'admin',
      'password': '1234', // En un sistema real en la nube, esto iría encriptado
      'role': 'Administrador'
    });

  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
