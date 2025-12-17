import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../be/xu_ly_thu_chi_service.dart';
import '../be/tong_quan_thang.dart';
import 'widgets/the_tong_quan_thang.dart';

class TrangTongQuanPage extends StatefulWidget {
  const TrangTongQuanPage({
    super.key,
    required this.taiKhoanId,
    required this.service,
  });

  final int taiKhoanId;
  final XuLyThuChiService service;
  

  @override
  State<TrangTongQuanPage> createState() => TrangTongQuanPageState();
}

class TrangTongQuanPageState extends State<TrangTongQuanPage> {
  final moneyFmt = NumberFormat.decimalPattern("vi_VN");
  final ScrollController _dsGiaoDichCtrl = ScrollController();

  DateTime thangDangXem = DateTime(DateTime.now().year, DateTime.now().month, 1);
  TongQuanThang? tongQuan;
  bool loading = true;

  // ✅ Mặc định lọc theo NGÀY HÔM NAY
  DateTime? ngayLoc;

  @override
  void initState() {
    super.initState();

    // Lấy "hôm nay" (chỉ lấy phần ngày)
    final now = DateTime.now();
    ngayLoc = DateTime(now.year, now.month, now.day);

    taiLai();
  }

  @override
  void dispose() {
    _dsGiaoDichCtrl.dispose();
    super.dispose();
  }


  Future<void> taiLai() async {
    setState(() => loading = true);
    tongQuan = await widget.service.taiDuLieuThang(
      taiKhoanId: widget.taiKhoanId,
      thangDangXem: thangDangXem,
    );
    if (mounted) setState(() => loading = false);
  }

  bool _cungNgay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _thangTruoc() {
    final y = thangDangXem.year;
    final m = thangDangXem.month;

    setState(() {
      thangDangXem = (m == 1) ? DateTime(y - 1, 12, 1) : DateTime(y, m - 1, 1);

      // ✅ đổi tháng thì bỏ lọc ngày (vì "hôm nay" không thuộc tháng đó)
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

  Future<void> _datNganSachDialog() async {
    final hienTai = tongQuan?.nganSach ?? 0;
    final ctrl = TextEditingController(text: hienTai.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Đặt ngân sách tháng"),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "Ví dụ: 5000000",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, int.tryParse(ctrl.text.trim())),
            child: const Text("Lưu"),
          ),
        ],
      ),
    );

    if (result == null || result < 0) return;

    await widget.service.datNganSachThang(
      taiKhoanId: widget.taiKhoanId,
      thangDangXem: thangDangXem,
      soTienNganSach: result,
    );

    await taiLai();
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

    // ✅ lưu ngày lọc (chỉ phần ngày)
    setState(() => ngayLoc = DateTime(picked.year, picked.month, picked.day));
  }

  void _boLocNgay() {
    final now = DateTime.now();
    setState(() => ngayLoc = DateTime(now.year, now.month, now.day));
  }

  @override
  Widget build(BuildContext context) {
    final labelThang = DateFormat("MM/yyyy").format(thangDangXem);
    final t = tongQuan;

    // ✅ Nếu có ngayLoc => lọc theo ngày đó, nếu không => xem cả tháng
    final dsHienThi = (t?.giaoDich ?? []).where((g) {
      if (ngayLoc == null) return true;
      return _cungNgay(g.ngay, ngayLoc!);
    }).toList();

    final titleGiaoDich = ngayLoc == null
        ? "Giao dịch trong tháng ($labelThang)"
        : "Giao dịch ngày ${DateFormat("dd/MM/yyyy").format(ngayLoc!)}";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sổ thu chi"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        // Thẻ tổng quan (không scroll)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: TheTongQuanThang(
                            monthLabel: labelThang,
                            nganSach: t?.nganSach ?? 0,
                            daChi: t?.daChi ?? 0,
                            conLai: t?.conLai ?? 0,
                            moneyFmt: moneyFmt,
                            onPrev: _thangTruoc,
                            onNext: _thangSau,
                            onSetBudget: _datNganSachDialog,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tiêu đề + nút chọn ngày lọc
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  titleGiaoDich,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              if (ngayLoc != null)
                                IconButton(
                                  tooltip: "Về hôm nay",
                                  onPressed: _boLocNgay,
                                  icon: const Icon(Icons.close),
                                ),
                              FilledButton.tonalIcon(
                                onPressed: _chonNgayLoc,
                                icon: const Icon(Icons.calendar_month),
                                label: Text(ngayLoc == null ? "Chọn ngày" : "Đổi ngày"),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // chỉ danh sách giao dịch được scroll
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: dsHienThi.isEmpty
                                ? Center(
                                    child: Text(
                                      "Không có giao dịch trong ngày đã chọn.",
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  )
                                : Scrollbar(
                                    controller: _dsGiaoDichCtrl,
                                    thumbVisibility: true,
                                    child: ListView.builder(
                                      controller: _dsGiaoDichCtrl,
                                      padding: const EdgeInsets.only(bottom: 12),
                                      itemCount: dsHienThi.length,
                                      itemBuilder: (context, i) {
                                        final g = dsHienThi[i];
                                        return Card(
                                          child: ListTile(
                                            leading: const Icon(Icons.receipt_long),
                                            title: Text(
                                              "${g.tenDanhMuc} • ${moneyFmt.format(g.soTien)} đ",
                                            ),
                                            subtitle: Text(
                                              "${DateFormat("dd/MM/yyyy").format(g.ngay)}"
                                              "${(g.ghiChu == null) ? "" : " • ${g.ghiChu}"}",
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // chừa khoảng cho FAB
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}
