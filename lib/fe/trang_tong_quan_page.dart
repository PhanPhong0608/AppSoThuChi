import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../be/xu_ly_thu_chi_service.dart';
import '../be/tong_quan_thang.dart';
import '../db/models/giao_dich.dart';
import '../db/models/danh_muc.dart';
import '../db/models/vi_tien.dart';
import 'widgets/the_tong_quan_thang.dart';

class TrangTongQuanPage extends StatefulWidget {
  const TrangTongQuanPage({
    super.key,
    required this.taiKhoanId,
    required this.service,
  });

  final String taiKhoanId;
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

  // ✅ Mặc định lọc theo NGÀY HÔM NAY (chỉ phần ngày)
  DateTime? ngayLoc;

  // Map cache tên ví
  final Map<String, String> dsViMap = {};

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    // ✅ set tháng đang xem = tháng hiện tại
    thangDangXem = DateTime(now.year, now.month, 1);

    // ✅ mặc định lọc theo ngày hôm nay
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
    setState(() => loading = true);
    try {
      // Fetch danh sách ví để map ID sang Tên
      dsViMap.clear();
      final listVi = await widget.service.layDanhSachVi();
      for (var v in listVi) {
        dsViMap[v.id] = v.ten;
      }

      tongQuan = await widget.service.taiDuLieuThang(
        taiKhoanId: widget.taiKhoanId,
        thangDangXem: thangDangXem,
      );
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
            onPressed: () =>
                Navigator.pop(context, int.tryParse(ctrl.text.trim())),
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

  // ✅ CHỌN NGÀY: tự nhảy về đúng tháng của ngày đó + reload
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

  // ✅ VỀ HÔM NAY: cũng phải về đúng tháng hiện tại + reload
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
      taiLai();
    }
  }

  Future<void> _suaGiaoDich(GiaoDich g) async {
    final dsVi = await widget.service.layDanhSachVi();

    // ✅ lấy danh mục và chống lặp trên UI
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
      builder: (context) => DialogSuaGiaoDich(
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
          if (mounted) Navigator.pop(context);
          taiLai();
        },
      ),
    );
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
                                label:
                                    Text(ngayLoc == null ? "Chọn ngày" : "Đổi ngày"),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: dsHienThi.isEmpty
                                ? Center(
                                    child: Text(
                                      ngayLoc == null
                                          ? "Không có giao dịch trong tháng đã chọn."
                                          : "Không có giao dịch trong ngày đã chọn.",
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
                                            leading:
                                                const Icon(Icons.receipt_long),
                                            title: Text(
                                              "${g.tenDanhMuc} • ${moneyFmt.format(g.soTien)} đ",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: g.viTienId == null
                                                    ? Colors.black
                                                    : Colors.green[800],
                                              ),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  DateFormat("dd/MM/yyyy")
                                                      .format(g.ngay),
                                                ),
                                                if (g.ghiChu != null &&
                                                    g.ghiChu!.isNotEmpty)
                                                  Text(g.ghiChu!),
                                                Text(
                                                  g.viTienId == null
                                                      ? "Nguồn: Ngân sách"
                                                      : "Nguồn: ${dsViMap[g.viTienId] ?? 'Ví'}",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontStyle: FontStyle.italic,
                                                    color: g.viTienId == null
                                                        ? Colors.grey[600]
                                                        : Colors.green[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            onTap: () => _suaGiaoDich(g),
                                            onLongPress: () => _xoaGiaoDich(g),
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

                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}

class DialogSuaGiaoDich extends StatefulWidget {
  const DialogSuaGiaoDich({
    super.key,
    required this.giaoDich,
    required this.dsVi,
    required this.dsDanhMuc,
    required this.onSave,
  });

  final GiaoDich giaoDich;
  final List<ViTien> dsVi;
  final List<DanhMuc> dsDanhMuc;
  final Function(int, String, String?, DateTime, String?) onSave;

  @override
  State<DialogSuaGiaoDich> createState() => _DialogSuaGiaoDichState();
}

class _DialogSuaGiaoDichState extends State<DialogSuaGiaoDich> {
  late TextEditingController _soTienCtrl;
  late TextEditingController _ghiChuCtrl;
  late DateTime _ngay;
  String? _selectedVi;
  late String _selectedDanhMuc;
  bool _dungVi = false;

  @override
  void initState() {
    super.initState();
    final g = widget.giaoDich;
    _soTienCtrl = TextEditingController(text: g.soTien.toString());
    _ghiChuCtrl = TextEditingController(text: g.ghiChu ?? "");
    _ngay = g.ngay;
    _selectedVi = g.viTienId;
    _selectedDanhMuc = g.danhMucId;
    _dungVi = g.viTienId != null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Sửa giao dịch"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _soTienCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Số tiền"),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedDanhMuc,
              items: widget.dsDanhMuc
                  .map<DropdownMenuItem<String>>(
                      (e) => DropdownMenuItem(value: e.id, child: Text(e.ten)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedDanhMuc = v!),
              decoration: const InputDecoration(labelText: "Danh mục"),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text("Nguồn: "),
                ChoiceChip(
                  label: const Text("Ngân sách"),
                  selected: !_dungVi,
                  onSelected: (v) => v ? setState(() => _dungVi = false) : null,
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Ví"),
                  selected: _dungVi,
                  onSelected: (v) => v
                      ? setState(() {
                          _dungVi = true;
                          if (_selectedVi == null && widget.dsVi.isNotEmpty) {
                            _selectedVi = widget.dsVi.first.id;
                          }
                        })
                      : null,
                ),
              ],
            ),
            if (_dungVi)
              DropdownButtonFormField<String>(
                value: _selectedVi,
                items: widget.dsVi
                    .map<DropdownMenuItem<String>>(
                        (e) => DropdownMenuItem(value: e.id, child: Text(e.ten)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedVi = v),
                decoration: const InputDecoration(labelText: "Ví"),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _ghiChuCtrl,
              decoration: const InputDecoration(labelText: "Ghi chú"),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  initialDate: _ngay,
                );
                if (d != null) setState(() => _ngay = d);
              },
              icon: const Icon(Icons.calendar_today),
              label: Text(DateFormat("dd/MM/yyyy").format(_ngay)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Hủy"),
        ),
        FilledButton(
          onPressed: () {
            final amt = int.tryParse(_soTienCtrl.text) ?? 0;
            widget.onSave(
              amt,
              _selectedDanhMuc,
              _dungVi ? _selectedVi : null,
              _ngay,
              _ghiChuCtrl.text,
            );
          },
          child: const Text("Lưu"),
        ),
      ],
    );
  }
}
