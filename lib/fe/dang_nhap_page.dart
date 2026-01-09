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
  final ValueChanged<String> onLoggedIn;

  @override
  State<DangNhapPage> createState() => _DangNhapPageState();
}

class _DangNhapPageState extends State<DangNhapPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool loadingEmail = false;
  bool loadingGoogle = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _dangNhapEmail() async {
    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');

    if (emailCtrl.text.trim().isEmpty ||
        !emailRegex.hasMatch(emailCtrl.text.trim())) {
      _toast("Email không hợp lệ.");
      return;
    }

    if (passCtrl.text.isEmpty) {
      _toast("Vui lòng nhập mật khẩu.");
      return;
    }

    setState(() => loadingEmail = true);
    try {
      final tk = await widget.tkService.dangNhap(
        email: emailCtrl.text,
        matKhau: passCtrl.text,
        phien: widget.phien,
      );

      widget.onLoggedIn(tk.id);
    } catch (e) {
      if (mounted) _toast(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => loadingEmail = false);
    }
  }

  Future<void> _dangNhapGoogle() async {
    setState(() => loadingGoogle = true);
    try {
      final tk = await widget.tkService.dangNhapGoogle(
        phien: widget.phien,
      );

      widget.onLoggedIn(tk.id);
    } catch (e) {
      final msg = e.toString().replaceFirst("Exception: ", "");
      if (mounted) _toast(msg);
    } finally {
      if (mounted) setState(() => loadingGoogle = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabledAll = loadingEmail || loadingGoogle;

    return Scaffold(
      appBar: AppBar(title: const Text("Đăng nhập")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: "Email",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Mật khẩu",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // ✅ Đăng nhập Email/Password
          FilledButton(
            onPressed: disabledAll ? null : _dangNhapEmail,
            child: loadingEmail
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Đăng nhập"),
          ),

          const SizedBox(height: 10),

          // ✅ Đăng nhập Google
          OutlinedButton.icon(
            onPressed: disabledAll ? null : _dangNhapGoogle,
            icon: loadingGoogle
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.g_mobiledata),
            label: Text(loadingGoogle ? "Đang đăng nhập..." : "Đăng nhập bằng Google"),
          ),

          const SizedBox(height: 8),
          TextButton(
            onPressed: disabledAll
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DangKyPage(
                          tkService: widget.tkService,
                          phien: widget.phien,
                        ),
                      ),
                    );
                  },
            child: const Text("Chưa có tài khoản? Đăng ký"),
          )
        ],
      ),
    );
  }
}
