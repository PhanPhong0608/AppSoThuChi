import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import '../db/models/tai_khoan.dart';
import 'kho_tai_khoan_repository.dart';
import 'phien_dang_nhap.dart';

class XuLyTaiKhoanService {
  final KhoTaiKhoanRepository _repo;

  XuLyTaiKhoanService(this._repo);

  /// ✅ Đăng ký Email/Password
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

    await user.getIdToken(true);

    await _repo.upsertHoSo(uid: uid, email: email.trim());
    await phien.dangNhap(uid);

    final tk = TaiKhoan(id: uid, email: email.trim());

    if (autoSignOut) {
      await FirebaseAuth.instance.signOut();
      await phien.dangXuat();
    }

    return tk;
  }

  /// ✅ Đăng nhập Email/Password
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

    await _repo.upsertHoSo(uid: uid, email: email.trim());
    await phien.dangNhap(uid);

    return TaiKhoan(id: uid, email: email.trim());
  }

  /// ✅ Đăng nhập Google (Version 6.x - đơn giản)
  Future<TaiKhoan> dangNhapGoogle({
    required PhienDangNhap phien,
  }) async {
    final auth = FirebaseAuth.instance;

    if (kIsWeb) {
      // WEB
      final provider = GoogleAuthProvider();
      final cred = await auth.signInWithPopup(provider);

      final user = cred.user!;
      final uid = user.uid;
      final email = (user.email ?? '').trim();

      await user.getIdToken(true);
      await _repo.upsertHoSo(uid: uid, email: email);
      await phien.dangNhap(uid);

      return TaiKhoan(id: uid, email: email);
    }

    // ANDROID/iOS - Version 6.x API (đơn giản)
    final googleSignIn = GoogleSignIn(
      scopes: ['email'],
    );

    final googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      throw Exception('Người dùng đã hủy đăng nhập Google.');
    }

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCred = await auth.signInWithCredential(credential);

    final user = userCred.user!;
    final uid = user.uid;
    final email = (user.email ?? googleUser.email).trim();

    await user.getIdToken(true);

    await _repo.upsertHoSo(uid: uid, email: email);
    await phien.dangNhap(uid);

    return TaiKhoan(id: uid, email: email);
  }

  /// ✅ Đăng xuất (thoát cả Google + Firebase)
  Future<void> dangXuat(PhienDangNhap phien) async {
    if (!kIsWeb) {
      try {
        final googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
      } catch (_) {}
    }
    await FirebaseAuth.instance.signOut();
    await phien.dangXuat();
  }
}