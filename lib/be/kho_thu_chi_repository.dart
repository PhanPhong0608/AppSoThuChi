import 'package:sqflite/sqflite.dart';

import '../db/so_thu_chi_db.dart';
import '../db/models/danh_muc.dart';
import '../db/models/giao_dich.dart';
import '../db/models/vi_tien.dart';

class KhoThuChiRepository {
  final SoThuChiDb _db;
  KhoThuChiRepository(this._db);

  Database get db => _db.db;

  Future<List<DanhMuc>> layDanhMuc() async {
    final rows = await db.query("danh_muc", orderBy: "id ASC");
    return rows.map((e) => DanhMuc.fromMap(e)).toList();
  }

  Future<List<ViTien>> layDanhSachVi() async {
    final rows = await db.query("vi_tien", where: "an = 0", orderBy: "id ASC");
    return rows.map((e) => ViTien.fromMap(e)).toList();
  }

  Future<void> suaVi(int id, String ten, String loai, String? icon) async {
    await db.update(
      "vi_tien",
      {"ten": ten, "loai": loai, "icon": icon},
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<void> xoaVi(int id) async {
    await db.update(
      "vi_tien",
      {"an": 1},
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<void> themVi({
    required String ten,
    required String loai,
    required int soDu,
    String? icon,
  }) async {
    await db.insert("vi_tien", {
      "ten": ten,
      "loai": loai,
      "so_du": soDu,
      "icon": icon,
      "an": 0,
    });
  }

  Future<void> capNhatSoDuVi(int viId, int soDuMoi) async {
    await db.update(
      "vi_tien",
      {"so_du": soDuMoi},
      where: "id = ?",
      whereArgs: [viId],
    );
  }

  Future<void> congTienVaoVi(int viId, int soTien) async {
    await db.rawUpdate(
        "UPDATE vi_tien SET so_du = so_du + ? WHERE id = ?", [soTien, viId]);
  }

  Future<void> truTienTuVi(int viId, int soTien) async {
    await db.rawUpdate(
        "UPDATE vi_tien SET so_du = so_du - ? WHERE id = ?", [soTien, viId]);
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
    required int? viTienId,
    required DateTime ngay,
    String? ghiChu,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return await db.transaction((txn) async {
      final id = await txn.insert("giao_dich", {
        "tai_khoan_id": taiKhoanId,
        "so_tien": soTien,
        "danh_muc_id": danhMucId,
        "vi_tien_id": viTienId,
        "ngay": ngay.millisecondsSinceEpoch,
        "ghi_chu": ghiChu,
        "tao_luc": now,
      });

      // Trừ tiền trong ví nếu có chọn ví
      if (viTienId != null) {
        // Lấy số dư hiện tại
        final viRow = await txn.query("vi_tien",
            columns: ["so_du"], where: "id = ?", whereArgs: [viTienId]);
        if (viRow.isNotEmpty) {
          final hienTai = (viRow.first["so_du"] as int?) ?? 0;
          await txn.update(
            "vi_tien",
            {"so_du": hienTai - soTien},
            where: "id = ?",
            whereArgs: [viTienId],
          );
        }
      }
      return id;
    });
  }

  Future<void> suaGiaoDich({
    required int id,
    required int soTienMoi,
    required int danhMucIdMoi,
    required int? viTienIdMoi,
    required DateTime ngayMoi,
    String? ghiChuMoi,
  }) async {
    await db.transaction((txn) async {
      // 1. Lấy giao dịch cũ
      final oldRows =
          await txn.query("giao_dich", where: "id = ?", whereArgs: [id]);
      if (oldRows.isEmpty) return;
      final old = oldRows.first;
      final oldSoTien = old["so_tien"] as int;
      final oldViId = old["vi_tien_id"] as int?;

      // 2. Hoàn lại tiền cho ví cũ (nếu có)
      if (oldViId != null) {
        await txn.rawUpdate(
            "UPDATE vi_tien SET so_du = so_du + ? WHERE id = ?",
            [oldSoTien, oldViId]);
      }

      // 3. Trừ tiền ví mới (nếu có)
      if (viTienIdMoi != null) {
        await txn.rawUpdate(
            "UPDATE vi_tien SET so_du = so_du - ? WHERE id = ?",
            [soTienMoi, viTienIdMoi]);
      }

      // 4. Update giao dịch
      await txn.update(
        "giao_dich",
        {
          "so_tien": soTienMoi,
          "danh_muc_id": danhMucIdMoi,
          "vi_tien_id": viTienIdMoi,
          "ngay": ngayMoi.millisecondsSinceEpoch,
          "ghi_chu": ghiChuMoi,
        },
        where: "id = ?",
        whereArgs: [id],
      );
    });
  }

  Future<void> xoaGiaoDich(int id) async {
    await db.transaction((txn) async {
      final oldRows =
          await txn.query("giao_dich", where: "id = ?", whereArgs: [id]);
      if (oldRows.isEmpty) return;
      final old = oldRows.first;
      final oldSoTien = old["so_tien"] as int;
      final oldViId = old["vi_tien_id"] as int?;

      // Hoàn tiền lại ví
      if (oldViId != null) {
        await txn.rawUpdate(
            "UPDATE vi_tien SET so_du = so_du + ? WHERE id = ?",
            [oldSoTien, oldViId]);
      }

      await txn.delete("giao_dich", where: "id = ?", whereArgs: [id]);
    });
  }

  Future<int> tinhTongChiTrongKhoang({
    required int taiKhoanId,
    required int startMs,
    required int endMs,
    bool chiTuNganSach = false,
  }) async {
    String where = "tai_khoan_id = ? AND ngay >= ? AND ngay < ?";
    List<Object?> args = [taiKhoanId, startMs, endMs];

    if (chiTuNganSach) {
      where += " AND vi_tien_id IS NULL";
    }

    final rows = await db.rawQuery('''
SELECT COALESCE(SUM(so_tien), 0) AS da_chi
FROM giao_dich
WHERE $where;
''', args);

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

  Future<List<Map<String, Object?>>> thongKeTheoDanhMuc({
    required int taiKhoanId,
    required int startMs,
    required int endMs,
  }) async {
    return await db.rawQuery('''
      SELECT d.ten, d.mau, SUM(g.so_tien) as tong_tien
      FROM giao_dich g
      JOIN danh_muc d ON g.danh_muc_id = d.id
      WHERE g.tai_khoan_id = ? AND g.ngay >= ? AND g.ngay < ?
      GROUP BY d.id
    ''', [taiKhoanId, startMs, endMs]);
  }

  Future<List<Map<String, Object?>>> thongKeTheoThoiGian({
    required int taiKhoanId,
    required int nam,
  }) async {
    // Thống kê theo tháng trong năm
    // SQLite strftime('%m', ...) trả về tháng 01-12
    return await db.rawQuery('''
      SELECT strftime('%m', datetime(ngay / 1000, 'unixepoch', 'localtime')) as thang,
             SUM(so_tien) as tong_tien
      FROM giao_dich
      WHERE tai_khoan_id = ? 
        AND ngay >= ? 
        AND ngay < ?
      GROUP BY thang
    ''', [
      taiKhoanId,
      DateTime(nam, 1, 1).millisecondsSinceEpoch,
      DateTime(nam + 1, 1, 1).millisecondsSinceEpoch
    ]);

  }

  Future<int> layTongChiTieuTheoVi(int viId) async {
    final rows = await db.rawQuery(
        "SELECT COALESCE(SUM(so_tien), 0) as da_chi FROM giao_dich WHERE vi_tien_id = ?",
        [viId]);
    return (rows.first["da_chi"] as int?) ?? 0;
  }
}
