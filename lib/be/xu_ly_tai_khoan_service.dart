import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

import 'kho_tai_khoan_repository.dart';

class XuLyTaiKhoanService {
  final KhoTaiKhoanRepository repo;
  XuLyTaiKhoanService(this.repo);

  String _taoSalt() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hash(String matKhau, String salt) {
    return sha256.convert(utf8.encode("$salt:$matKhau")).toString();
  }

  Future<int> dangKy({required String email, required String matKhau}) async {
    email = email.trim().toLowerCase();
    if (email.isEmpty || !email.contains("@")) throw Exception("Email không hợp lệ.");
    if (matKhau.length < 6) throw Exception("Mật khẩu phải từ 6 ký tự.");

    final existed = await repo.timTheoEmail(email);
    if (existed != null) throw Exception("Email đã tồn tại.");

    final salt = _taoSalt();
    final hash = _hash(matKhau, salt);
    return repo.taoTaiKhoan(email: email, matKhauHash: hash, salt: salt);
  }

  Future<int> dangNhap({required String email, required String matKhau}) async {
    email = email.trim().toLowerCase();
    final row = await repo.layRowTheoEmail(email);
    if (row == null) throw Exception("Sai email hoặc mật khẩu.");

    final salt = row["salt"] as String;
    final hashDb = row["mat_khau_hash"] as String;
    final hashInput = _hash(matKhau, salt);

    if (hashInput != hashDb) throw Exception("Sai email hoặc mật khẩu.");
    return row["id"] as int;
  }
}
