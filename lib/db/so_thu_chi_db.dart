import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SoThuChiDb {
  SoThuChiDb._();
  static final SoThuChiDb instance = SoThuChiDb._();

  Database? _db;

  Database get db {
    final d = _db;
    if (d == null) throw Exception("DB chưa khởi tạo. Gọi SoThuChiDb.instance.init()");
    return d;
  }

  Future<void> init() async {
    if (_db != null) return;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, "so_thu_chi.db");

    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE tai_khoan (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT NOT NULL UNIQUE,
  mat_khau_hash TEXT NOT NULL,
  salt TEXT NOT NULL,
  tao_luc INTEGER NOT NULL
);
''');

        await db.execute('''
CREATE TABLE danh_muc (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ten TEXT NOT NULL,
  loai TEXT NOT NULL DEFAULT 'expense',
  icon TEXT,
  mau INTEGER
);
''');

        await db.execute('''
CREATE TABLE giao_dich (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tai_khoan_id INTEGER NOT NULL,
  so_tien INTEGER NOT NULL CHECK(so_tien >= 0),
  danh_muc_id INTEGER NOT NULL,
  ngay INTEGER NOT NULL,
  ghi_chu TEXT,
  tao_luc INTEGER NOT NULL,
  FOREIGN KEY (tai_khoan_id) REFERENCES tai_khoan(id),
  FOREIGN KEY (danh_muc_id) REFERENCES danh_muc(id)
);
''');

        await db.execute('''
CREATE TABLE ngan_sach_thang (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tai_khoan_id INTEGER NOT NULL,
  nam INTEGER NOT NULL,
  thang INTEGER NOT NULL CHECK(thang BETWEEN 1 AND 12),
  so_tien_ngan_sach INTEGER NOT NULL CHECK(so_tien_ngan_sach >= 0),
  UNIQUE(tai_khoan_id, nam, thang),
  FOREIGN KEY (tai_khoan_id) REFERENCES tai_khoan(id)
);
''');

        // Seed danh mục mẫu
        final seed = [
          "Ăn uống",
          "Đi chơi",
          "Mua sắm",
          "Thể thao",
          "Giải trí",
          "Di chuyển",
          "Học tập",
          "Sức khỏe",
        ];
        for (final ten in seed) {
          await db.insert("danh_muc", {"ten": ten, "loai": "expense"});
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Đơn giản hóa: tạo bảng tài khoản + drop/recreate 2 bảng có liên quan user
          await db.execute('''
CREATE TABLE IF NOT EXISTS tai_khoan (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT NOT NULL UNIQUE,
  mat_khau_hash TEXT NOT NULL,
  salt TEXT NOT NULL,
  tao_luc INTEGER NOT NULL
);
''');

          await db.execute('DROP TABLE IF EXISTS giao_dich;');
          await db.execute('DROP TABLE IF EXISTS ngan_sach_thang;');

          await db.execute('''
CREATE TABLE giao_dich (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tai_khoan_id INTEGER NOT NULL,
  so_tien INTEGER NOT NULL CHECK(so_tien >= 0),
  danh_muc_id INTEGER NOT NULL,
  ngay INTEGER NOT NULL,
  ghi_chu TEXT,
  tao_luc INTEGER NOT NULL,
  FOREIGN KEY (tai_khoan_id) REFERENCES tai_khoan(id),
  FOREIGN KEY (danh_muc_id) REFERENCES danh_muc(id)
);
''');

          await db.execute('''
CREATE TABLE ngan_sach_thang (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tai_khoan_id INTEGER NOT NULL,
  nam INTEGER NOT NULL,
  thang INTEGER NOT NULL CHECK(thang BETWEEN 1 AND 12),
  so_tien_ngan_sach INTEGER NOT NULL CHECK(so_tien_ngan_sach >= 0),
  UNIQUE(tai_khoan_id, nam, thang),
  FOREIGN KEY (tai_khoan_id) REFERENCES tai_khoan(id)
);
''');
        }
      },
    );
  }
}
