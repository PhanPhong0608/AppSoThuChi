import 'package:flutter/material.dart';
import '../be/phien_dang_nhap.dart';
import '../be/kho_tai_khoan_repository.dart';
import '../be/xu_ly_thu_chi_service.dart';

import 'trang_quan_ly_danh_muc.dart';
import 'trang_cai_dat.dart';
import '../be/theme_service.dart';

class TaiKhoanPage extends StatefulWidget {
  const TaiKhoanPage({
    super.key,
    required this.taiKhoanId,
    required this.phien,
    required this.khoTaiKhoanRepo,
    required this.service,
    required this.onLogout,
    required this.themeService,
  });

  final String taiKhoanId;
  final PhienDangNhap phien;
  final KhoTaiKhoanRepository khoTaiKhoanRepo;
  final XuLyThuChiService service;
  final VoidCallback onLogout;
  final ThemeService themeService;

  @override
  State<TaiKhoanPage> createState() => _TaiKhoanPageState();
}

class _TaiKhoanPageState extends State<TaiKhoanPage> {
  String? email;
  final _tenCtrl = TextEditingController();
  final _sdtCtrl = TextEditingController();
  
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
      _tenCtrl.text = tk?.ten ?? "";
      _sdtCtrl.text = tk?.sdt ?? "";
      loading = false;
    });
  }

  @override
  void dispose() {
    _tenCtrl.dispose();
    _sdtCtrl.dispose();
    super.dispose();
  }

  Future<void> _luu() async {
    setState(() => loading = true);
    await widget.khoTaiKhoanRepo.capNhatThongTin(
        uid: widget.taiKhoanId, ten: _tenCtrl.text, sdt: _sdtCtrl.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cập nhật thông tin thành công"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => loading = false);
    }
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
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.email),
                          title: const Text("Email"),
                          subtitle: Text(email ?? "(không rõ)"),
                        ),
                        const Divider(),
                        TextField(
                          controller: _tenCtrl,
                          decoration: const InputDecoration(
                            labelText: "Tên hiển thị",
                            prefixIcon: Icon(Icons.badge),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _sdtCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: "Số điện thoại",
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _luu,
                            label: const Text("Lưu thay đổi"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 12),
                Card(
                  child: Column( 
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
                        leading: const Icon(Icons.settings, color: Colors.blue),
                        title: const Text("Cài đặt"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TrangCaiDat(themeService: widget.themeService),
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
