class GiaoDich {
  final int id;
  final int soTien;
  final int danhMucId;
  final DateTime ngay;
  final String? ghiChu;

  // ✅ thêm ví tiền (có thể null nếu không chọn ví)
  final int? viTienId;

  // view-only
  final String tenDanhMuc;

  GiaoDich({
    required this.id,
    required this.soTien,
    required this.danhMucId,
    required this.ngay,
    required this.ghiChu,
    required this.tenDanhMuc,
    this.viTienId,
  });

  factory GiaoDich.fromMap(Map<String, Object?> m) => GiaoDich(
        id: m["id"] as int,
        soTien: m["so_tien"] as int,
        danhMucId: m["danh_muc_id"] as int,
        ngay: DateTime.fromMillisecondsSinceEpoch(m["ngay"] as int),
        ghiChu: m["ghi_chu"] as String?,
        viTienId: m["vi_tien_id"] as int?, // ✅ map từ DB
        tenDanhMuc: (m["ten_danh_muc"] as String?) ?? "", // nếu query join có alias
      );

  GiaoDich copyWith({
    String? tenDanhMuc,
    int? viTienId,
    bool clearViTienId = false,
  }) =>
      GiaoDich(
        id: id,
        soTien: soTien,
        danhMucId: danhMucId,
        ngay: ngay,
        ghiChu: ghiChu,
        tenDanhMuc: tenDanhMuc ?? this.tenDanhMuc,
        viTienId: clearViTienId ? null : (viTienId ?? this.viTienId),
      );
}
