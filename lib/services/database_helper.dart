import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Bật tính năng kiểm tra khóa ngoại (Foreign Keys) trong SQLite
    await db.execute('PRAGMA foreign_keys = ON');

    // 1. Nhóm Quản lý phân quyền & Nhân sự
    await db.execute('''
      CREATE TABLE Role (
        RoleID INTEGER PRIMARY KEY AUTOINCREMENT,
        RoleName TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE Account (
        AccountID INTEGER PRIMARY KEY AUTOINCREMENT,
        Username TEXT NOT NULL UNIQUE,
        Password TEXT NOT NULL,
        RoleID INTEGER,
        Status INTEGER DEFAULT 1,
        FOREIGN KEY (RoleID) REFERENCES Role (RoleID) ON DELETE SET NULL
      )
    ''');

    // 2. Nhóm Hệ thống cửa hàng & Đối tác
    await db.execute('''
      CREATE TABLE Store (
        StoreID INTEGER PRIMARY KEY AUTOINCREMENT,
        StoreName TEXT NOT NULL,
        Address TEXT,
        Phone TEXT,
        Status TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE Employee (
        EmployeeID INTEGER PRIMARY KEY AUTOINCREMENT,
        FullName TEXT NOT NULL,
        DOB TEXT,
        Gender INTEGER,
        Address TEXT,
        Phone TEXT,
        Salary REAL,
        StoreID INTEGER,
        AccountID INTEGER,
        FOREIGN KEY (StoreID) REFERENCES Store (StoreID) ON DELETE SET NULL,
        FOREIGN KEY (AccountID) REFERENCES Account (AccountID) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE Supplier (
        SupplierID INTEGER PRIMARY KEY AUTOINCREMENT,
        SupplierName TEXT NOT NULL,
        Address TEXT,
        Email TEXT,
        Phone TEXT
      )
    ''');

    // 3. Nhóm Sản phẩm & Tồn kho
    await db.execute('''
      CREATE TABLE Category (
        CategoryID INTEGER PRIMARY KEY AUTOINCREMENT,
        CategoryName TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE Product (
        ProductID INTEGER PRIMARY KEY AUTOINCREMENT,
        ProductName TEXT NOT NULL,
        CategoryID INTEGER,
        SupplierID INTEGER,
        Description TEXT,
        FOREIGN KEY (CategoryID) REFERENCES Category (CategoryID) ON DELETE SET NULL,
        FOREIGN KEY (SupplierID) REFERENCES Supplier (SupplierID) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE Inventory (
        InventoryID INTEGER PRIMARY KEY AUTOINCREMENT,
        StoreID INTEGER,
        ProductID INTEGER,
        Quantity INTEGER DEFAULT 0,
        SalePrice REAL DEFAULT 0.0,
        ExpiredDate TEXT,
        FOREIGN KEY (StoreID) REFERENCES Store (StoreID) ON DELETE CASCADE,
        FOREIGN KEY (ProductID) REFERENCES Product (ProductID) ON DELETE CASCADE
      )
    ''');

    // 4. Nhóm Nhập hàng (Purchase Order)
    await db.execute('''
      CREATE TABLE PurchaseOrder (
        PurchaseOrderID INTEGER PRIMARY KEY AUTOINCREMENT,
        SupplierID INTEGER,
        EmployeeID INTEGER,
        OrderDate TEXT,
        FOREIGN KEY (SupplierID) REFERENCES Supplier (SupplierID) ON DELETE SET NULL,
        FOREIGN KEY (EmployeeID) REFERENCES Employee (EmployeeID) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE PurchaseOrderDetail (
        PurchaseOrderDetailID INTEGER PRIMARY KEY AUTOINCREMENT,
        PurchaseOrderID INTEGER,
        ProductID INTEGER,
        Quantity INTEGER NOT NULL,
        ImportPrice REAL NOT NULL,
        ExpiredDate TEXT,
        FOREIGN KEY (PurchaseOrderID) REFERENCES PurchaseOrder (PurchaseOrderID) ON DELETE CASCADE,
        FOREIGN KEY (ProductID) REFERENCES Product (ProductID) ON DELETE RESTRICT
      )
    ''');

    // 5. Nhóm Điều chuyển hàng (Transfer Order)
    await db.execute('''
      CREATE TABLE TransferOrder (
        TransferID INTEGER PRIMARY KEY AUTOINCREMENT,
        FromStoreID INTEGER,
        ToStoreID INTEGER,
        ProductID INTEGER,
        Quantity INTEGER NOT NULL,
        TransferDate TEXT,
        FOREIGN KEY (FromStoreID) REFERENCES Store (StoreID) ON DELETE RESTRICT,
        FOREIGN KEY (ToStoreID) REFERENCES Store (StoreID) ON DELETE RESTRICT,
        FOREIGN KEY (ProductID) REFERENCES Product (ProductID) ON DELETE RESTRICT
      )
    ''');

    // 6. Nhóm Khách hàng & Khuyến mãi & Bán hàng (POS)
    await db.execute('''
      CREATE TABLE Customer (
        CustomerID INTEGER PRIMARY KEY AUTOINCREMENT,
        FullName TEXT NOT NULL,
        Phone TEXT,
        Email TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE Promotion (
        PromotionID INTEGER PRIMARY KEY AUTOINCREMENT,
        PromotionName TEXT NOT NULL,
        DiscountPercent REAL DEFAULT 0.0,
        StartDate TEXT,
        EndDate TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE Invoice (
        InvoiceID INTEGER PRIMARY KEY AUTOINCREMENT,
        StoreID INTEGER,
        CustomerID INTEGER,
        EmployeeID INTEGER,
        InvoiceDate TEXT,
        TotalAmount REAL DEFAULT 0.0,
        FOREIGN KEY (StoreID) REFERENCES Store (StoreID) ON DELETE SET NULL,
        FOREIGN KEY (CustomerID) REFERENCES Customer (CustomerID) ON DELETE SET NULL,
        FOREIGN KEY (EmployeeID) REFERENCES Employee (EmployeeID) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE InvoiceDetail (
        InvoiceDetailID INTEGER PRIMARY KEY AUTOINCREMENT,
        InvoiceID INTEGER,
        ProductID INTEGER,
        PromotionID INTEGER,
        Quantity INTEGER NOT NULL,
        UnitPrice REAL NOT NULL,
        DiscountAmount REAL DEFAULT 0.0,
        FOREIGN KEY (InvoiceID) REFERENCES Invoice (InvoiceID) ON DELETE CASCADE,
        FOREIGN KEY (ProductID) REFERENCES Product (ProductID) ON DELETE RESTRICT,
        FOREIGN KEY (PromotionID) REFERENCES Promotion (PromotionID) ON DELETE SET NULL
      )
    ''');
  }
}