import 'package:sqflite/sqflite.dart';

import '../db/so_thu_chi_db.dart';
import '../db/models/danh_muc.dart';
import '../db/models/giao_dich.dart';

class KhoThuChiRepository {
  final SoThuChiDb _db;
  KhoThuChiRepository(this._db);

  Database get db => _db.db;

  Future<List<DanhMuc>> layDanhMuc() async {
    final rows = await db.query("danh_muc", orderBy: "id ASC");
    return rows.map((e) => DanhMuc.fromMap(e)).toList();
  }

  Future<void> capNhatNganSachThang({
    required int taiKhoanId,
    required int nam,
    required int thang,
    required int soTienNganSach,
  }) async {
    await db.insert(
      "ngan_sach_thang",
      {
        "tai_khoan_id": taiKhoanId,
        "nam": nam,
        "thang": thang,
        "so_tien_ngan_sach": soTienNganSach
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int?> layNganSachThang({
    required int taiKhoanId,
    required int nam,
    required int thang,
  }) async {
    final rows = await db.query(
      "ngan_sach_thang",
      columns: ["so_tien_ngan_sach"],
      where: "tai_khoan_id = ? AND nam = ? AND thang = ?",
      whereArgs: [taiKhoanId, nam, thang],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first["so_tien_ngan_sach"] as int;
  }

  Future<int> themGiaoDich({
    required int taiKhoanId,
    required int soTien,
    required int danhMucId,
    required DateTime ngay,
    String? ghiChu,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.insert("giao_dich", {
      "tai_khoan_id": taiKhoanId,
      "so_tien": soTien,
      "danh_muc_id": danhMucId,
      "ngay": ngay.millisecondsSinceEpoch,
      "ghi_chu": ghiChu,
      "tao_luc": now,
    });
  }

  Future<int> tinhTongChiTrongKhoang({
    required int taiKhoanId,
    required int startMs,
    required int endMs,
  }) async {
    final rows = await db.rawQuery('''
SELECT COALESCE(SUM(so_tien), 0) AS da_chi
FROM giao_dich
WHERE tai_khoan_id = ? AND ngay >= ? AND ngay < ?;
''', [taiKhoanId, startMs, endMs]);

    return (rows.first["da_chi"] as int?) ?? 0;
  }

  Future<List<GiaoDich>> layGiaoDichTrongKhoang({
    required int taiKhoanId,
    required int startMs,
    required int endMs,
  }) async {
    final rows = await db.query(
      "giao_dich",
      where: "tai_khoan_id = ? AND ngay >= ? AND ngay < ?",
      whereArgs: [taiKhoanId, startMs, endMs],
      orderBy: "ngay DESC, id DESC",
    );
    return rows.map((e) => GiaoDich.fromMap(e)).toList();
  }
}
