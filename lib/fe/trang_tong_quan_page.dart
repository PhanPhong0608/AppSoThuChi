import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../be/xu_ly_thu_chi_service.dart';
import '../be/kho_tai_khoan_repository.dart';
import '../be/tong_quan_thang.dart';
import '../db/models/giao_dich.dart';
import '../db/models/danh_muc.dart';
import '../db/models/vi_tien.dart';
import 'widgets/the_tong_quan_thang.dart';
import 'trang_chi_tiet_chuoi_lua.dart';
import 'trang_lich_su_ghi_chep.dart';
import 'trang_sua_giao_dich.dart';

class TrangTongQuanPage extends StatefulWidget {
  const TrangTongQuanPage({
    super.key,
    required this.taiKhoanId,
    required this.service,
    required this.repo,
    this.onRefresh,
  });

  final String taiKhoanId;
  final XuLyThuChiService service;
  final KhoTaiKhoanRepository repo;
  final VoidCallback? onRefresh;

  @override
  State<TrangTongQuanPage> createState() => TrangTongQuanPageState();
}

class TrangTongQuanPageState extends State<TrangTongQuanPage> {
  final moneyFmt = NumberFormat.decimalPattern("vi_VN");
  final ScrollController _dsGiaoDichCtrl = ScrollController();

  DateTime thangDangXem = DateTime(DateTime.now().year, DateTime.now().month, 1);
  TongQuanThang? tongQuan;
  String? userName;
  int streak = 0;
  bool laNgayMoi = false;
  bool loading = true;

  DateTime? ngayLoc;

  final Map<String, String> dsViMap = {};
  final Map<String, DanhMuc> dsDanhMucMap = {};

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    thangDangXem = DateTime(now.year, now.month, 1);
    ngayLoc = DateTime(now.year, now.month, now.day);

    _taiDuLieu();
  }

  @override
  void dispose() {
    _dsGiaoDichCtrl.dispose();
    super.dispose();
  }

  bool _cungNgay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _taiDuLieu() async {
    if (mounted) setState(() => loading = true);
    try {
      dsViMap.clear();
      final listVi = await widget.service.layDanhSachVi();
      for (var v in listVi) {
        dsViMap[v.id] = v.ten;
      }

      final listCat = await widget.service.layDanhMuc();
      dsDanhMucMap.clear();
      for (var c in listCat) {
        dsDanhMucMap[c.id] = c;
      }

      tongQuan = await widget.service.taiDuLieuThang(
        taiKhoanId: widget.taiKhoanId,
        thangDangXem: thangDangXem,
      );

      final user = await widget.repo.layTheoId(widget.taiKhoanId);
      userName = user?.ten ?? user?.email;
      streak = user?.chuoiLua ?? 0;

      final lastMs = user?.ngayHoatDongCuoiMs;
      if (lastMs != null) {
        final lastDate = DateTime.fromMillisecondsSinceEpoch(lastMs);
        final now = DateTime.now();
        laNgayMoi = _cungNgay(lastDate, now);
      } else {
        laNgayMoi = false;
      }
    } catch (e, st) {
      debugPrint('TrangTongQuanPage: error _taiDuLieu: $e\n$st');
      tongQuan = null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> taiLai() => _taiDuLieu();

  void _thangTruoc() {
    final y = thangDangXem.year;
    final m = thangDangXem.month;

    setState(() {
      thangDangXem = (m == 1) ? DateTime(y - 1, 12, 1) : DateTime(y, m - 1, 1);
      ngayLoc = null;
    });

    taiLai();
  }

  void _thangSau() {
    final y = thangDangXem.year;
    final m = thangDangXem.month;

    setState(() {
      thangDangXem = (m == 12) ? DateTime(y + 1, 1, 1) : DateTime(y, m + 1, 1);
      ngayLoc = null;
    });

    taiLai();
  }



  Future<void> _chonNgayLoc() async {
    final now = DateTime.now();
    final init = ngayLoc ?? DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked == null) return;

    final pickedDay = DateTime(picked.year, picked.month, picked.day);
    final pickedMonth = DateTime(picked.year, picked.month, 1);

    setState(() {
      ngayLoc = pickedDay;
      thangDangXem = pickedMonth;
    });

    await taiLai();
  }

  void _boLocNgay() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    setState(() {
      thangDangXem = DateTime(now.year, now.month, 1);
      ngayLoc = today;
    });

    await taiLai();
  }

  Future<void> _xoaGiaoDich(GiaoDich g) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xóa giao dịch"),
        content: const Text("Bạn có chắc chắn muốn xóa không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.service.xoaGiaoDich(g.id);
      if (mounted) {
        await taiLai();
        widget.onRefresh?.call();
      }
    }
  }

  Future<void> _suaGiaoDich(GiaoDich g) async {
    final nav = Navigator.of(context);

    final dsVi = await widget.service.layDanhSachVi();

    final List<DanhMuc> danhMucRaw = await widget.service.layDanhMuc();
    final uniq = <String, DanhMuc>{};
    for (final dm in danhMucRaw) {
      final k =
          '${dm.ten.trim().toLowerCase()}|${dm.loai.trim().toLowerCase()}';
      uniq.putIfAbsent(k, () => dm);
    }
    final danhMuc = uniq.values.toList()
      ..sort((a, b) => a.ten.compareTo(b.ten));

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogCtx) => TrangSuaGiaoDich(
        giaoDich: g,
        dsVi: dsVi,
        dsDanhMuc: danhMuc,
        onSave: (amt, dm, vi, ngay, note) async {
          await widget.service.suaGiaoDich(
            id: g.id,
            soTien: amt,
            danhMucId: dm,
            viTienId: vi,
            ngay: ngay,
            ghiChu: note,
          );

          if (nav.canPop()) nav.pop();

          if (!mounted) return;
          await taiLai();
          widget.onRefresh?.call();
        },
      ),
    );
  }

  void _xemTatCaGiaoDich() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrangLichSuGhiChep(
          taiKhoanId: widget.taiKhoanId,
          service: widget.service,
        ),
      ),
    );
    if (mounted) {
      await taiLai();
      widget.onRefresh?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelThang = DateFormat("MM/yyyy").format(thangDangXem);
    final t = tongQuan;

    final dsHienThi = (t?.giaoDich ?? []).where((g) {
      if (ngayLoc == null) return true;
      return _cungNgay(g.ngay, ngayLoc!);
    }).toList();

    final dsGanDay = [...(t?.giaoDich ?? [])]
      ..sort((a, b) => b.ngay.compareTo(a.ngay));
    final top3GanDay = dsGanDay.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage('assets/images/appthuchi.png'),
              backgroundColor: Colors.transparent,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Xin chào,",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  userName ?? "Người dùng",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TrangChiTietChuoiLua(
                    taiKhoanId: widget.taiKhoanId,
                    service: widget.service,
                    repo: widget.repo,
                  ),
                ),
              );
              if (mounted) _taiDuLieu();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: laNgayMoi ? Colors.orange.shade50 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      laNgayMoi ? Colors.orange.shade200 : Colors.grey.shade400,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: laNgayMoi ? Colors.orange : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "$streak",
                    style: TextStyle(
                      color: laNgayMoi ? Colors.orange : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ✅ Card tổng quan tháng
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: TheTongQuanThang(
                        monthLabel: labelThang,
                        tongSoDuVi: t?.tongSoDuVi ?? 0,
                        daChi: t?.daChi ?? 0,
                        moneyFmt: moneyFmt,
                        onPrev: _thangTruoc,
                        onNext: _thangSau,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ✅ Phần "Ghi chép gần đây"
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Ghi chép gần đây",
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              TextButton(
                                onPressed: _xemTatCaGiaoDich,
                                child: const Text("Xem tất cả"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          if (top3GanDay.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  "Chưa có ghi chép nào",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.grey),
                                ),
                              ),
                            )
                          else
                            ...top3GanDay.map((g) {
                              final dm = dsDanhMucMap[g.danhMucId];
                              final iconCode = dm?.icon ?? 0xe3ac;
                              final colorVal = dm?.mau ?? 0xFF90A4AE;
                              final loai = dm?.loai.toLowerCase() ?? 'chi';
                              final isThu = loai == 'thu' || loai == 'income' || loai == 'adjustment';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Color(colorVal).withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      IconData(iconCode,
                                          fontFamily: 'MaterialIcons'),
                                      color: Color(colorVal),
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    "${g.tenDanhMuc} • ${isThu ? (g.soTien >= 0 ? '+' : '') : '-'}${moneyFmt.format(g.soTien)} đ",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: (isThu && g.soTien >= 0) ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(DateFormat("dd/MM/yyyy").format(g.ngay)),
                                      if (g.ghiChu != null &&
                                          g.ghiChu!.isNotEmpty)
                                        Text(
                                          g.ghiChu!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                                  onTap: () => _suaGiaoDich(g),
                                  onLongPress: () => _xoaGiaoDich(g),
                                ),
                              );
                            }).toList(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),                    
                  ],
                ),
              ),
            ),
    );
  }
}


