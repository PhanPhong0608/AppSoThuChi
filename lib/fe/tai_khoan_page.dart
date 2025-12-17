import 'package:flutter/material.dart';

import '../be/phien_dang_nhap.dart';
import '../be/kho_tai_khoan_repository.dart';

class TaiKhoanPage extends StatefulWidget {
  const TaiKhoanPage({
    super.key,
    required this.taiKhoanId,
    required this.phien,
    required this.khoTaiKhoanRepo,
    required this.onLogout,
  });

  final int taiKhoanId;
  final PhienDangNhap phien;
  final KhoTaiKhoanRepository khoTaiKhoanRepo;
  final VoidCallback onLogout;

  @override
  State<TaiKhoanPage> createState() => _TaiKhoanPageState();
}

class _TaiKhoanPageState extends State<TaiKhoanPage> {
  String? email;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tk = await widget.khoTaiKhoanRepo.timTheoId(widget.taiKhoanId);
    setState(() {
      email = tk?.email;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tài khoản")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_rounded),
                    title: const Text("Email"),
                    subtitle: Text(email ?? "(không rõ)"),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text("Đăng xuất"),
                    onTap: () async {
                      await widget.phien.dangXuat();
                      widget.onLogout();
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
