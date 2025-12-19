import '../db/models/giao_dich.dart';
import '../db/models/vi_tien.dart';
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
    // Tính tổng chi (chỉ tính từ ngân sách, KHÔNG tính từ ví)
    final daChi = await repo.tinhTongChiTrongKhoang(
      taiKhoanId: taiKhoanId,
      startMs: startMs,
      endMs: endMs,
      chiTuNganSach: true, 
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
    required int? viTienId,
    required DateTime ngay,
    String? ghiChu,
  }) async {
    await repo.themGiaoDich(
      taiKhoanId: taiKhoanId,
      soTien: soTien,
      danhMucId: danhMucId,
      viTienId: viTienId,
      ngay: ngay,
      ghiChu: ghiChu,
    );
  }

  Future<List<ViTien>> layDanhSachVi() => repo.layDanhSachVi();

  Future<void> themVi({
    required String ten,
    required String loai,
    required int soDu,
    String? icon,
  }) =>
      repo.themVi(ten: ten, loai: loai, soDu: soDu, icon: icon);

  Future<void> capNhatSoDuVi(int viId, int soDuMoi) =>
      repo.capNhatSoDuVi(viId, soDuMoi);

  Future<void> xoaVi(int id) => repo.xoaVi(id);

  Future<void> suaVi(int id, String ten, String loai, String? icon) =>
      repo.suaVi(id, ten, loai, icon);

  Future<void> suaGiaoDich({
    required int id,
    required int soTien,
    required int danhMucId,
    required int? viTienId,
    required DateTime ngay,
    String? ghiChu,
  }) =>
      repo.suaGiaoDich(
        id: id,
        soTienMoi: soTien,
        danhMucIdMoi: danhMucId,
        viTienIdMoi: viTienId,
        ngayMoi: ngay,
        ghiChuMoi: ghiChu,
      );

  Future<void> xoaGiaoDich(int id) => repo.xoaGiaoDich(id);

  Future<int> layTongChiTieuTheoVi(int viId) => repo.layTongChiTieuTheoVi(viId);

  Future<List<Map<String, Object?>>> layThongKeTheoDanhMuc({
    required int taiKhoanId,
    required DateTime thang,
  }) {
    final (start, next) = _khoangThang(thang);
    return repo.thongKeTheoDanhMuc(
      taiKhoanId: taiKhoanId,
      startMs: start.millisecondsSinceEpoch,
      endMs: next.millisecondsSinceEpoch,
    );
  }

  Future<List<Map<String, Object?>>> layThongKeTheoNam({
    required int taiKhoanId,
    required int nam,
  }) {
    return repo.thongKeTheoThoiGian(taiKhoanId: taiKhoanId, nam: nam);
  }
}
