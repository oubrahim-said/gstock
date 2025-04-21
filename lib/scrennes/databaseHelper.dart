import "package:sqflite/sqflite.dart";
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'gstock.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Admin table
    await db.execute('''
      CREATE TABLE admin(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL
      )
    ''');

    // Components table
    await db.execute('''
      CREATE TABLE components(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category_id INTEGER,
        quantity INTEGER NOT NULL,
        acquisition_date TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // Members table
    await db.execute('''
      CREATE TABLE members(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        phone1 TEXT NOT NULL,
        phone2 TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Borrowings table
    await db.execute('''
      CREATE TABLE borrowings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        component_id INTEGER,
        member_id INTEGER,
        quantity INTEGER NOT NULL,
        borrow_date TEXT DEFAULT CURRENT_TIMESTAMP,
        return_date TEXT,
        status TEXT CHECK(status IN ('pending', 'returned', 'damaged', 'severely_damaged')),
        FOREIGN KEY (component_id) REFERENCES components (id),
        FOREIGN KEY (member_id) REFERENCES members (id)
      )
    ''');

    // Insert default admin
    await db.insert('admin', {
      'username': 'admin',
      'password': 'admin123' // In production, this should be hashed
    });
  }

  // Admin methods
  Future<bool> authenticateAdmin(String username, String password) async {
    final db = await database;
    final result = await db.query(
      'admin',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    return result.isNotEmpty;
  }

  // Category methods
  Future<int> insertCategory(String name) async {
    final db = await database;
    return await db.insert('categories', {'name': name});
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return await db.query('categories');
  }

  // Component methods
  Future<int> insertComponent(Map<String, dynamic> component) async {
    final db = await database;
    return await db.insert('components', component);
  }

  Future<List<Map<String, dynamic>>> getComponents() async {
    final db = await database;
    return await db.query('components');
  }

  Future<int> updateComponentQuantity(int id, int quantity) async {
    final db = await database;
    return await db.update(
      'components',
      {'quantity': quantity},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Member methods
  Future<int> insertMember(Map<String, dynamic> member) async {
    final db = await database;
    return await db.insert('members', member);
  }

  Future<List<Map<String, dynamic>>> getMembers() async {
    final db = await database;
    return await db.query('members');
  }

  // Borrowing methods
  Future<int> insertBorrowing(Map<String, dynamic> borrowing) async {
    final db = await database;
    return await db.insert('borrowings', borrowing);
  }

  Future<List<Map<String, dynamic>>> getPendingBorrowings() async {
    final db = await database;
    return await db.query(
      'borrowings',
      where: 'status = ?',
      whereArgs: ['pending'],
    );
  }

  Future<int> updateBorrowingStatus(int id, String status) async {
    final db = await database;
    return await db.update(
      'borrowings',
      {
        'status': status,
        'return_date': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
