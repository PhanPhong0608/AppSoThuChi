import 'package:flutter/material.dart';
import '../be/xu_ly_tai_khoan_service.dart';

class DangKyPage extends StatefulWidget {
  const DangKyPage({super.key, required this.tkService});
  final XuLyTaiKhoanService tkService;

  @override
  State<DangKyPage> createState() => _DangKyPageState();
}

class _DangKyPageState extends State<DangKyPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final pass2Ctrl = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    pass2Ctrl.dispose();
    super.dispose();
  }

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _dangKy() async {
    if (passCtrl.text != pass2Ctrl.text) {
      _toast("Mật khẩu nhập lại không khớp.");
      return;
    }

    setState(() => loading = true);
    try {
      await widget.tkService.dangKy(email: emailCtrl.text, matKhau: passCtrl.text);
      if (mounted) {
        _toast("Đăng ký thành công. Vui lòng đăng nhập.");
        Navigator.pop(context);
      }
    } catch (e) {
      _toast(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng ký")),
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
            decoration: const InputDecoration(labelText: "Mật khẩu (>= 6 ký tự)", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: pass2Ctrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: "Nhập lại mật khẩu", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: loading ? null : _dangKy,
            child: loading ? const CircularProgressIndicator() : const Text("Tạo tài khoản"),
          ),
        ],
      ),
    );
  }
}
