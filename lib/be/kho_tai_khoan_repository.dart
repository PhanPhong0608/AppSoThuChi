import 'package:sqflite/sqflite.dart';

import '../db/so_thu_chi_db.dart';
import '../db/models/tai_khoan.dart';

class KhoTaiKhoanRepository {
  final SoThuChiDb _db;
  KhoTaiKhoanRepository(this._db);

  Database get db => _db.db;

  Future<TaiKhoan?> timTheoEmail(String email) async {
    final rows = await db.query(
      "tai_khoan",
      columns: ["id", "email"],
      where: "email = ?",
      whereArgs: [email],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TaiKhoan.fromMap(rows.first);
  }

  Future<TaiKhoan?> timTheoId(int id) async {
    final rows = await db.query(
      "tai_khoan",
      columns: ["id", "email"],
      where: "id = ?",
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TaiKhoan.fromMap(rows.first);
  }

  Future<Map<String, Object?>?> layRowTheoEmail(String email) async {
    final rows = await db.query(
      "tai_khoan",
      where: "email = ?",
      whereArgs: [email],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<int> taoTaiKhoan({
    required String email,
    required String matKhauHash,
    required String salt,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.insert("tai_khoan", {
      "email": email,
      "mat_khau_hash": matKhauHash,
      "salt": salt,
      "tao_luc": now,
    });
  }
}
