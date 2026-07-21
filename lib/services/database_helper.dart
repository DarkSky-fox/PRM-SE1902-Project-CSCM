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
      version: 11,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion >= 10) {
      if (oldVersion < 11) {
        await db.execute('''
          ALTER TABLE TransferOrder
          ADD COLUMN RequestedByEmployeeID INTEGER
          REFERENCES Employee(EmployeeID) ON DELETE SET NULL
        ''');
        await db.execute('''
          ALTER TABLE TransferOrder
          ADD COLUMN Status TEXT NOT NULL DEFAULT 'Approved'
        ''');
        await db.execute('''
          ALTER TABLE TransferOrder
          ADD COLUMN ReviewedByEmployeeID INTEGER
          REFERENCES Employee(EmployeeID) ON DELETE SET NULL
        ''');
        await db.execute('''
          ALTER TABLE TransferOrder
          ADD COLUMN ReviewedAt TEXT
        ''');
      }
      return;
    }

    await db.execute('DROP TABLE IF EXISTS WorkSchedule');
    await db.execute('DROP TABLE IF EXISTS InvoiceDetail');
    await db.execute('DROP TABLE IF EXISTS Invoice');
    await db.execute('DROP TABLE IF EXISTS Promotion');
    await db.execute('DROP TABLE IF EXISTS Customer');
    await db.execute('DROP TABLE IF EXISTS TransferOrder');
    await db.execute('DROP TABLE IF EXISTS PurchaseOrderDetail');
    await db.execute('DROP TABLE IF EXISTS PurchaseOrder');
    await db.execute('DROP TABLE IF EXISTS Inventory');
    await db.execute('DROP TABLE IF EXISTS Product');
    await db.execute('DROP TABLE IF EXISTS Category');
    await db.execute('DROP TABLE IF EXISTS Supplier');
    await db.execute('DROP TABLE IF EXISTS Employee');
    await db.execute('DROP TABLE IF EXISTS Store');
    await db.execute('DROP TABLE IF EXISTS Account');
    await db.execute('DROP TABLE IF EXISTS Role');

    await _createDB(db, newVersion);
  }

  Future _createDB(Database db, int version) async {
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
        OpenTime TEXT,
        CloseTime TEXT,
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
        ImageUrl TEXT,
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
        RequestedByEmployeeID INTEGER,
        Status TEXT NOT NULL DEFAULT 'Pending',
        ReviewedByEmployeeID INTEGER,
        ReviewedAt TEXT,
        FOREIGN KEY (FromStoreID) REFERENCES Store (StoreID) ON DELETE RESTRICT,
        FOREIGN KEY (ToStoreID) REFERENCES Store (StoreID) ON DELETE RESTRICT,
        FOREIGN KEY (ProductID) REFERENCES Product (ProductID) ON DELETE RESTRICT,
        FOREIGN KEY (RequestedByEmployeeID) REFERENCES Employee (EmployeeID) ON DELETE SET NULL,
        FOREIGN KEY (ReviewedByEmployeeID) REFERENCES Employee (EmployeeID) ON DELETE SET NULL
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

    // 7. Nhóm Lịch làm việc (Work Schedule)
    await db.execute('''
      CREATE TABLE WorkSchedule (
        ScheduleID INTEGER PRIMARY KEY AUTOINCREMENT,
        EmployeeID INTEGER,
        WorkDate TEXT,
        Shift TEXT,
        FOREIGN KEY (EmployeeID) REFERENCES Employee (EmployeeID) ON DELETE CASCADE
      )
    ''');

    // --- SEED INITIAL DATA ---
    // Roles
    await db.insert('Role', {'RoleName': 'Chủ chuỗi'});
    await db.insert('Role', {'RoleName': 'Cửa hàng trưởng'});
    await db.insert('Role', {'RoleName': 'Nhân viên'});

    // 4 Stores
    await db.insert('Store', {
      'StoreName': 'Store Quận 1',
      'Address': '123 Nguyễn Huệ, Q.1',
      'Phone': '02811112222',
      'OpenTime': '07:00',
      'CloseTime': '22:00',
      'Status': 'Active',
    });
    await db.insert('Store', {
      'StoreName': 'Store Quận 3',
      'Address': '456 Điện Biên Phủ, Q.3',
      'Phone': '02833334444',
      'OpenTime': '07:00',
      'CloseTime': '22:00',
      'Status': 'Active',
    });
    await db.insert('Store', {
      'StoreName': 'Store Bình Thạnh',
      'Address': '789 Điện Biên Phủ, Bình Thạnh',
      'Phone': '02855556666',
      'OpenTime': '06:30',
      'CloseTime': '23:00',
      'Status': 'Active',
    });
    await db.insert('Store', {
      'StoreName': 'Store Phú Nhuận',
      'Address': '101 Phan Xích Long, Phú Nhuận',
      'Phone': '02877778888',
      'OpenTime': '06:30',
      'CloseTime': '23:00',
      'Status': 'Active',
    });

    // Supplier
    await db.insert('Supplier', {
      'SupplierName': 'Nhà Cung Cấp Tổng Hợp',
      'Address': '789 Bình Thạnh',
      'Email': 'supplier@cscm.com',
      'Phone': '0909999888',
    });

    // Customers
    await db.insert('Customer', {
      'FullName': 'Khách Vãng Lai',
      'Phone': '0000000000',
      'Email': 'guest@cscm.com',
    });

    // Promotions
    await db.insert('Promotion', {
      'PromotionName': 'Không giảm giá',
      'DiscountPercent': 0.0,
    });
    await db.insert('Promotion', {
      'PromotionName': 'Giảm giá 10%',
      'DiscountPercent': 10.0,
    });

    // 4 Categories
    await db.insert('Category', {'CategoryName': 'Đồ uống'});
    await db.insert('Category', {'CategoryName': 'Đồ ăn nhanh'});
    await db.insert('Category', {'CategoryName': 'Snack & Bánh kẹo'});
    await db.insert('Category', {'CategoryName': 'Nhu yếu phẩm'});

    // Define 33 products (3 existing + 30 new)
    final List<Map<String, dynamic>> productData = [
      {
        'ProductName': 'Cà phê sữa đá',
        'CategoryID': 1,
        'SupplierID': 1,
        'Description': 'Cà phê sữa truyền thống',
        'ImageUrl':
            'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=300',
        'SalePrice': 25000.0,
      },
      {
        'ProductName': 'Trà đào sả',
        'CategoryID': 1,
        'SupplierID': 1,
        'Description': 'Trà đào thơm mát',
        'ImageUrl':
            'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=300',
        'SalePrice': 30000.0,
      },
      {
        'ProductName': 'Bánh mì pate',
        'CategoryID': 2,
        'SupplierID': 1,
        'Description': 'Bánh mì thịt pate nóng giòn',
        'ImageUrl':
            'https://images.unsplash.com/photo-1626132647523-66f5bf380027?w=300',
        'SalePrice': 20000.0,
      },

      // 30 mặt hàng mới
      // Đồ uống (CategoryID 1)
      {
        'ProductName': 'Pepsi lon 320ml',
        'CategoryID': 1,
        'SupplierID': 1,
        'Description': 'Pepsi giải khát sảng khoái',
        'ImageUrl':
            'https://images.unsplash.com/photo-1629203851122-3726ecdf080e?w=300',
        'SalePrice': 12000.0,
      },
      {
        'ProductName': 'Coca-Cola lon 320ml',
        'CategoryID': 1,
        'SupplierID': 1,
        'Description': 'Coca-Cola hương vị nguyên bản',
        'ImageUrl':
            'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=300',
        'SalePrice': 12000.0,
      },
      {
        'ProductName': 'Nước suối Aquafina 500ml',
        'CategoryID': 1,
        'SupplierID': 1,
        'Description': 'Nước uống tinh khiết',
        'ImageUrl':
            'https://images.unsplash.com/photo-1616169776580-c810d1d9ec34?w=300',
        'SalePrice': 6000.0,
      },
      {
        'ProductName': 'Sữa tươi Vinamilk ít đường',
        'CategoryID': 1,
        'SupplierID': 1,
        'Description': 'Sữa tươi sạch 180ml',
        'ImageUrl':
            'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=300',
        'SalePrice': 9000.0,
      },
      {
        'ProductName': 'Trà sữa truyền thống',
        'CategoryID': 1,
        'SupplierID': 1,
        'Description': 'Trà sữa thơm béo kèm trân châu',
        'ImageUrl':
            'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=300',
        'SalePrice': 35000.0,
      },
      {
        'ProductName': 'Sinh tố bơ sáp',
        'CategoryID': 1,
        'SupplierID': 1,
        'Description': 'Sinh tố bơ béo ngậy hạt chia',
        'ImageUrl':
            'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=300',
        'SalePrice': 40000.0,
      },
      {
        'ProductName': 'Nước cam ép nguyên chất',
        'CategoryID': 1,
        'SupplierID': 1,
        'Description': 'Cam sành ép giàu vitamin C',
        'ImageUrl':
            'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=300',
        'SalePrice': 28000.0,
      },
      {
        'ProductName': 'Trà xanh Oolong C2',
        'CategoryID': 1,
        'SupplierID': 1,
        'Description': 'Trà xanh thanh mát cơ thể',
        'ImageUrl':
            'https://images.unsplash.com/photo-1597481499750-3e6b22637e12?w=300',
        'SalePrice': 10000.0,
      },

      // Đồ ăn nhanh (CategoryID 2)
      {
        'ProductName': 'Bánh bao trứng cút',
        'CategoryID': 2,
        'SupplierID': 1,
        'Description': 'Bánh bao nhân thịt nóng hổi',
        'ImageUrl':
            'https://images.unsplash.com/photo-1614961909013-1e2212a2ca87?w=300',
        'SalePrice': 18000.0,
      },
      {
        'ProductName': 'Hotdog phô mai kéo sợi',
        'CategoryID': 2,
        'SupplierID': 1,
        'Description': 'Hotdog xúc xích Hàn Quốc',
        'ImageUrl':
            'https://images.unsplash.com/photo-1619740455993-9e612b1af08a?w=300',
        'SalePrice': 22000.0,
      },
      {
        'ProductName': 'Pizza hải sản mini',
        'CategoryID': 2,
        'SupplierID': 1,
        'Description': 'Pizza hải sản phô mai xốt cay',
        'ImageUrl':
            'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=300',
        'SalePrice': 35000.0,
      },
      {
        'ProductName': 'Hamburger bò phô mai',
        'CategoryID': 2,
        'SupplierID': 1,
        'Description': 'Hamburger bò Mỹ nướng chín tới',
        'ImageUrl':
            'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=300',
        'SalePrice': 38000.0,
      },
      {
        'ProductName': 'Xôi mặn chà bông lạp xưởng',
        'CategoryID': 2,
        'SupplierID': 1,
        'Description': 'Xôi nếp dẻo thơm ngon',
        'ImageUrl':
            'https://images.unsplash.com/photo-1612838320302-4b3b49afec1c?w=300',
        'SalePrice': 15000.0,
      },
      {
        'ProductName': 'Sandwich tam giác cá ngừ',
        'CategoryID': 2,
        'SupplierID': 1,
        'Description': 'Sandwich cá ngừ sốt mayo',
        'ImageUrl':
            'https://images.unsplash.com/photo-1539252554453-80ab65ce3586?w=300',
        'SalePrice': 20000.0,
      },
      {
        'ProductName': 'Kimbap truyền thống',
        'CategoryID': 2,
        'SupplierID': 1,
        'Description': 'Cơm cuộn rong biển Hàn Quốc',
        'ImageUrl':
            'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?w=300',
        'SalePrice': 28000.0,
      },

      // Snack & Bánh kẹo (CategoryID 3)
      {
        'ProductName': 'Khoai tây chiên Lays',
        'CategoryID': 3,
        'SupplierID': 1,
        'Description': 'Snack khoai tây vị tự nhiên',
        'ImageUrl':
            'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=300',
        'SalePrice': 16000.0,
      },
      {
        'ProductName': 'Snack bắp ngọt Oishi',
        'CategoryID': 3,
        'SupplierID': 1,
        'Description': 'Snack vị bắp sữa ngọt ngào',
        'ImageUrl':
            'https://images.unsplash.com/photo-1599490659223-93a95178e70a?w=300',
        'SalePrice': 7000.0,
      },
      {
        'ProductName': 'Bánh Choco-Pie hộp 2 cái',
        'CategoryID': 3,
        'SupplierID': 1,
        'Description': 'Bánh kem marshmallow socola',
        'ImageUrl':
            'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=300',
        'SalePrice': 12000.0,
      },
      {
        'ProductName': 'Kẹo dẻo Haribo Bears',
        'CategoryID': 3,
        'SupplierID': 1,
        'Description': 'Kẹo dẻo hương trái cây Đức',
        'ImageUrl':
            'https://images.unsplash.com/photo-1581798459219-318e76aecc7b?w=300',
        'SalePrice': 22000.0,
      },
      {
        'ProductName': 'Hạt điều rang muối 100g',
        'CategoryID': 3,
        'SupplierID': 1,
        'Description': 'Hạt điều Bình Phước giòn bùi',
        'ImageUrl':
            'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=300',
        'SalePrice': 45000.0,
      },
      {
        'ProductName': 'Bánh quy bơ Danisa 200g',
        'CategoryID': 3,
        'SupplierID': 1,
        'Description': 'Bánh quy bơ Đan Mạch thượng hạng',
        'ImageUrl':
            'https://images.unsplash.com/photo-1558961317-5f241202db27?w=300',
        'SalePrice': 55000.0,
      },
      {
        'ProductName': 'Socola KitKat 4 thanh',
        'CategoryID': 3,
        'SupplierID': 1,
        'Description': 'Bánh xốp phủ socola ngọt ngào',
        'ImageUrl':
            'https://images.unsplash.com/photo-1549007994-cb92ca8a4a77?w=300',
        'SalePrice': 15000.0,
      },

      // Nhu yếu phẩm (CategoryID 4)
      {
        'ProductName': 'Khăn giấy Paseo bỏ túi',
        'CategoryID': 4,
        'SupplierID': 1,
        'Description': 'Khăn giấy lụa Paseo 3 lớp',
        'ImageUrl':
            'https://images.unsplash.com/photo-1603513492128-ba7bc9bca20f?w=300',
        'SalePrice': 6000.0,
      },
      {
        'ProductName': 'Bàn chải Colgate mềm',
        'CategoryID': 4,
        'SupplierID': 1,
        'Description': 'Bàn chải đánh răng Colgate lông tơ',
        'ImageUrl':
            'https://images.unsplash.com/photo-1559592442-741e2b41cd0b?w=300',
        'SalePrice': 18000.0,
      },
      {
        'ProductName': 'Kem đánh răng Closeup',
        'CategoryID': 4,
        'SupplierID': 1,
        'Description': 'Closeup bạc hà thơm mát 180g',
        'ImageUrl':
            'https://images.unsplash.com/photo-1559592442-741e2b41cd0b?w=300',
        'SalePrice': 38000.0,
      },
      {
        'ProductName': 'Dầu gội Clear gói tiện lợi',
        'CategoryID': 4,
        'SupplierID': 1,
        'Description': 'Dầu gội Clear sạch gàu mát lạnh',
        'ImageUrl':
            'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?w=300',
        'SalePrice': 2000.0,
      },
      {
        'ProductName': 'Nước rửa tay Lifebuoy',
        'CategoryID': 4,
        'SupplierID': 1,
        'Description': 'Lifebuoy bảo vệ vượt trội 10 200ml',
        'ImageUrl':
            'https://images.unsplash.com/photo-1604762524889-3e2fcc145683?w=300',
        'SalePrice': 40000.0,
      },
      {
        'ProductName': 'Sữa tắm Tây Thi dưỡng da',
        'CategoryID': 4,
        'SupplierID': 1,
        'Description': 'Sữa tắm dược liệu Tây Thi 200ml',
        'ImageUrl':
            'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?w=300',
        'SalePrice': 50000.0,
      },
      {
        'ProductName': 'Mì ly Hảo Hảo chua cay',
        'CategoryID': 4,
        'SupplierID': 1,
        'Description': 'Mì ly hương vị tôm chua cay tiện lợi',
        'ImageUrl':
            'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=300',
        'SalePrice': 10000.0,
      },
      {
        'ProductName': 'Băng cá nhân Urgo hộp 20',
        'CategoryID': 4,
        'SupplierID': 1,
        'Description': 'Urgo độ bám dính cao bảo vệ vết thương',
        'ImageUrl':
            'https://images.unsplash.com/photo-1603398938378-e54eab446dde?w=300',
        'SalePrice': 25000.0,
      },
    ];

    for (final p in productData) {
      final productId = await db.insert('Product', {
        'ProductName': p['ProductName'],
        'CategoryID': p['CategoryID'],
        'SupplierID': p['SupplierID'],
        'Description': p['Description'],
        'ImageUrl': p['ImageUrl'],
      });
      // Seed Inventory cho cả 4 Store
      for (int storeId = 1; storeId <= 4; storeId++) {
        final qty = storeId == 1
            ? 120
            : (storeId == 2 ? 80 : (storeId == 3 ? 70 : 60));
        await db.insert('Inventory', {
          'StoreID': storeId,
          'ProductID': productId,
          'Quantity': qty,
          'SalePrice': p['SalePrice'],
          'ExpiredDate': '2026-12-31',
        });
      }
    }

    // Seed Owner Account & Employee
    await db.insert('Account', {
      'Username': 'admin',
      'Password': '123456',
      'RoleID': 1,
      'Status': 1,
    });
    await db.insert('Employee', {
      'FullName': 'Nguyễn Văn A',
      'DOB': '1985-05-15',
      'Gender': 1,
      'Phone': '090111222',
      'Salary': 30000000.0,
      'AccountID': 1,
    });

    // Seed Manager Account & Employee (Store 1)
    await db.insert('Account', {
      'Username': 'manager',
      'Password': '123456',
      'RoleID': 2,
      'Status': 1,
    });
    await db.insert('Employee', {
      'FullName': 'Trần Thị B',
      'DOB': '1990-10-20',
      'Gender': 0,
      'Phone': '0901234567',
      'Salary': 15000000.0,
      'StoreID': 1,
      'AccountID': 2,
    });

    // Seed Staff Account & Employee (Store 1)
    await db.insert('Account', {
      'Username': 'staff',
      'Password': '123456',
      'RoleID': 3,
      'Status': 1,
    });
    await db.insert('Employee', {
      'FullName': 'Lê Văn C',
      'DOB': '1998-12-05',
      'Gender': 1,
      'Phone': '0907654321',
      'Salary': 7000000.0,
      'StoreID': 1,
      'AccountID': 3,
    });

    // --- SEED 8 NHÂN VIÊN MỚI TRÊN 2 CHI NHÁNH MỚI + CHI NHÁNH CŨ ---
    // Store 2 (Q3)
    await db.insert('Account', {
      'Username': 'manager2',
      'Password': '123456',
      'RoleID': 2,
      'Status': 1,
    });
    await db.insert('Employee', {
      'FullName': 'Phạm Văn D',
      'DOB': '1991-04-12',
      'Gender': 1,
      'Phone': '090222333',
      'Salary': 15000000.0,
      'StoreID': 2,
      'AccountID': 4,
    });
    await db.insert('Account', {
      'Username': 'staff2',
      'Password': '123456',
      'RoleID': 3,
      'Status': 1,
    });
    await db.insert('Employee', {
      'FullName': 'Hoàng Thị E',
      'DOB': '1999-07-21',
      'Gender': 0,
      'Phone': '090333444',
      'Salary': 7000000.0,
      'StoreID': 2,
      'AccountID': 5,
    });
    await db.insert('Account', {
      'Username': 'staff3',
      'Password': '123456',
      'RoleID': 3,
      'Status': 1,
    });
    await db.insert('Employee', {
      'FullName': 'Đỗ Văn F',
      'DOB': '2000-01-15',
      'Gender': 1,
      'Phone': '090444555',
      'Salary': 7000000.0,
      'StoreID': 2,
      'AccountID': 6,
    });

    // Store 3 (Bình Thạnh)
    await db.insert('Account', {
      'Username': 'manager3',
      'Password': '123456',
      'RoleID': 2,
      'Status': 1,
    });
    await db.insert('Employee', {
      'FullName': 'Bùi Thị G',
      'DOB': '1992-09-08',
      'Gender': 0,
      'Phone': '090555666',
      'Salary': 15000000.0,
      'StoreID': 3,
      'AccountID': 7,
    });
    await db.insert('Account', {
      'Username': 'staff4',
      'Password': '123456',
      'RoleID': 3,
      'Status': 1,
    });
    await db.insert('Employee', {
      'FullName': 'Vũ Văn H',
      'DOB': '1997-11-30',
      'Gender': 1,
      'Phone': '090666777',
      'Salary': 7000000.0,
      'StoreID': 3,
      'AccountID': 8,
    });
    await db.insert('Account', {
      'Username': 'staff5',
      'Password': '123456',
      'RoleID': 3,
      'Status': 1,
    });
    await db.insert('Employee', {
      'FullName': 'Ngô Thị I',
      'DOB': '2001-05-18',
      'Gender': 0,
      'Phone': '090777888',
      'Salary': 7000000.0,
      'StoreID': 3,
      'AccountID': 9,
    });

    // Store 4 (Phú Nhuận)
    await db.insert('Account', {
      'Username': 'manager4',
      'Password': '123456',
      'RoleID': 2,
      'Status': 1,
    });
    await db.insert('Employee', {
      'FullName': 'Lý Văn K',
      'DOB': '1989-02-28',
      'Gender': 1,
      'Phone': '090888999',
      'Salary': 16000000.0,
      'StoreID': 4,
      'AccountID': 10,
    });
    await db.insert('Account', {
      'Username': 'staff6',
      'Password': '123456',
      'RoleID': 3,
      'Status': 1,
    });
    await db.insert('Employee', {
      'FullName': 'Dương Thị L',
      'DOB': '2000-08-04',
      'Gender': 0,
      'Phone': '090999000',
      'Salary': 7500000.0,
      'StoreID': 4,
      'AccountID': 11,
    });
  }

  // --- CRUD BUSINESS METHODS ---

  // Check login credentials, returns account + employee info
  Future<Map<String, dynamic>?> login(String username, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> res = await db.rawQuery(
      '''
      SELECT a.AccountID, a.Username, a.RoleID, a.Status, e.EmployeeID, e.FullName, e.StoreID, r.RoleName
      FROM Account a
      INNER JOIN Role r ON a.RoleID = r.RoleID
      LEFT JOIN Employee e ON a.AccountID = e.AccountID
      WHERE a.Username = ? AND a.Password = ?
    ''',
      [username, password],
    );

    if (res.isNotEmpty) {
      return res.first;
    }
    return null;
  }

  // Create account and link to an employee profile
  Future<int> createAccount({
    required String username,
    required String password,
    required int roleId,
    required int storeId,
    required String fullName,
    required int gender,
    required String phone,
  }) async {
    final db = await database;

    // Check username existence
    final List<Map<String, dynamic>> existing = await db.query(
      'Account',
      where: 'Username = ?',
      whereArgs: [username],
    );

    if (existing.isNotEmpty) {
      return -1; // Duplicate username error
    }

    return await db.transaction((txn) async {
      final accountId = await txn.insert('Account', {
        'Username': username,
        'Password': password,
        'RoleID': roleId,
        'Status': 1,
      });

      await txn.insert('Employee', {
        'FullName': fullName,
        'Gender': gender,
        'Phone': phone,
        'StoreID': storeId,
        'AccountID': accountId,
        'Salary': roleId == 2 ? 15000000.0 : 7000000.0,
      });

      return accountId;
    });
  }

  // Edit employee and manager account details
  Future<int> updateAccount({
    required int accountId,
    required int employeeId,
    required String username,
    required String password,
    required int roleId,
    required int storeId,
    required String fullName,
    required int gender,
    required String phone,
  }) async {
    final db = await database;

    // Check username uniqueness (excluding the current account)
    final List<Map<String, dynamic>> existing = await db.query(
      'Account',
      where: 'Username = ? AND AccountID != ?',
      whereArgs: [username, accountId],
    );

    if (existing.isNotEmpty) {
      return -1; // Duplicate username error
    }

    return await db.transaction((txn) async {
      await txn.update(
        'Account',
        {'Username': username, 'Password': password, 'RoleID': roleId},
        where: 'AccountID = ?',
        whereArgs: [accountId],
      );

      await txn.update(
        'Employee',
        {
          'FullName': fullName,
          'Gender': gender,
          'Phone': phone,
          'StoreID': storeId,
        },
        where: 'EmployeeID = ?',
        whereArgs: [employeeId],
      );

      return 1; // Success
    });
  }

  // Lock/Unlock an account
  Future<int> toggleAccountStatus(int accountId, int currentStatus) async {
    final db = await database;
    final newStatus = currentStatus == 1 ? 0 : 1;
    return await db.update(
      'Account',
      {'Status': newStatus},
      where: 'AccountID = ?',
      whereArgs: [accountId],
    );
  }

  // Fetch all accounts and employees profiles
  Future<List<Map<String, dynamic>>> getEmployeeList() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT e.EmployeeID, e.FullName, e.Phone, e.Gender, e.StoreID, a.AccountID, a.Username, a.Password, a.Status, a.RoleID, r.RoleName, s.StoreName
      FROM Employee e
      INNER JOIN Account a ON e.AccountID = a.AccountID
      INNER JOIN Role r ON a.RoleID = r.RoleID
      LEFT JOIN Store s ON e.StoreID = s.StoreID
      ORDER BY e.EmployeeID ASC
    ''');
  }

  // POS sales: creates Invoice and InvoiceDetail, decrements stock
  Future<bool> createInvoice({
    required int storeId,
    required int employeeId,
    required List<Map<String, dynamic>>
    items, // keys: ProductID, Quantity, UnitPrice, PromotionID, DiscountAmount
    required double totalAmount,
  }) async {
    final db = await database;
    try {
      await db.transaction((txn) async {
        final invoiceId = await txn.insert('Invoice', {
          'StoreID': storeId,
          'CustomerID': 1, // Default customer
          'EmployeeID': employeeId,
          'InvoiceDate': DateTime.now().toIso8601String(),
          'TotalAmount': totalAmount,
        });

        for (final item in items) {
          await txn.insert('InvoiceDetail', {
            'InvoiceID': invoiceId,
            'ProductID': item['ProductID'],
            'PromotionID': item['PromotionID'],
            'Quantity': item['Quantity'],
            'UnitPrice': item['UnitPrice'],
            'DiscountAmount': item['DiscountAmount'] ?? 0.0,
          });

          // Decrement inventory
          await txn.rawUpdate(
            '''
            UPDATE Inventory
            SET Quantity = MAX(0, Quantity - ?)
            WHERE StoreID = ? AND ProductID = ?
          ''',
            [item['Quantity'], storeId, item['ProductID']],
          );
        }
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Import Goods (Purchase Order): increments inventory
  Future<bool> createPurchaseOrder({
    required int employeeId,
    required int storeId,
    required List<Map<String, dynamic>>
    items, // keys: ProductID, Quantity, ImportPrice
  }) async {
    final db = await database;
    try {
      await db.transaction((txn) async {
        final poId = await txn.insert('PurchaseOrder', {
          'SupplierID': 1, // Default supplier
          'EmployeeID': employeeId,
          'OrderDate': DateTime.now().toIso8601String(),
        });

        for (final item in items) {
          await txn.insert('PurchaseOrderDetail', {
            'PurchaseOrderID': poId,
            'ProductID': item['ProductID'],
            'Quantity': item['Quantity'],
            'ImportPrice': item['ImportPrice'],
            'ExpiredDate': DateTime.now()
                .add(const Duration(days: 90))
                .toIso8601String()
                .substring(0, 10),
          });

          // Increment inventory
          await txn.rawUpdate(
            '''
            UPDATE Inventory
            SET Quantity = Quantity + ?
            WHERE StoreID = ? AND ProductID = ?
          ''',
            [item['Quantity'], storeId, item['ProductID']],
          );
        }
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Staff creates a transfer request. Inventory changes only after approval.
  Future<bool> createTransferRequest({
    required int fromStoreId,
    required int toStoreId,
    required int productId,
    required int quantity,
    required int requestedByEmployeeId,
  }) async {
    final db = await database;
    try {
      if (fromStoreId == toStoreId || quantity <= 0) return false;

      return await db.transaction<bool>((txn) async {
        final requester = await txn.rawQuery(
          '''
          SELECT e.EmployeeID
          FROM Employee e
          INNER JOIN Account a ON a.AccountID = e.AccountID
          WHERE e.EmployeeID = ?
            AND e.StoreID = ?
            AND a.RoleID = 3
            AND a.Status = 1
          LIMIT 1
          ''',
          [requestedByEmployeeId, fromStoreId],
        );
        if (requester.isEmpty) return false;

        final sourceInv = await txn.query(
          'Inventory',
          where: 'StoreID = ? AND ProductID = ?',
          whereArgs: [fromStoreId, productId],
          limit: 1,
        );
        if (sourceInv.isEmpty ||
            (sourceInv.first['Quantity'] as int) < quantity) {
          return false;
        }

        await txn.insert('TransferOrder', {
          'FromStoreID': fromStoreId,
          'ToStoreID': toStoreId,
          'ProductID': productId,
          'Quantity': quantity,
          'TransferDate': DateTime.now().toIso8601String(),
          'RequestedByEmployeeID': requestedByEmployeeId,
          'Status': 'Pending',
        });
        return true;
      });
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getTransferRequestsForManager(
    int storeId,
  ) async {
    return await _getTransferRequests(
      't.FromStoreID = ?',
      [storeId],
    );
  }

  Future<List<Map<String, dynamic>>> getTransferRequestsForStaff(
    int employeeId,
  ) async {
    return await _getTransferRequests(
      't.RequestedByEmployeeID = ?',
      [employeeId],
    );
  }

  Future<List<Map<String, dynamic>>> _getTransferRequests(
    String whereClause,
    List<Object?> whereArgs,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT t.TransferID, t.FromStoreID, t.ToStoreID, t.ProductID,
             t.Quantity, t.TransferDate, t.RequestedByEmployeeID,
             t.Status, t.ReviewedByEmployeeID, t.ReviewedAt,
             p.ProductName,
             sourceStore.StoreName AS FromStoreName,
             targetStore.StoreName AS ToStoreName,
             requester.FullName AS RequestedByName,
             reviewer.FullName AS ReviewedByName,
             COALESCE(sourceInventory.Quantity, 0) AS AvailableQuantity
      FROM TransferOrder t
      INNER JOIN Product p ON p.ProductID = t.ProductID
      INNER JOIN Store sourceStore ON sourceStore.StoreID = t.FromStoreID
      INNER JOIN Store targetStore ON targetStore.StoreID = t.ToStoreID
      LEFT JOIN Employee requester
        ON requester.EmployeeID = t.RequestedByEmployeeID
      LEFT JOIN Employee reviewer
        ON reviewer.EmployeeID = t.ReviewedByEmployeeID
      LEFT JOIN Inventory sourceInventory
        ON sourceInventory.StoreID = t.FromStoreID
       AND sourceInventory.ProductID = t.ProductID
      WHERE $whereClause
      ORDER BY CASE t.Status
                 WHEN 'Pending' THEN 0
                 WHEN 'Approved' THEN 1
                 ELSE 2
               END,
               t.TransferID DESC
      ''',
      whereArgs,
    );
  }

  // Returns: approved, rejected, insufficient_stock, already_processed,
  // unauthorized, not_found, or error.
  Future<String> reviewTransferRequest({
    required int transferId,
    required int managerEmployeeId,
    required bool approve,
  }) async {
    final db = await database;
    try {
      return await db.transaction<String>((txn) async {
        final requests = await txn.query(
          'TransferOrder',
          where: 'TransferID = ?',
          whereArgs: [transferId],
          limit: 1,
        );
        if (requests.isEmpty) return 'not_found';

        final request = requests.first;
        if (request['Status'] != 'Pending') return 'already_processed';

        final manager = await txn.rawQuery(
          '''
          SELECT e.EmployeeID
          FROM Employee e
          INNER JOIN Account a ON a.AccountID = e.AccountID
          WHERE e.EmployeeID = ?
            AND e.StoreID = ?
            AND a.RoleID = 2
            AND a.Status = 1
          LIMIT 1
          ''',
          [managerEmployeeId, request['FromStoreID']],
        );
        if (manager.isEmpty) return 'unauthorized';

        final reviewedAt = DateTime.now().toIso8601String();
        if (!approve) {
          final updated = await txn.update(
            'TransferOrder',
            {
              'Status': 'Rejected',
              'ReviewedByEmployeeID': managerEmployeeId,
              'ReviewedAt': reviewedAt,
            },
            where: 'TransferID = ? AND Status = ?',
            whereArgs: [transferId, 'Pending'],
          );
          return updated == 1 ? 'rejected' : 'already_processed';
        }

        final fromStoreId = request['FromStoreID'] as int;
        final toStoreId = request['ToStoreID'] as int;
        final productId = request['ProductID'] as int;
        final quantity = request['Quantity'] as int;

        final sourceInventory = await txn.query(
          'Inventory',
          where: 'StoreID = ? AND ProductID = ?',
          whereArgs: [fromStoreId, productId],
          limit: 1,
        );
        if (sourceInventory.isEmpty ||
            (sourceInventory.first['Quantity'] as int) < quantity) {
          return 'insufficient_stock';
        }

        final decremented = await txn.rawUpdate(
          '''
          UPDATE Inventory
          SET Quantity = Quantity - ?
          WHERE StoreID = ? AND ProductID = ? AND Quantity >= ?
        ''',
          [quantity, fromStoreId, productId, quantity],
        );
        if (decremented != 1) return 'insufficient_stock';

        final targetInventory = await txn.query(
          'Inventory',
          where: 'StoreID = ? AND ProductID = ?',
          whereArgs: [toStoreId, productId],
          limit: 1,
        );
        if (targetInventory.isEmpty) {
          await txn.insert('Inventory', {
            'StoreID': toStoreId,
            'ProductID': productId,
            'Quantity': quantity,
            'SalePrice': sourceInventory.first['SalePrice'] ?? 0.0,
          });
        } else {
          await txn.rawUpdate(
            '''
            UPDATE Inventory
            SET Quantity = Quantity + ?
            WHERE StoreID = ? AND ProductID = ?
          ''',
            [quantity, toStoreId, productId],
          );
        }

        final updated = await txn.update(
          'TransferOrder',
          {
            'Status': 'Approved',
            'ReviewedByEmployeeID': managerEmployeeId,
            'ReviewedAt': reviewedAt,
          },
          where: 'TransferID = ? AND Status = ?',
          whereArgs: [transferId, 'Pending'],
        );
        if (updated != 1) {
          throw StateError('Transfer request was processed concurrently.');
        }
        return 'approved';
      });
    } catch (e) {
      return 'error';
    }
  }

  // Audit Inventory (Kiểm kho)
  Future<bool> auditInventory(int storeId, int productId, int actualQty) async {
    final db = await database;
    try {
      await db.update(
        'Inventory',
        {'Quantity': actualQty},
        where: 'StoreID = ? AND ProductID = ?',
        whereArgs: [storeId, productId],
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // Fetch product inventory details
  Future<List<Map<String, dynamic>>> getInventoryList(int storeId) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT i.InventoryID, i.StoreID, i.ProductID, i.Quantity, i.SalePrice, p.ProductName, p.ImageUrl, c.CategoryName
      FROM Inventory i
      INNER JOIN Product p ON i.ProductID = p.ProductID
      INNER JOIN Category c ON p.CategoryID = c.CategoryID
      WHERE i.StoreID = ?
    ''',
      [storeId],
    );
  }

  // Load available products in system
  Future<List<Map<String, dynamic>>> getProductsList() async {
    final db = await database;
    return await db.query('Product');
  }

  // Fetch revenue reports: period: 'Day', 'Month', 'Year'
  Future<List<Map<String, dynamic>>> getRevenue(
    int? storeId,
    String period,
  ) async {
    final db = await database;
    String dateFilter = '';
    String groupBy = '';

    if (period == 'Day') {
      dateFilter = "strftime('%Y-%m-%d', InvoiceDate)";
      groupBy = "strftime('%Y-%m-%d', InvoiceDate)";
    } else if (period == 'Month') {
      dateFilter = "strftime('%Y-%m', InvoiceDate)";
      groupBy = "strftime('%Y-%m', InvoiceDate)";
    } else {
      dateFilter = "strftime('%Y', InvoiceDate)";
      groupBy = "strftime('%Y', InvoiceDate)";
    }

    String query = '';
    List<dynamic> args = [];
    if (storeId != null) {
      query =
          '''
        SELECT $dateFilter AS date, SUM(TotalAmount) AS revenue, COUNT(InvoiceID) AS orderCount
        FROM Invoice
        WHERE StoreID = ?
        GROUP BY $groupBy
        ORDER BY date DESC
        LIMIT 10
      ''';
      args = [storeId];
    } else {
      query =
          '''
        SELECT $dateFilter AS date, SUM(TotalAmount) AS revenue, COUNT(InvoiceID) AS orderCount
        FROM Invoice
        GROUP BY $groupBy
        ORDER BY date DESC
        LIMIT 10
      ''';
    }

    return await db.rawQuery(query, args);
  }

  // --- Invoices --- //
  Future<List<Map<String, dynamic>>> getInvoices(int? storeId) async {
    final db = await database;
    if (storeId != null) {
      return await db.rawQuery('''
        SELECT i.*, e.FullName as EmployeeName, s.StoreName
        FROM Invoice i
        LEFT JOIN Employee e ON i.EmployeeID = e.EmployeeID
        LEFT JOIN Store s ON i.StoreID = s.StoreID
        WHERE i.StoreID = ?
        ORDER BY i.InvoiceDate DESC
      ''', [storeId]);
    } else {
      return await db.rawQuery('''
        SELECT i.*, e.FullName as EmployeeName, s.StoreName
        FROM Invoice i
        LEFT JOIN Employee e ON i.EmployeeID = e.EmployeeID
        LEFT JOIN Store s ON i.StoreID = s.StoreID
        ORDER BY i.InvoiceDate DESC
      ''');
    }
  }

  Future<List<Map<String, dynamic>>> getInvoiceDetails(int invoiceId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT d.*, p.ProductName
      FROM InvoiceDetail d
      LEFT JOIN Product p ON d.ProductID = p.ProductID
      WHERE d.InvoiceID = ?
    ''', [invoiceId]);
  }

  // Shift Schedule
  Future<int> saveSchedule(int employeeId, String date, String shift) async {
    final db = await database;
    // Check if exists
    final List<Map<String, dynamic>> existing = await db.query(
      'WorkSchedule',
      where: 'EmployeeID = ? AND WorkDate = ?',
      whereArgs: [employeeId, date],
    );

    if (existing.isNotEmpty) {
      return await db.update(
        'WorkSchedule',
        {'Shift': shift},
        where: 'ScheduleID = ?',
        whereArgs: [existing.first['ScheduleID']],
      );
    } else {
      return await db.insert('WorkSchedule', {
        'EmployeeID': employeeId,
        'WorkDate': date,
        'Shift': shift,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getSchedulesForEmployee(
    int employeeId,
  ) async {
    final db = await database;
    return await db.query(
      'WorkSchedule',
      where: 'EmployeeID = ?',
      whereArgs: [employeeId],
      orderBy: 'WorkDate ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getSchedulesForStore(int storeId) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT ws.ScheduleID, ws.EmployeeID, ws.WorkDate, ws.Shift, e.FullName
      FROM WorkSchedule ws
      INNER JOIN Employee e ON ws.EmployeeID = e.EmployeeID
      WHERE e.StoreID = ?
      ORDER BY ws.WorkDate ASC
    ''',
      [storeId],
    );
  }

  Future<List<Map<String, dynamic>>> getStoresList() async {
    final db = await database;
    return await db.query('Store', orderBy: 'StoreID ASC');
  }

  // ── STORE CRUD ─────────────────────────────────────────────────────────────

  Future<int> insertStore({
    required String storeName,
    String? address,
    String? phone,
    String? openTime,
    String? closeTime,
    String status = 'Active',
  }) async {
    final db = await database;
    return await db.insert('Store', {
      'StoreName': storeName,
      'Address': address,
      'Phone': phone,
      'OpenTime': openTime,
      'CloseTime': closeTime,
      'Status': status,
    });
  }

  Future<int> updateStore({
    required int storeId,
    required String storeName,
    String? address,
    String? phone,
    String? openTime,
    String? closeTime,
    String? status,
  }) async {
    final db = await database;
    return await db.update(
      'Store',
      {
        'StoreName': storeName,
        'Address': address,
        'Phone': phone,
        'OpenTime': openTime,
        'CloseTime': closeTime,
        'Status': status,
      },
      where: 'StoreID = ?',
      whereArgs: [storeId],
    );
  }

  /// Returns -1 if store still has employees, -2 if has inventory, else rows deleted
  Future<int> deleteStore(int storeId) async {
    final db = await database;
    final empCheck = await db.query(
      'Employee',
      where: 'StoreID = ?',
      whereArgs: [storeId],
      limit: 1,
    );
    if (empCheck.isNotEmpty) return -1;
    final invCheck = await db.query(
      'Inventory',
      where: 'StoreID = ? AND Quantity > 0',
      whereArgs: [storeId],
      limit: 1,
    );
    if (invCheck.isNotEmpty) return -2;
    return await db.delete('Store', where: 'StoreID = ?', whereArgs: [storeId]);
  }

  Future<List<Map<String, dynamic>>> getStoresWithEmployeeCount() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT s.StoreID, s.StoreName, s.Address, s.Phone,
             s.OpenTime, s.CloseTime, s.Status,
             COUNT(e.EmployeeID) AS EmployeeCount
      FROM Store s
      LEFT JOIN Employee e ON s.StoreID = e.StoreID
      GROUP BY s.StoreID
      ORDER BY s.StoreID ASC
    ''');
  }

  Future<int> toggleStoreStatus(int storeId, String currentStatus) async {
    final db = await database;
    final newStatus = currentStatus == 'Active' ? 'Inactive' : 'Active';
    return await db.update(
      'Store',
      {'Status': newStatus},
      where: 'StoreID = ?',
      whereArgs: [storeId],
    );
  }

  // ── EMPLOYEE DETAIL CRUD ───────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getEmployeeById(int employeeId) async {
    final db = await database;
    final res = await db.rawQuery(
      '''
      SELECT e.*, a.Username, a.RoleID, a.Status AS AccountStatus, r.RoleName, s.StoreName
      FROM Employee e
      LEFT JOIN Account a ON e.AccountID = a.AccountID
      LEFT JOIN Role r ON a.RoleID = r.RoleID
      LEFT JOIN Store s ON e.StoreID = s.StoreID
      WHERE e.EmployeeID = ?
    ''',
      [employeeId],
    );
    return res.isNotEmpty ? res.first : null;
  }

  Future<int> updateEmployeeDetail({
    required int employeeId,
    required String fullName,
    String? dob,
    int? gender,
    String? address,
    String? phone,
    double? salary,
    int? storeId,
  }) async {
    final db = await database;
    return await db.update(
      'Employee',
      {
        'FullName': fullName,
        'DOB': dob,
        'Gender': gender,
        'Address': address,
        'Phone': phone,
        'Salary': salary,
        'StoreID': storeId,
      },
      where: 'EmployeeID = ?',
      whereArgs: [employeeId],
    );
  }

  Future<List<Map<String, dynamic>>> getEmployeesWithDetail({
    int? storeId,
    int? roleId,
  }) async {
    final db = await database;
    String where = '';
    List<dynamic> args = [];
    if (storeId != null && roleId != null) {
      where = 'WHERE e.StoreID = ? AND a.RoleID = ?';
      args = [storeId, roleId];
    } else if (storeId != null) {
      where = 'WHERE e.StoreID = ?';
      args = [storeId];
    } else if (roleId != null) {
      where = 'WHERE a.RoleID = ?';
      args = [roleId];
    }
    return await db.rawQuery('''
      SELECT e.EmployeeID, e.FullName, e.DOB, e.Gender, e.Address, e.Phone, e.Salary,
             e.StoreID, e.AccountID, a.Username, a.RoleID, a.Status AS AccountStatus,
             r.RoleName, s.StoreName
      FROM Employee e
      LEFT JOIN Account a ON e.AccountID = a.AccountID
      LEFT JOIN Role r ON a.RoleID = r.RoleID
      LEFT JOIN Store s ON e.StoreID = s.StoreID
      $where
      ORDER BY e.EmployeeID ASC
    ''', args);
  }

  // ── CATEGORY CRUD ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCategoriesList() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT c.CategoryID, c.CategoryName, COUNT(p.ProductID) AS ProductCount
      FROM Category c
      LEFT JOIN Product p ON c.CategoryID = p.CategoryID
      GROUP BY c.CategoryID
      ORDER BY c.CategoryID ASC
    ''');
  }

  Future<int> insertCategory(String categoryName) async {
    final db = await database;
    return await db.insert('Category', {'CategoryName': categoryName});
  }

  Future<int> updateCategory(int categoryId, String categoryName) async {
    final db = await database;
    return await db.update(
      'Category',
      {'CategoryName': categoryName},
      where: 'CategoryID = ?',
      whereArgs: [categoryId],
    );
  }

  /// Returns -1 if category still has products, else rows deleted
  Future<int> deleteCategory(int categoryId) async {
    final db = await database;
    final check = await db.query(
      'Product',
      where: 'CategoryID = ?',
      whereArgs: [categoryId],
      limit: 1,
    );
    if (check.isNotEmpty) return -1;
    return await db.delete(
      'Category',
      where: 'CategoryID = ?',
      whereArgs: [categoryId],
    );
  }

  // ── PRODUCT CRUD ───────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getProductsWithDetail({
    int? categoryId,
  }) async {
    final db = await database;
    final where = categoryId != null ? 'WHERE p.CategoryID = ?' : '';
    final args = categoryId != null ? [categoryId] : <dynamic>[];
    return await db.rawQuery('''
      SELECT p.ProductID, p.ProductName, p.Description, p.ImageUrl,
             p.CategoryID, c.CategoryName,
             p.SupplierID, s.SupplierName
      FROM Product p
      LEFT JOIN Category c ON p.CategoryID = c.CategoryID
      LEFT JOIN Supplier s ON p.SupplierID = s.SupplierID
      $where
      ORDER BY p.ProductID ASC
    ''', args);
  }

  Future<int> insertProduct({
    required String productName,
    int? categoryId,
    int? supplierId,
    String? description,
    String? imageUrl,
  }) async {
    final db = await database;
    return await db.insert('Product', {
      'ProductName': productName,
      'CategoryID': categoryId,
      'SupplierID': supplierId,
      'Description': description,
      'ImageUrl': imageUrl,
    });
  }

  Future<int> updateProduct({
    required int productId,
    required String productName,
    int? categoryId,
    int? supplierId,
    String? description,
    String? imageUrl,
  }) async {
    final db = await database;
    return await db.update(
      'Product',
      {
        'ProductName': productName,
        'CategoryID': categoryId,
        'SupplierID': supplierId,
        'Description': description,
        'ImageUrl': imageUrl,
      },
      where: 'ProductID = ?',
      whereArgs: [productId],
    );
  }

  /// Returns -1 if any store still has Quantity > 0, else rows deleted
  Future<int> deleteProduct(int productId) async {
    final db = await database;
    final check = await db.rawQuery(
      'SELECT 1 FROM Inventory WHERE ProductID = ? AND Quantity > 0 LIMIT 1',
      [productId],
    );
    if (check.isNotEmpty) return -1;
    return await db.delete(
      'Product',
      where: 'ProductID = ?',
      whereArgs: [productId],
    );
  }

  // ── SUPPLIER CRUD ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getSuppliersList() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT s.SupplierID, s.SupplierName, s.Address, s.Email, s.Phone,
             COUNT(p.ProductID) AS ProductCount
      FROM Supplier s
      LEFT JOIN Product p ON s.SupplierID = p.SupplierID
      GROUP BY s.SupplierID
      ORDER BY s.SupplierID ASC
    ''');
  }

  Future<int> insertSupplier({
    required String supplierName,
    String? address,
    String? email,
    String? phone,
  }) async {
    final db = await database;
    return await db.insert('Supplier', {
      'SupplierName': supplierName,
      'Address': address,
      'Email': email,
      'Phone': phone,
    });
  }

  Future<int> updateSupplier({
    required int supplierId,
    required String supplierName,
    String? address,
    String? email,
    String? phone,
  }) async {
    final db = await database;
    return await db.update(
      'Supplier',
      {
        'SupplierName': supplierName,
        'Address': address,
        'Email': email,
        'Phone': phone,
      },
      where: 'SupplierID = ?',
      whereArgs: [supplierId],
    );
  }

  /// Returns -1 if supplier still has products linked, else rows deleted
  Future<int> deleteSupplier(int supplierId) async {
    final db = await database;
    final check = await db.query(
      'Product',
      where: 'SupplierID = ?',
      whereArgs: [supplierId],
      limit: 1,
    );
    if (check.isNotEmpty) return -1;
    return await db.delete(
      'Supplier',
      where: 'SupplierID = ?',
      whereArgs: [supplierId],
    );
  }
}
