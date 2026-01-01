import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../be/kho_tai_khoan_repository.dart';
import '../be/phien_dang_nhap.dart';
import '../be/xu_ly_tai_khoan_service.dart';
import '../be/xu_ly_thu_chi_service.dart';
import 'app_shell.dart';
import 'dang_nhap_page.dart';

/// Cổng điều hướng theo trạng thái đăng nhập:
/// - Chưa đăng nhập -> DangNhapPage
/// - Đã đăng nhập -> AppShell
class AuthGate extends StatefulWidget {
  final PhienDangNhap phien;
  final XuLyTaiKhoanService tkService;
  final XuLyThuChiService thuChiService;
  final KhoTaiKhoanRepository khoTaiKhoanRepo;

  const AuthGate({
    super.key,
    required this.phien,
    required this.tkService,
    required this.thuChiService,
    required this.khoTaiKhoanRepo,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _uid;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();

    // Đồng bộ theo FirebaseAuth để tránh lệch trạng thái.
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      final uid = user?.uid;
      if (!mounted) return;

      if (uid == null) {
        await widget.phien.dangXuat();
        setState(() => _uid = null);
      } else {
        await widget.phien.luuUserId(uid);
        setState(() => _uid = uid);
      }
    });
  }

  Future<void> _init() async {
    final uid = await widget.phien.layUserId();
    if (!mounted) return;
    setState(() {
      _uid = uid;
      _loading = false;
    });
  }

  Future<void> _onLoggedIn(String uid) async {
    await widget.phien.luuUserId(uid);

    // Seed dữ liệu mặc định để app có danh mục + ví ban đầu.
    await widget.thuChiService.seedDefaultCategories();
    await widget.thuChiService.seedDefaultWallets();

    if (!mounted) return;
    setState(() => _uid = uid);
  }

  Future<void> _onLogout() async {
    await FirebaseAuth.instance.signOut();
    await widget.phien.dangXuat();
    if (!mounted) return;
    setState(() => _uid = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_uid == null) {
      return DangNhapPage(
        phien: widget.phien,
        tkService: widget.tkService,
        onLoggedIn: _onLoggedIn,
      );
    }

    return AppShell(
      taiKhoanId: _uid!,
      thuChiService: widget.thuChiService,
      phien: widget.phien,
      khoTaiKhoanRepo: widget.khoTaiKhoanRepo,
      onLogout: _onLogout,
    );
  }
}
