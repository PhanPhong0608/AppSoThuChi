import '../db/models/giao_dich.dart';

class TongQuanThang {
  final int nganSach;
  final int daChi;
  final int conLai;
  final List<GiaoDich> giaoDich;

  TongQuanThang({
    required this.nganSach,
    required this.daChi,
    required this.conLai,
    required this.giaoDich,
  });
}
