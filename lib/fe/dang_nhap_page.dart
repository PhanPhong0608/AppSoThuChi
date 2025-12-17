import 'package:flutter/material.dart';

import '../be/phien_dang_nhap.dart';
import '../be/xu_ly_tai_khoan_service.dart';
import 'dang_ky_page.dart';

class DangNhapPage extends StatefulWidget {
  const DangNhapPage({
    super.key,
    required this.phien,
    required this.tkService,
    required this.onLoggedIn,
  });

  final PhienDangNhap phien;
  final XuLyTaiKhoanService tkService;
  final ValueChanged<int> onLoggedIn;

  @override
  State<DangNhapPage> createState() => _DangNhapPageState();
}

class _DangNhapPageState extends State<DangNhapPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _dangNhap() async {
    setState(() => loading = true);
    try {
      final id = await widget.tkService.dangNhap(
        email: emailCtrl.text,
        matKhau: passCtrl.text,
      );
      await widget.phien.luuUserId(id);
      widget.onLoggedIn(id);
    } catch (e) {
      _toast(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng nhập")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: "Mật khẩu", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: loading ? null : _dangNhap,
            child: loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator()) : const Text("Đăng nhập"),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DangKyPage(tkService: widget.tkService)),
              );
            },
            child: const Text("Chưa có tài khoản? Đăng ký"),
          )
        ],
      ),
    );
  }
}
