import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../be/xu_ly_thu_chi_service.dart';
import '../db/models/giao_dich.dart';
import '../db/models/danh_muc.dart';

class TrangLichSuGhiChep extends StatefulWidget {
  const TrangLichSuGhiChep({
    super.key,
    required this.taiKhoanId,
    required this.service,
  });

  final String taiKhoanId;
  final XuLyThuChiService service;

  @override
  State<TrangLichSuGhiChep> createState() => _TrangLichSuGhiChepState();
}

class _TrangLichSuGhiChepState extends State<TrangLichSuGhiChep> {
  final moneyFmt = NumberFormat.decimalPattern("vi_VN");
  
  DateTime thangDangXem = DateTime(DateTime.now().year, DateTime.now().month, 1);
  List<GiaoDich> dsGiaoDich = [];
  Map<String, DanhMuc> dsDanhMucMap = {};
  Map<String, String> dsViMap = {};
  
  bool loading = true;
  
  int tongThu = 0;
  int tongChi = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    thangDangXem = DateTime(now.year, now.month, 1);
    _taiDuLieu();
  }

  Future<void> _taiDuLieu() async {
    if (mounted) setState(() => loading = true);
    
    try {
      // Tải danh mục
      final listCat = await widget.service.layDanhMuc();
      dsDanhMucMap.clear();
      for (var c in listCat) {
        dsDanhMucMap[c.id] = c;
      }

      // Tải danh sách ví
      dsViMap.clear();
      final listVi = await widget.service.layDanhSachVi();
      for (var v in listVi) {
        dsViMap[v.id] = v.ten;
      }

      // Tải dữ liệu tháng
      final tongQuan = await widget.service.taiDuLieuThang(
        taiKhoanId: widget.taiKhoanId,
        thangDangXem: thangDangXem,
      );

      dsGiaoDich = tongQuan.giaoDich;

      // Tính tổng thu và tổng chi
      tongThu = 0;
      tongChi = 0;
      
      for (var g in dsGiaoDich) {
        final dm = dsDanhMucMap[g.danhMucId];
        if (dm != null) {
          if (dm.loai.toLowerCase() == 'thu') {
            tongThu += g.soTien;
          } else {
            tongChi += g.soTien;
          }
        }
      }

    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _thangTruoc() {
    final y = thangDangXem.year;
    final m = thangDangXem.month;

    setState(() {
      thangDangXem = (m == 1) ? DateTime(y - 1, 12, 1) : DateTime(y, m - 1, 1);
    });

    _taiDuLieu();
  }

  void _thangSau() {
    final y = thangDangXem.year;
    final m = thangDangXem.month;

    setState(() {
      thangDangXem = (m == 12) ? DateTime(y + 1, 1, 1) : DateTime(y, m + 1, 1);
    });

    _taiDuLieu();
  }

  Future<void> _chonThang() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: thangDangXem,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    
    if (picked == null) return;

    setState(() {
      thangDangXem = DateTime(picked.year, picked.month, 1);
    });

    await _taiDuLieu();
  }

  // Nhóm giao dịch theo ngày
  Map<DateTime, List<GiaoDich>> _nhomTheoNgay() {
    final Map<DateTime, List<GiaoDich>> grouped = {};
    
    for (var g in dsGiaoDich) {
      final ngayKey = DateTime(g.ngay.year, g.ngay.month, g.ngay.day);
      grouped.putIfAbsent(ngayKey, () => []).add(g);
    }
    
    return grouped;
  }

  // Tính tổng tiền trong ngày
  int _tongTienTrongNgay(List<GiaoDich> list) {
    int total = 0;
    for (var g in list) {
      total += g.soTien;
    }
    return total;
  }

  // Lấy tên thứ trong tuần
  String _layTenThu(DateTime date) {
    const daysOfWeek = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return daysOfWeek[date.weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    final labelThang = DateFormat("MM/yyyy").format(thangDangXem);
    final grouped = _nhomTheoNgay();
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch sử ghi chép"),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ✅ Header: Tổng thu, Tổng chi, Chọn tháng
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Chọn tháng
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _thangTruoc,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          InkWell(
                            onTap: _chonThang,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month, color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    labelThang,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _thangSau,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Tổng thu và Tổng chi
                      Row(
                        children: [
                          Expanded(
                            child: Card(
                              color: Colors.green.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    const Icon(Icons.arrow_downward, color: Colors.green),
                                    const SizedBox(height: 8),
                                    const Text(
                                      "Tổng thu",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${moneyFmt.format(tongThu)} đ",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Card(
                              color: Colors.red.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    const Icon(Icons.arrow_upward, color: Colors.red),
                                    const SizedBox(height: 8),
                                    const Text(
                                      "Tổng chi",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${moneyFmt.format(tongChi)} đ",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ✅ Danh sách giao dịch theo ngày
                Expanded(
                  child: sortedDates.isEmpty
                      ? Center(
                          child: Text(
                            "Không có giao dịch trong tháng này",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: sortedDates.length,
                          itemBuilder: (context, index) {
                            final ngay = sortedDates[index];
                            final dsGiaoDichNgay = grouped[ngay]!;
                            final tongNgay = _tongTienTrongNgay(dsGiaoDichNgay);
                            final thu = _layTenThu(ngay);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header ngày
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceVariant,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.primary,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                thu,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              DateFormat("dd/MM/yyyy").format(ngay),
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          "${moneyFmt.format(tongNgay)} đ",
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Danh sách giao dịch trong ngày
                                  ...dsGiaoDichNgay.map((g) {
                                    final dm = dsDanhMucMap[g.danhMucId];
                                    final iconCode = dm?.icon ?? 0xe3ac;
                                    final colorVal = dm?.mau ?? 0xFF90A4AE;
                                    final loai = dm?.loai ?? 'chi';

                                    return ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Color(colorVal).withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          IconData(iconCode, fontFamily: 'MaterialIcons'),
                                          color: Color(colorVal),
                                          size: 20,
                                        ),
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              g.tenDanhMuc,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            "${loai.toLowerCase() == 'thu' ? '+' : '-'}${moneyFmt.format(g.soTien)} đ",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: loai.toLowerCase() == 'thu'
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (g.ghiChu != null && g.ghiChu!.isNotEmpty)
                                            Text(
                                              g.ghiChu!,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          if (g.viTienId != null)
                                            Text(
                                              "Nguồn: ${dsViMap[g.viTienId] ?? 'Ví'}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.green[700],
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}