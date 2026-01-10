class TaiKhoan {
  final String id;
  final String email;
  final String? ten;
  final String? sdt;
  final int chuoiLua;
  final int? ngayHoatDongCuoiMs;

  TaiKhoan({
    required this.id,
    required this.email,
    this.ten,
    this.sdt,
    this.chuoiLua = 0,
    this.ngayHoatDongCuoiMs,
  });

  factory TaiKhoan.fromMap(Map<String, Object?> m) => TaiKhoan(
        id: m["id"] as String,
        email: m["email"] as String,
        ten: m["ten"] as String?,
        sdt: m["sdt"] as String?,
        chuoiLua: (m["chuoi_lua"] as num?)?.toInt() ?? 0,
        ngayHoatDongCuoiMs: (m["ngay_hoat_dong_cuoi"] as num?)?.toInt(),
      );
}
