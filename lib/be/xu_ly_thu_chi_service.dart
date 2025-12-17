import '../db/models/giao_dich.dart';
import 'kho_thu_chi_repository.dart';
import 'tong_quan_thang.dart';

class XuLyThuChiService {
  final KhoThuChiRepository repo;
  XuLyThuChiService(this.repo);

  (DateTime, DateTime) _khoangThang(DateTime thangDangXem) {
    final start = DateTime(thangDangXem.year, thangDangXem.month, 1);
    final next = (thangDangXem.month == 12)
        ? DateTime(thangDangXem.year + 1, 1, 1)
        : DateTime(thangDangXem.year, thangDangXem.month + 1, 1);
    return (start, next);
  }

  Future<TongQuanThang> taiDuLieuThang({
    required int taiKhoanId,
    required DateTime thangDangXem,
  }) async {
    final (start, next) = _khoangThang(thangDangXem);
    final startMs = start.millisecondsSinceEpoch;
    final endMs = next.millisecondsSinceEpoch;

    final dsDanhMuc = await repo.layDanhMuc();
    final mapTenDanhMuc = {for (final d in dsDanhMuc) d.id: d.ten};

    final nganSach = await repo.layNganSachThang(
          taiKhoanId: taiKhoanId,
          nam: thangDangXem.year,
          thang: thangDangXem.month,
        ) ??
        0;

    final daChi = await repo.tinhTongChiTrongKhoang(
      taiKhoanId: taiKhoanId,
      startMs: startMs,
      endMs: endMs,
    );

    final raw = await repo.layGiaoDichTrongKhoang(
      taiKhoanId: taiKhoanId,
      startMs: startMs,
      endMs: endMs,
    );

    final List<GiaoDich> dsGiaoDich = raw
        .map((g) => g.copyWith(tenDanhMuc: mapTenDanhMuc[g.danhMucId] ?? "Khác"))
        .toList();

    return TongQuanThang(
      nganSach: nganSach,
      daChi: daChi,
      conLai: nganSach - daChi,
      giaoDich: dsGiaoDich,
    );
  }

  Future<void> datNganSachThang({
    required int taiKhoanId,
    required DateTime thangDangXem,
    required int soTienNganSach,
  }) async {
    await repo.capNhatNganSachThang(
      taiKhoanId: taiKhoanId,
      nam: thangDangXem.year,
      thang: thangDangXem.month,
      soTienNganSach: soTienNganSach,
    );
  }

  Future<void> themKhoanChi({
    required int taiKhoanId,
    required int soTien,
    required int danhMucId,
    required DateTime ngay,
    String? ghiChu,
  }) async {
    await repo.themGiaoDich(
      taiKhoanId: taiKhoanId,
      soTien: soTien,
      danhMucId: danhMucId,
      ngay: ngay,
      ghiChu: ghiChu,
    );
  }
}
