import '../db/models/giao_dich.dart';
import '../db/models/vi_tien.dart';
import '../db/models/danh_muc.dart';
import 'kho_thu_chi_repository.dart';
import 'kho_tai_khoan_repository.dart';
import 'tong_quan_thang.dart';
import 'phien_dang_nhap.dart';

class XuLyThuChiService {
  final KhoThuChiRepository repo;
  final KhoTaiKhoanRepository tkRepo;
  final PhienDangNhap phien;

  XuLyThuChiService(this.repo, this.tkRepo, this.phien);

  Future<String> _getUserId() async {
    final uid = await phien.layUserId();
    if (uid == null) throw Exception("Chưa đăng nhập.");
    return uid;
  }

  (DateTime, DateTime) _khoangThang(DateTime thangDangXem) {
    final start = DateTime(thangDangXem.year, thangDangXem.month, 1);
    final next = (thangDangXem.month == 12)
        ? DateTime(thangDangXem.year + 1, 1, 1)
        : DateTime(thangDangXem.year, thangDangXem.month + 1, 1);
    return (start, next);
  }

  // NOTE: taiKhoanId was passed here before.
  // Should we use the passed one or the one from Phien?
  // Usually the UI passes the current user ID if it knows it.
  // But let's verify if the UI passes it. 
  // If we change signature to remove taiKhoanId, we break UI.
  // If we keep it, we should ensure it matches Phien or just use Phien.
  // For safety, let's keep the signature but ignore logical conflict (or assert).
  // Actually, 'taiKhoanId' is now 'String'. The UI is likely calling with 'phien.currentUser.id' anyway.
  // Wait, if UI code hasn't been updated, it might try to pass an INT id.
  // But the UI gets the ID from `Phien`. I updated `Phien` to return String.
  // So the UI compilation will break if I don't update UI.
  // Since I can't see UI, I can assume UI gets ID from Phien.
  // So I should change 'int taiKhoanId' to 'String taiKhoanId'.
  
  Future<TongQuanThang> taiDuLieuThang({
    required String taiKhoanId, // Changed from int
    required DateTime thangDangXem,
  }) async {
    final (start, next) = _khoangThang(thangDangXem);
    final startMs = start.millisecondsSinceEpoch;
    final endMs = next.millisecondsSinceEpoch;

    // Use taiKhoanId passed in
    final dsDanhMuc = await repo.layDanhMuc(taiKhoanId);
    final mapTenDanhMuc = {for (final d in dsDanhMuc) d.id: d.ten};

    // Calculate total wallet balance
    final listVi = await repo.layDanhSachVi(taiKhoanId);
    final tongSoDuVi = listVi.fold(0, (sum, v) => sum + v.soDu);
    
    final raw = await repo.layGiaoDichTrongKhoang(
      userId: taiKhoanId,
      startMs: startMs,
      endMs: endMs,
    );

    final List<GiaoDich> dsGiaoDich = raw
        .map((g) => g.copyWith(tenDanhMuc: mapTenDanhMuc[g.danhMucId] ?? "Khác"))
        .toList();

    // Calculate total expense manually to exclude income
    int daChi = 0;
    for (var g in dsGiaoDich) {
      final dm = mapTenDanhMuc[g.danhMucId]; // This map only has names now. We need the object.
      // Re-fetch category object map or search in dsDanhMuc
      final catObj = dsDanhMuc.firstWhere((d) => d.id == g.danhMucId, orElse: () => DanhMuc(id: '', ten: '', loai: 'expense'));
      final loai = catObj.loai.toLowerCase();
      if (loai == 'chi' || loai == 'expense') {
        daChi += g.soTien;
      }
    }

    return TongQuanThang(
      tongSoDuVi: tongSoDuVi,
      daChi: daChi,
      giaoDich: dsGiaoDich,
    );
  }

  Future<void> datNganSachThang({
    required String taiKhoanId,
    required DateTime thangDangXem,
    required int soTienNganSach,
  }) async {
    await repo.capNhatNganSachThang(
      userId: taiKhoanId,
      nam: thangDangXem.year,
      thang: thangDangXem.month,
      soTienNganSach: soTienNganSach,
    );
  }

  Future<void> themGiaoDich({
    required String taiKhoanId,
    required int soTien,
    required String danhMucId,
    required String viTienId, // Now mandatory (must select wallet)
    required DateTime ngay,
    required bool isThu, // true = income, false = expense
    String? ghiChu,
  }) async {
    await repo.themGiaoDich(
      userId: taiKhoanId,
      soTien: soTien,
      danhMucId: danhMucId,
      viTienId: viTienId,
      ngay: ngay,
      ghiChu: ghiChu,
    );

    // Update wallet balance
    final viList = await repo.layDanhSachVi(taiKhoanId);
    final vi = viList.firstWhere((v) => v.id == viTienId, orElse: () => throw Exception("Ví không tồn tại"));
    
    int newBalance = vi.soDu;
    if (isThu) {
      newBalance += soTien;
    } else {
      newBalance -= soTien;
    }

    await repo.capNhatSoDuVi(taiKhoanId, viTienId, newBalance);

    // Cập nhật chuỗi lửa
    await _capNhatStreak(taiKhoanId, ngay);
  }

  Future<void> checkInHangNgay() async {
    final uid = await _getUserId();
    await _capNhatStreak(uid, DateTime.now());
  }

  Future<void> _capNhatStreak(String uid, DateTime activityDate) async {
    try {
      final user = await tkRepo.layTheoId(uid);
      if (user != null) {
        final txDate = DateTime(activityDate.year, activityDate.month, activityDate.day);
        
        final lastMs = user.ngayHoatDongCuoiMs;
        DateTime? lastDate;
        if (lastMs != null) {
          final d = DateTime.fromMillisecondsSinceEpoch(lastMs);
          lastDate = DateTime(d.year, d.month, d.day);
        }

        int newStreak = user.chuoiLua;

        if (lastDate == null) {
          // Chưa có activity nào -> streak = 1
          newStreak = 1;
          await tkRepo.capNhatChuoiLua(uid: uid, chuoiLua: newStreak, ngayHoatDongCuoiMs: txDate.millisecondsSinceEpoch);
        } else {
          // Compare txDate vs lastDate
          if (txDate.isBefore(lastDate)) {
            // Giao dịch cũ hơn ngày cuối cùng -> không ảnh hưởng streak hiện tại
          } else if (txDate.isAtSameMomentAs(lastDate)) {
            // Cùng ngày -> không đổi
          } else {
            // Ngày mới hơn
            final diff = txDate.difference(lastDate).inDays;
            if (diff == 1) {
              newStreak++;
            } else {
              // Cách quá xa
              newStreak = 1;
            }
            await tkRepo.capNhatChuoiLua(uid: uid, chuoiLua: newStreak, ngayHoatDongCuoiMs: txDate.millisecondsSinceEpoch);
          }
        }
      }
    } catch (e) {
      print("Streak update failed: $e");
    }
  }

  // Refactored methods that didn't have ID before
  
  Future<List<ViTien>> layDanhSachVi() async {
    final uid = await _getUserId();
    return repo.layDanhSachVi(uid);
  }

  // Public wrapper to get categories. FE should call this instead of accessing repo directly.
  Future<List<DanhMuc>> layDanhMuc() async {
    final uid = await _getUserId();
    return repo.layDanhMuc(uid);
  }

  Future<void> seedDefaultCategories() async {
    final uid = await _getUserId();
    return repo.seedDefaultCategories(uid);
  }

  Future<void> seedDefaultWallets() async {
    final uid = await _getUserId();
    await repo.seedDefaultWallets(uid);
  }

  Future<void> themVi({
    required String ten,
    required String loai,
    required int soDu,
    String? icon,
  }) async {
    final uid = await _getUserId();
    return repo.themVi(userId: uid, ten: ten, loai: loai, soDu: soDu, icon: icon);
  }

  Future<void> capNhatSoDuVi(String viId, int soDuMoi) async {
    final uid = await _getUserId();
    return repo.capNhatSoDuVi(uid, viId, soDuMoi);
  }

  Future<void> xoaVi(String id) async {
    final uid = await _getUserId();
    return repo.xoaVi(uid, id);
  }

  Future<void> suaVi(String id, String ten, String loai, String? icon) async {
    final uid = await _getUserId();
    return repo.suaVi(uid, id, ten, loai, icon);
  }

  Future<void> suaGiaoDich({
    required String id,
    required int soTien,
    required String danhMucId,
    required String? viTienId,
    required DateTime ngay,
    String? ghiChu,
  }) async {
    final uid = await _getUserId();
    return repo.suaGiaoDich(
        userId: uid,
        id: id,
        soTienMoi: soTien,
        danhMucIdMoi: danhMucId,
        viTienIdMoi: viTienId,
        ngayMoi: ngay,
        ghiChuMoi: ghiChu,
      );
  }

  Future<void> xoaGiaoDich(String id) async {
    final uid = await _getUserId();
    
    // 1. Get transaction details
    final g = await repo.layChiTietGiaoDich(userId: uid, id: id);
    if (g == null) return; // Already deleted or not found

    // 2. Identify if Income/Expense to revert balance
    // Need category type
    final cats = await repo.layDanhMuc(uid);
    final cat = cats.firstWhere((c) => c.id == g.danhMucId, orElse: () => DanhMuc(id: '', ten: '', loai: 'expense'));
    
    final type = cat.loai.toLowerCase();
    final isThu = type == 'thu' || type == 'income';
    
    // 3. Revert balance
    // If it was Income => Subtract from wallet
    // If it was Expense => Add back to wallet
    if (g.viTienId != null) {
      final viList = await repo.layDanhSachVi(uid);
      final vi = viList.where((v) => v.id == g.viTienId).firstOrNull;
      
      if (vi != null) {
        int newBalance = vi.soDu;
        if (isThu) {
          newBalance -= g.soTien; // Revert income
        } else {
          newBalance += g.soTien; // Revert expense
        }
        await repo.capNhatSoDuVi(uid, g.viTienId!, newBalance);
      }
    }

    // 4. Delete transaction
    return repo.xoaGiaoDich(uid, id);
  }

  Future<int> layTongChiTieuTheoVi(String viId) async {
    final uid = await _getUserId();
    return repo.layTongChiTieuTheoVi(uid, viId);
  }

  Future<List<Map<String, Object?>>> layThongKeTheoDanhMuc({
    required String taiKhoanId,
    required DateTime thang,
  }) {
    final (start, next) = _khoangThang(thang);
    return repo.thongKeTheoDanhMuc(
      userId: taiKhoanId,
      startMs: start.millisecondsSinceEpoch,
      endMs: next.millisecondsSinceEpoch,
    );
  }

  Future<List<Map<String, Object?>>> layThongKeTheoNam({
    required String taiKhoanId,
    required int nam,
  }) {
    return repo.thongKeTheoThoiGian(userId: taiKhoanId, nam: nam);
  }

  Future<List<GiaoDich>> layGiaoDichTrongKhoang({
    required String userId,
    required int startMs,
    required int endMs,
  }) {
    return repo.layGiaoDichTrongKhoang(userId: userId, startMs: startMs, endMs: endMs);
  }

  Future<void> themDanhMuc({
    required String ten,
    required String loai,
    int? icon,
    int? mau,
  }) async {
    final uid = await _getUserId();
    await repo.themDanhMuc(userId: uid, ten: ten, loai: loai, icon: icon, mau: mau);
  }

  Future<void> suaDanhMuc({
    required String id,
    required String ten,
    required String loai,
    int? icon,
    int? mau,
  }) async {
    final uid = await _getUserId();
    await repo.suaDanhMuc(userId: uid, id: id, ten: ten, loai: loai, icon: icon, mau: mau);
  }

  Future<void> xoaDanhMuc(String id) async {
    final uid = await _getUserId();
    await repo.xoaDanhMuc(userId: uid, id: id);
  }
}
