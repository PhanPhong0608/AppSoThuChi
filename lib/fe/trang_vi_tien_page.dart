import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../be/xu_ly_thu_chi_service.dart';
import '../db/models/vi_tien.dart';
import '../db/models/danh_muc.dart';

class TrangViTienPage extends StatefulWidget {
  const TrangViTienPage({
    super.key,
    required this.taiKhoanId,
    required this.service,
    this.onRefresh,
  });

  final String taiKhoanId;
  final XuLyThuChiService service;
  final VoidCallback? onRefresh;

  @override
  State<TrangViTienPage> createState() => TrangViTienPageState();
}

class TrangViTienPageState extends State<TrangViTienPage> {
  final moneyFmt = NumberFormat.decimalPattern("vi_VN");
  List<ViTien>? _danhSachVi;
  bool _dangTai = true;

  @override
  void initState() {
    super.initState();
    _taiDuLieu();
  }

  Future<void> _taiDuLieu() async {
    setState(() => _dangTai = true);
    try {
      final list = await widget.service.layDanhSachVi();
      final updatedList = <ViTien>[];
      for (var v in list) {
        final chi = await widget.service.layTongChiTieuTheoVi(v.id);
        updatedList.add(ViTien(
          id: v.id,
          ten: v.ten,
          loai: v.loai,
          soDu: v.soDu,
          icon: v.icon,
          an: v.an,
          chiTieu: chi,
        ));
      }

      if (mounted) {
        setState(() {
          _danhSachVi = updatedList;
          _dangTai = false;
        });
      }
    } catch (e, st) {
      debugPrint('TrangViTienPage: error loading data: $e\n$st');
      if (mounted) {
        setState(() {
          _danhSachVi = [];
          _dangTai = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi khi tải ví: $e')));
      }
    }
  }

  // Alias public call
  Future<void> taiLai() => _taiDuLieu();

  Future<void> _themViMoi() async {
    await showDialog(
      context: context,
      builder: (dialogCtx) => DialogThemVi(onAdd: (ten, loai, soDu) async {
        await widget.service.themVi(ten: ten, loai: loai, soDu: soDu);
        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
        _taiDuLieu();
        widget.onRefresh?.call();
      }),
    );
  }

  Future<void> _suaSoDu(ViTien vi) async {
    final controller = TextEditingController(text: vi.soDu.toString());
    final moi = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Cập nhật số dư: ${vi.ten}"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: "đ"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val >= 0) {
                Navigator.pop(context, val);
              }
            },
            child: const Text("Lưu"),
          )
        ],
      ),
    );

    if (moi != null && moi != vi.soDu) {
      // Thay vì chỉ cập nhật số dư, ta tạo giao dịch điều chỉnh
      final diff = moi - vi.soDu;
      // User requested: Decrease balance = Subtract Income. Increase = Add Income.
      // So treat all adjustments as "Income" but with signed amount.
      final isThu = true; 

      try {
        final danhMucList = await widget.service.layDanhMuc();
        
        // Tìm danh mục phù hợp
        String? danhMucId;
        
        // 1. Tìm chính xác "Điều chỉnh số dư" có loại là adjustment/dieuchinh
        final exactMatch = danhMucList.firstWhere(
           (d) => d.ten.toLowerCase() == "điều chỉnh số dư" && 
                  (d.loai == 'adjustment' || d.loai == 'dieuchinh'),
           orElse: () => DanhMuc(id: '', ten: '', loai: '')
        );
        if (exactMatch.id.isNotEmpty) danhMucId = exactMatch.id;

        // 2. Nếu không có, tìm theo từ khóa (ưu tiên adjustment)
        if (danhMucId == null) {
          final keyWords = ['điều chỉnh', 'adjust'];
          for (var kw in keyWords) {
             final found = danhMucList.where((d) {
                final name = d.ten.toLowerCase();
                final type = d.loai.toLowerCase();
                return (type == 'adjustment' || type == 'dieuchinh') && name.contains(kw);
             }).firstOrNull;
             
             if (found != null) {
               danhMucId = found.id;
               break;
             }
          }
        }

        // 3. Nếu vẫn chưa có, tạo mới danh mục "Điều chỉnh số dư"
        if (danhMucId == null) {
           await widget.service.themDanhMuc(
              ten: "Điều chỉnh số dư",
              loai: "adjustment", // Loại đặc biệt không tính vào thu chi
              icon: 0xe57f, 
              mau: 0xFF9E9E9E, // Colors.grey
           ); 
           
           // Re-fetch to find it
           final newList = await widget.service.layDanhMuc();
           final created = newList.firstWhere((d) => d.loai == 'adjustment' && d.ten == "Điều chỉnh số dư");
           danhMucId = created.id;
        }

        // Guaranteed to be not null due to creation above
        await widget.service.themGiaoDich(
          taiKhoanId: widget.taiKhoanId,
          soTien: diff, // Signed amount!
          danhMucId: danhMucId,
          viTienId: vi.id,
          ngay: DateTime.now(),
          isThu: isThu,
          ghiChu: "Điều chỉnh ví ${vi.ten}: ${moneyFmt.format(vi.soDu)} -> ${moneyFmt.format(moi)}",
        );

        _taiDuLieu();
        widget.onRefresh?.call();
      } catch (e) {
        debugPrint("Error adjusting balance: $e");
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Lỗi: $e")));
        }
      }
    }
  }

  Future<void> _xoaVi(ViTien vi) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Xóa ví ${vi.ten}?"),
        content: const Text("Bạn có chắc chắn muốn xóa ví này không?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Hủy")),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Xóa")),
        ],
      ),
    );

    if (confirm == true) {
      await widget.service.xoaVi(vi.id); // Warning: api might need uid
      _taiDuLieu();
      widget.onRefresh?.call();
    }
  }

  Future<void> _suaThongTinVi(ViTien vi) async {
    // Tái sử dụng DialogThemVi nhưng sửa lại chút để hỗ trợ edit
    // Để đơn giản, ta copy logic Dialog
    await showDialog(
      context: context,
      builder: (dialogCtx) => DialogThemVi(
        isEdit: true,
        initialTen: vi.ten,
        initialLoai: vi.loai ?? "other",
        initialSoDu: vi.soDu,
        onAdd: (ten, loai, _) async {
          await widget.service.suaVi(vi.id, ten, loai, vi.icon);
          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
          _taiDuLieu();
          widget.onRefresh?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ví của tôi"),
        actions: [
          IconButton(
            onPressed: _themViMoi,
            icon: const Icon(Icons.add),
            tooltip: "Thêm ví",
          )
        ],
      ),
      body: _dangTai
          ? const Center(child: CircularProgressIndicator())
          : (_danhSachVi == null || _danhSachVi!.isEmpty)
              ? const Center(child: Text("Chưa có ví nào"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _danhSachVi!.length,
                  itemBuilder: (context, index) {
                    final vi = _danhSachVi![index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: InkWell(
                        onTap: () {}, // No-op, use menu for actions
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    child: Icon(_iconTuLoai(vi.loai)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          vi.ten,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                        Text(
                                          vi.loai ?? "Khác",
                                          style: const TextStyle(
                                              color: Colors.grey, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton(
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: "edit_balance",
                                        child: Text("Sửa số dư"),
                                      ),
                                      const PopupMenuItem(
                                        value: "edit_info",
                                        child: Text("Sửa thông tin"),
                                      ),
                                      const PopupMenuItem(
                                        value: "delete",
                                        child: Text("Xóa ví",
                                            style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                    onSelected: (val) {
                                      if (val == "edit_balance") _suaSoDu(vi);
                                      if (val == "edit_info")
                                        _suaThongTinVi(vi);
                                      if (val == "delete") _xoaVi(vi);
                                    },
                                  ),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStat(
                                      "Số dư", vi.soDu, Colors.green),
                                  _buildStat(
                                      "Đã chi", vi.chiTieu, Colors.red),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildStat(String label, int amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          NumberFormat.currency(locale: "vi_VN", symbol: "đ").format(amount),
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 15, color: color),
        ),
      ],
    );
  }

  IconData _iconTuLoai(String? loai) {
    switch (loai) {
      case "cash":
        return Icons.money;
      case "ewallet":
        return Icons.account_balance_wallet;
      case "bank":
        return Icons.account_balance;
      default:
        return Icons.wallet;
    }
  }
}

class DialogThemVi extends StatefulWidget {
  const DialogThemVi({
    super.key,
    required this.onAdd,
    this.isEdit = false,
    this.initialTen = "",
    this.initialLoai = "ewallet",
    this.initialSoDu = 0,
  });
  final Function(String ten, String loai, int soDu) onAdd;
  final bool isEdit;
  final String initialTen;
  final String initialLoai;
  final int initialSoDu;

  @override
  State<DialogThemVi> createState() => _DialogThemViState();
}

class _DialogThemViState extends State<DialogThemVi> {
  final _tenCtrl = TextEditingController();
  final _soDuCtrl = TextEditingController();
  String _loai = "ewallet";

  @override
  void initState() {
    super.initState();
    _tenCtrl.text = widget.initialTen;
    _soDuCtrl.text = widget.initialSoDu.toString();
    _loai = widget.initialLoai;
  }

  final _loaiVi = const [
    {"val": "ewallet", "label": "Ví điện tử (Momo, ZaloPay...)"},
    {"val": "bank", "label": "Ngân hàng"},
    {"val": "cash", "label": "Tiền mặt"},
    {"val": "other", "label": "Khác"},
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? "Cập nhật ví" : "Thêm ví mới"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Use DropdownButton instead of FormField to avoid deprecation warning
            InputDecorator(
              decoration: const InputDecoration(labelText: "Loại ví"),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _loai,
                  isDense: true,
                  isExpanded: true,
                  items: _loaiVi
                      .map((e) => DropdownMenuItem(
                          value: e['val'], child: Text(e['label']!)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _loai = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tenCtrl,
              decoration: const InputDecoration(
                labelText: "Tên ví (Ví dụ: Momo)",
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            if (!widget.isEdit)
              TextField(
                controller: _soDuCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Số dư ban đầu",
                  border: OutlineInputBorder(),
                  suffixText: "đ",
                ),
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
            final ten = _tenCtrl.text.trim();
            final soDu = int.tryParse(_soDuCtrl.text.trim()) ?? 0;
            if (ten.isEmpty) return;
            widget.onAdd(ten, _loai, soDu);
          },
          child: const Text("Lưu"),
        ),
      ],
    );
  }
}
