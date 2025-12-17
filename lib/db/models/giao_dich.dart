class GiaoDich {
  final int id;
  final int soTien;
  final int danhMucId;
  final DateTime ngay;
  final String? ghiChu;

  // view-only
  final String tenDanhMuc;

  GiaoDich({
    required this.id,
    required this.soTien,
    required this.danhMucId,
    required this.ngay,
    required this.ghiChu,
    required this.tenDanhMuc,
  });

  factory GiaoDich.fromMap(Map<String, Object?> m) => GiaoDich(
        id: m["id"] as int,
        soTien: m["so_tien"] as int,
        danhMucId: m["danh_muc_id"] as int,
        ngay: DateTime.fromMillisecondsSinceEpoch(m["ngay"] as int),
        ghiChu: m["ghi_chu"] as String?,
        tenDanhMuc: "",
      );

  GiaoDich copyWith({String? tenDanhMuc}) => GiaoDich(
        id: id,
        soTien: soTien,
        danhMucId: danhMucId,
        ngay: ngay,
        ghiChu: ghiChu,
        tenDanhMuc: tenDanhMuc ?? this.tenDanhMuc,
      );
}
