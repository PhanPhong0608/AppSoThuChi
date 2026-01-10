import 'package:firebase_database/firebase_database.dart';

import '../db/models/tai_khoan.dart';

/// Repository chỉ làm việc với **hồ sơ** user trong Realtime Database.
///
/// Authentication (đăng ký/đăng nhập) sẽ do FirebaseAuth xử lý.
class KhoTaiKhoanRepository {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref();

  DatabaseReference _userRef(String uid) => _ref.child('users').child(uid);

  /// Tạo/cập nhật hồ sơ cơ bản cho user.
  ///
  /// Không lưu password/salt/hash trong DB nữa.
  Future<void> upsertHoSo({required String uid, required String email}) async {
    await _userRef(uid).update({
      'email': email,
      'tao_luc': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<TaiKhoan?> layTheoId(String uid) async {
    final snap = await _userRef(uid).get();
    if (!snap.exists || snap.value == null) return null;

    final data = Map<String, Object?>.from(snap.value as Map);
    // đảm bảo có id
    data['id'] = uid;
    return TaiKhoan.fromMap(data);
  }

  Future<void> capNhatChuoiLua({
    required String uid,
    required int chuoiLua,
    required int ngayHoatDongCuoiMs,
  }) async {
    await _userRef(uid).update({
      'chuoi_lua': chuoiLua,
      'ngay_hoat_dong_cuoi': ngayHoatDongCuoiMs,
    });
  }

  Future<void> capNhatThongTin({
    required String uid,
    required String ten,
    required String sdt,
  }) async {
    await _userRef(uid).update({
      'ten': ten,
      'sdt': sdt,
    });
  }
}
