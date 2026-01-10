import 'package:flutter/material.dart';

import '../be/phien_dang_nhap.dart';
import '../be/xu_ly_thu_chi_service.dart';
import '../be/kho_tai_khoan_repository.dart';
import '../be/theme_service.dart';
import 'trang_tong_quan_page.dart';
import 'trang_vi_tien_page.dart';
import 'trang_thong_ke_page.dart';
import 'them_khoan_chi_page.dart';
import 'tai_khoan_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.taiKhoanId,
    required this.thuChiService,
    required this.phien,
    required this.khoTaiKhoanRepo,
    required this.onLogout,
    required this.themeService,
  });

  final String taiKhoanId;
  final XuLyThuChiService thuChiService;
  final PhienDangNhap phien;
  final KhoTaiKhoanRepository khoTaiKhoanRepo;
  final VoidCallback onLogout;
  final ThemeService themeService;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  final GlobalKey<TrangTongQuanPageState> _tongQuanKey =
      GlobalKey<TrangTongQuanPageState>();
  final GlobalKey<TrangViTienPageState> _viTienKey =
      GlobalKey<TrangViTienPageState>();

  Future<void> _moTrangThemKhoanChi({required bool isIncome}) async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ThemKhoanChiPage(
          taiKhoanId: widget.taiKhoanId,
          service: widget.thuChiService,
          isIncome: isIncome,
        ),
      ),
    );

    if (added == true) {
      setState(() => index = 0);
      _tongQuanKey.currentState?.taiLai();
      _viTienKey.currentState?.taiLai();
    }
  }

  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.remove_circle, color: Colors.red, size: 30),
                  title: const Text('Thêm khoản chi', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Ghi chép chi tiêu'),
                  onTap: () {
                    Navigator.pop(context);
                    _moTrangThemKhoanChi(isIncome: false);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_circle, color: Colors.green, size: 30),
                  title: const Text('Thêm khoản thu', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Ghi chép thu nhập'),
                  onTap: () {
                    Navigator.pop(context);
                    _moTrangThemKhoanChi(isIncome: true);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _refreshAllData() {
    _tongQuanKey.currentState?.taiLai();
    _viTienKey.currentState?.taiLai();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      TrangTongQuanPage(
        key: _tongQuanKey,
        taiKhoanId: widget.taiKhoanId,
        service: widget.thuChiService,
        repo: widget.khoTaiKhoanRepo,
        onRefresh: _refreshAllData,
      ),
      TrangViTienPage(
        key: _viTienKey,
        taiKhoanId: widget.taiKhoanId,
        service: widget.thuChiService,
        onRefresh: _refreshAllData,
      ),
      TrangThongKePage(
        taiKhoanId: widget.taiKhoanId,
        service: widget.thuChiService,
      ),
      TaiKhoanPage(
        taiKhoanId: widget.taiKhoanId,
        phien: widget.phien,
        khoTaiKhoanRepo: widget.khoTaiKhoanRepo,
        service: widget.thuChiService,
        onLogout: widget.onLogout,
        themeService: widget.themeService,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: index, children: pages),

      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMenu,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              Expanded(
                child: IconButton(
                  onPressed: () {
                    setState(() => index = 0);
                    _tongQuanKey.currentState?.taiLai();
                  },
                  icon: Icon(
                    Icons.home_rounded,
                    color: index == 0
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: IconButton(
                  onPressed: () {
                    setState(() => index = 1);
                    // Refresh khi switch qua tab ví
                    _viTienKey.currentState?.taiLai();
                  },
                  icon: Icon(
                    Icons.account_balance_wallet,
                    color: index == 1
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
              ),
              const Expanded(child: SizedBox()),
              Expanded(
                child: IconButton(
                  onPressed: () => setState(() => index = 2),
                  icon: Icon(
                    Icons.pie_chart,
                    color: index == 2
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: IconButton(
                  onPressed: () => setState(() => index = 3),
                  icon: Icon(
                    Icons.person_rounded,
                    color: index == 3
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
