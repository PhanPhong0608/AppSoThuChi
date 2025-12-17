import 'package:flutter/material.dart';

import '../be/phien_dang_nhap.dart';
import '../be/xu_ly_tai_khoan_service.dart';
import '../be/xu_ly_thu_chi_service.dart';
import '../be/kho_tai_khoan_repository.dart';
import 'dang_nhap_page.dart';
import 'app_shell.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.phien,
    required this.tkService,
    required this.thuChiService,
    required this.khoTaiKhoanRepo,
  });

  final PhienDangNhap phien;
  final XuLyTaiKhoanService tkService;
  final XuLyThuChiService thuChiService;
  final KhoTaiKhoanRepository khoTaiKhoanRepo;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  int? userId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    userId = await widget.phien.layUserId();
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (userId == null) {
      return DangNhapPage(
        phien: widget.phien,
        tkService: widget.tkService,
        onLoggedIn: (id) => setState(() => userId = id),
      );
    }

    return AppShell(
      taiKhoanId: userId!,
      thuChiService: widget.thuChiService,
      phien: widget.phien,
      khoTaiKhoanRepo: widget.khoTaiKhoanRepo,
      onLogout: () => setState(() => userId = null),
    );
  }
}
