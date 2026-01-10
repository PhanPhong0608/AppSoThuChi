import '../db/models/giao_dich.dart';

class TongQuanThang {
  final int tongSoDuVi;
  final int daChi;
  final List<GiaoDich> giaoDich;

  TongQuanThang({
    required this.tongSoDuVi,
    required this.daChi,
    required this.giaoDich,
  });
}
