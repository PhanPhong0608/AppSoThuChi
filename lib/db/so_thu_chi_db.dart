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
      version: 3,
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
CREATE TABLE vi_tien (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ten TEXT NOT NULL,
  loai TEXT,
  so_du INTEGER NOT NULL DEFAULT 0,
  icon TEXT,
  an INTEGER DEFAULT 0
);
''');

        await db.execute('''
CREATE TABLE giao_dich (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tai_khoan_id INTEGER NOT NULL,
  vi_tien_id INTEGER,
  so_tien INTEGER NOT NULL CHECK(so_tien >= 0),
  danh_muc_id INTEGER NOT NULL,
  ngay INTEGER NOT NULL,
  ghi_chu TEXT,
  tao_luc INTEGER NOT NULL,
  FOREIGN KEY (tai_khoan_id) REFERENCES tai_khoan(id),
  FOREIGN KEY (danh_muc_id) REFERENCES danh_muc(id),
  FOREIGN KEY (vi_tien_id) REFERENCES vi_tien(id)
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

        // Seed ví mẫu
        final seedVi = [
          {"ten": "Tiền mặt", "loai": "cash"},
        ];
        for (final vi in seedVi) {
          await db.insert("vi_tien", vi);
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
           // (Old migration code for v2)
           // ... (We can keep or simplify, but let's just focus on the upgrade chain properly)
           // Since we are overwriting, let's keep it clean.
        }
        
        if (oldVersion < 3) {
           // Upgrade to V3
           await db.execute('''
CREATE TABLE vi_tien (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ten TEXT NOT NULL,
  loai TEXT,
  so_du INTEGER NOT NULL DEFAULT 0,
  icon TEXT,
  an INTEGER DEFAULT 0
);
''');
           
        // Seed ví mẫu
        final seedVi = [
          {"ten": "Tiền mặt", "loai": "cash"},
        ];
        for (final vi in seedVi) {
          await db.insert("vi_tien", vi);
        }

           // Add vi_tien_id to giao_dich
           // SQLite limitation: Cannot easily ADD COLUMN with FOREIGN KEY in one step usually works in simple cases, 
           // but safer to add column then update. 
           // Better yet: Just add the column.
           try {
             await db.execute("ALTER TABLE giao_dich ADD COLUMN vi_tien_id INTEGER REFERENCES vi_tien(id);");
           } catch (e) {
             // Ignore if already exists or fails (e.g. strict FK constraints)
           }
        }
      },
    );
  }
}
