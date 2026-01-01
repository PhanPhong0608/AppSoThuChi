class ViTien {
  final String id;
  final String ten;
  final String? loai;
  final int soDu;
  final String? icon;
  final bool an;
  final int chiTieu; // Tạm tính, không lưu DB

  ViTien({
    required this.id,
    required this.ten,
    this.loai,
    required this.soDu,
    this.icon,

    this.an = false,
    this.chiTieu = 0,
  });

  factory ViTien.fromMap(Map<String, dynamic> map) {
    return ViTien(
      id: map['id'] as String,
      ten: map['ten'] as String,
      loai: map['loai'] as String?,
      soDu: map['so_du'] as int,
      icon: map['icon'] as String?,
      an: (map['an'] as int?) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ten': ten,
      'loai': loai,
      'so_du': soDu,
      'icon': icon,
      'an': an ? 1 : 0,
    };
  }
}
