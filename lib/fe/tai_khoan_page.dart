import 'package:flutter/material.dart';
import '../be/phien_dang_nhap.dart';
import '../be/kho_tai_khoan_repository.dart';
import '../be/xu_ly_thu_chi_service.dart';
import 'dang_nhap_page.dart';
import 'trang_quan_ly_danh_muc.dart';

class TaiKhoanPage extends StatefulWidget {
  const TaiKhoanPage({
    super.key,
    required this.taiKhoanId,
    required this.phien,
    required this.khoTaiKhoanRepo,
    required this.service,
    required this.onLogout,
  });

  final String taiKhoanId;
  final PhienDangNhap phien;
  final KhoTaiKhoanRepository khoTaiKhoanRepo;
  final XuLyThuChiService service;
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
    final tk = await widget.khoTaiKhoanRepo.layTheoId(widget.taiKhoanId);
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
                  child: Column( // Wrap multiple ListTiles in a Column
                    children: [
                      ListTile(
                        leading: const Icon(Icons.category, color: Colors.orange),
                        title: const Text("Quản lý danh mục"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TrangQuanLyDanhMuc(service: widget.service),
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text("Đăng xuất"),
                        onTap: () async {
                          await widget.phien.dangXuat();
                          widget.onLogout();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
