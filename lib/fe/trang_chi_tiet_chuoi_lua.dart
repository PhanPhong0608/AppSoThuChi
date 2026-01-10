import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../be/xu_ly_thu_chi_service.dart';
import '../be/kho_tai_khoan_repository.dart';

class TrangChiTietChuoiLua extends StatefulWidget {
  const TrangChiTietChuoiLua({
    super.key,
    required this.taiKhoanId,
    required this.service,
    required this.repo,
  });

  final String taiKhoanId;
  final XuLyThuChiService service;
  final KhoTaiKhoanRepository repo;

  @override
  State<TrangChiTietChuoiLua> createState() => _TrangChiTietChuoiLuaState();
}

class _TrangChiTietChuoiLuaState extends State<TrangChiTietChuoiLua> {
  bool loading = true;
  int streak = 0;
  DateTime? lastActive;
  int todayTxCount = 0;
  bool laNgayMoi = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final user = await widget.repo.layTheoId(widget.taiKhoanId);
      final rawTx = await widget.service.layGiaoDichTrongKhoang(
        userId: widget.taiKhoanId,
        startMs: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).millisecondsSinceEpoch,
        endMs: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).add(const Duration(days: 1)).millisecondsSinceEpoch,
      );

      streak = user?.chuoiLua ?? 0;
      if (user?.ngayHoatDongCuoiMs != null) {
        lastActive = DateTime.fromMillisecondsSinceEpoch(user!.ngayHoatDongCuoiMs!);
      }
      todayTxCount = rawTx.length;

      final now = DateTime.now();
      if (lastActive != null) {
        laNgayMoi = lastActive!.year == now.year &&
            lastActive!.month == now.month &&
            lastActive!.day == now.day;
      } else {
        laNgayMoi = false;
      }
    } catch (e) {
      debugPrint("Error loading streak details: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _checkIn() async {
    setState(() => loading = true);
    await widget.service.checkInHangNgay();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chi tiết chuỗi lửa")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      size: 120,
                      color: laNgayMoi ? Colors.orange : Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "$streak ngày",
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: laNgayMoi ? Colors.orange : Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      laNgayMoi
                          ? "Bạn đã duy trì chuỗi lửa hôm nay! 🔥"
                          : "Bạn chưa check-in hôm nay.",
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            ListTile(
                              title: const Text("Hoạt động gần nhất"),
                              subtitle: Text(lastActive != null
                                  ? DateFormat("dd/MM/yyyy")
                                      .format(lastActive!)
                                  : "Chưa có"),
                              leading: const Icon(Icons.history),
                            ),
                            const Divider(),
                            ListTile(
                              title: const Text("Giao dịch hôm nay"),
                              subtitle: Text("$todayTxCount giao dịch"),
                              leading: const Icon(Icons.receipt_long),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (!laNgayMoi)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: _checkIn,
                          icon: const Icon(Icons.check_circle),
                          label: const Text("Check-in ngay!"),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                        ),
                      ),
                    if (laNgayMoi)
                      const Text(
                        "Tuyệt vời! Hãy quay lại vào ngày mai nhé.",
                        style: TextStyle(color: Colors.green, fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
