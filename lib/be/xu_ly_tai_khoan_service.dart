import 'package:firebase_auth/firebase_auth.dart';

import '../db/models/tai_khoan.dart';
import 'kho_tai_khoan_repository.dart';
import 'phien_dang_nhap.dart';

class XuLyTaiKhoanService {
  final KhoTaiKhoanRepository _repo;

  XuLyTaiKhoanService(this._repo);

  /// ✅ Đăng ký:
  /// - FirebaseAuth tự login sau khi tạo user
  /// - Nếu em muốn đăng ký xong QUAY VỀ màn login => keep autoSignOut = true
  Future<TaiKhoan> dangKy({
    required String email,
    required String matKhau,
    required PhienDangNhap phien,
    bool autoSignOut = true,
  }) async {
    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: matKhau,
    );

    final user = cred.user!;
    final uid = user.uid;

    // ✅ giúp RTDB nhận auth token ngay
    await user.getIdToken(true);

    // tạo/đảm bảo hồ sơ
    await _repo.upsertHoSo(uid: uid, email: email.trim());
    await phien.dangNhap(uid);

    final tk = TaiKhoan(id: uid, email: email.trim());

    // ✅ nếu muốn quay về đăng nhập
    if (autoSignOut) {
      await FirebaseAuth.instance.signOut();
      await phien.dangXuat();
    }

    return tk;
  }

  Future<TaiKhoan> dangNhap({
    required String email,
    required String matKhau,
    required PhienDangNhap phien,
  }) async {
    final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: matKhau,
    );

    final user = cred.user!;
    final uid = user.uid;

    await user.getIdToken(true);

    // đảm bảo có hồ sơ
    await _repo.upsertHoSo(uid: uid, email: email.trim());
    await phien.dangNhap(uid);

    return TaiKhoan(id: uid, email: email.trim());
  }

  Future<void> dangXuat(PhienDangNhap phien) async {
    await FirebaseAuth.instance.signOut();
    await phien.dangXuat();
  }
}
