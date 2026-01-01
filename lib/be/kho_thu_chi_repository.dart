import 'package:firebase_database/firebase_database.dart';
import '../db/models/danh_muc.dart';
import '../db/models/giao_dich.dart';
import '../db/models/vi_tien.dart';

class KhoThuChiRepository {
  KhoThuChiRepository();

  final DatabaseReference _root = FirebaseDatabase.instance.ref();
  DatabaseReference _userRef(String uid) => _root.child('users').child(uid);

  Map<String, dynamic> _normalizeSnapshotValue(dynamic value) {
    if (value == null) return {};
    if (value is Map) {
      final out = <String, dynamic>{};
      value.forEach((k, v) => out[k.toString()] = v);
      return out;
    }
    if (value is List) {
      final out = <String, dynamic>{};
      for (var i = 0; i < value.length; i++) {
        final v = value[i];
        if (v != null) out[i.toString()] = v;
      }
      return out;
    }
    return {};
  }

  Future<List<DanhMuc>> layDanhMuc(String uid) async {
    final snap = await _userRef(uid).child('categories').get();
    final val = snap.value;

    if (val is! Map) return [];

    final list = <DanhMuc>[];
    val.forEach((key, value) {
      if (value is Map) {
        list.add(DanhMuc(
          id: key.toString(),
          ten: (value['ten'] ?? '').toString(),
          loai: (value['loai'] ?? 'expense').toString(),
        ));
      }
    });

    final uniq = <String, DanhMuc>{};
    for (final dm in list) {
      final k = '${dm.ten.trim().toLowerCase()}|${dm.loai.trim().toLowerCase()}';
      uniq.putIfAbsent(k, () => dm);
    }

    return uniq.values.toList()
      ..sort((a, b) => a.ten.compareTo(b.ten));
  }


  /// Create default categories for a user (used when none exist)
  Future<void> seedDefaultCategories(String uid) async {
    final ref = _userRef(uid).child('categories');

    final now = DateTime.now().millisecondsSinceEpoch;

    // ID cố định (em có thể đổi tên key nếu muốn)
    final defaults = <String, Map<String, dynamic>>{
      'dm_an_uong': {'ten': 'Ăn uống', 'loai': 'expense', 'tao_luc': now},
      'dm_mua_sam': {'ten': 'Mua sắm', 'loai': 'expense', 'tao_luc': now},
      'dm_di_chuyen': {'ten': 'Di chuyển', 'loai': 'expense', 'tao_luc': now},
      'dm_hoa_don': {'ten': 'Hóa đơn', 'loai': 'expense', 'tao_luc': now},
      'dm_giao_duc': {'ten': 'Giáo dục', 'loai': 'expense', 'tao_luc': now},
      'dm_giai_tri': {'ten': 'Giải trí', 'loai': 'expense', 'tao_luc': now},
      'dm_suc_khoe': {'ten': 'Sức khỏe', 'loai': 'expense', 'tao_luc': now},
      'dm_khac': {'ten': 'Khác', 'loai': 'expense', 'tao_luc': now},
    };

    // update() sẽ tạo/ghi đè theo key -> gọi nhiều lần cũng không trùng
    await ref.update(defaults);
  }


  /// Tạo sẵn 2 ví mặc định nếu user chưa có ví nào.
  /// - Tiền mặt
  /// - Ngân hàng
  Future<void> seedDefaultWallets(String userId) async {
    final walletsRef = _userRef(userId).child("wallets");
    final snap = await walletsRef.get();
    if (snap.exists) return;

    await walletsRef.push().set({
      "ten": "Tiền mặt",
      "loai": "cash",
      "so_du": 0,
      "icon": "💵",
      "an": 0,
    });

    await walletsRef.push().set({
      "ten": "Ngân hàng",
      "loai": "bank",
      "so_du": 0,
      "icon": "🏦",
      "an": 0,
    });
  }

  Future<List<ViTien>> layDanhSachVi(String userId) async {
    final snapshot =
        await _userRef(userId).child("wallets").orderByChild("an").equalTo(0).get();
    if (!snapshot.exists) return [];
    final raw = snapshot.value;
    final data = _normalizeSnapshotValue(raw);
    if (data.isEmpty) return [];
    final out = <ViTien>[];
    for (final e in data.entries) {
      final v = e.value;
      if (v is Map) {
        final val = Map<String, Object?>.from(v);
        val['id'] = e.key;
        out.add(ViTien.fromMap(val));
      } else {
        out.add(ViTien.fromMap({
          'id': e.key,
          'ten': v?.toString() ?? '',
          'so_du': 0,
          'an': 0
        }));
      }
    }
    return out;
  }

  Future<void> suaVi(String userId, String id, String ten, String loai, String? icon) async {
    await _userRef(userId).child("wallets").child(id).update({
      "ten": ten,
      "loai": loai,
      "icon": icon,
    });
  }

  Future<void> xoaVi(String userId, String id) async {
    // Soft delete: DB dùng int 0/1 cho an
    await _userRef(userId).child("wallets").child(id).update({"an": 1});
  }

  Future<void> themVi({
    required String userId,
    required String ten,
    required String loai,
    required int soDu,
    String? icon,
  }) async {
    await _userRef(userId).child("wallets").push().set({
      "ten": ten,
      "loai": loai,
      "so_du": soDu,
      "icon": icon,
      "an": 0,
    });
  }

  Future<void> capNhatSoDuVi(String userId, String viId, int soDuMoi) async {
    await _userRef(userId).child("wallets").child(viId).update({"so_du": soDuMoi});
  }

  Future<void> congTienVaoVi(String userId, String viId, int soTien) async {
    final ref = _userRef(userId).child("wallets").child(viId).child("so_du");
    await ref.runTransaction((currentData) {
      if (currentData == null) return Transaction.success(soTien);
      final val = (currentData as int? ?? 0);
      return Transaction.success(val + soTien);
    });
  }

  Future<void> truTienTuVi(String userId, String viId, int soTien) async {
    final ref = _userRef(userId).child("wallets").child(viId).child("so_du");
    await ref.runTransaction((currentData) {
      if (currentData == null) return Transaction.success(-soTien);
      final val = (currentData as int? ?? 0);
      return Transaction.success(val - soTien);
    });
  }

  Future<void> capNhatNganSachThang({
    required String userId,
    required int nam,
    required int thang,
    required int soTienNganSach,
  }) async {
    final key = "$nam-$thang";
    await _userRef(userId).child("budgets").child(key).set(soTienNganSach);
  }

  Future<int?> layNganSachThang({
    required String userId,
    required int nam,
    required int thang,
  }) async {
    final key = "$nam-$thang";
    final snapshot = await _userRef(userId).child("budgets").child(key).get();
    if (snapshot.exists) {
      return (snapshot.value as int?);
    }
    return null;
  }

  Future<String> themGiaoDich({
    required String userId,
    required int soTien,
    required String danhMucId,
    required String? viTienId,
    required DateTime ngay,
    String? ghiChu,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final txnRef = _userRef(userId).child("transactions").push();
    final txnId = txnRef.key!;

    final txnData = {
      "so_tien": soTien,
      "danh_muc_id": danhMucId,
      "vi_tien_id": viTienId,
      "ngay": ngay.millisecondsSinceEpoch,
      "ghi_chu": ghiChu,
      "tao_luc": now,
    };

    await txnRef.set(txnData);

    if (viTienId != null) {
      await truTienTuVi(userId, viTienId, soTien);
    }

    return txnId;
  }

  Future<void> suaGiaoDich({
    required String userId,
    required String id,
    required int soTienMoi,
    required String danhMucIdMoi,
    required String? viTienIdMoi,
    required DateTime ngayMoi,
    String? ghiChuMoi,
  }) async {
    final snap = await _userRef(userId).child("transactions").child(id).get();
    if (!snap.exists) return;
    final oldRaw = _normalizeSnapshotValue(snap.value);
    final oldSoTien = (oldRaw['so_tien'] as int?) ?? 0;
    final oldViId = oldRaw['vi_tien_id'] as String?;

    if (oldViId != null) {
      await congTienVaoVi(userId, oldViId, oldSoTien);
    }

    if (viTienIdMoi != null) {
      await truTienTuVi(userId, viTienIdMoi, soTienMoi);
    }

    await _userRef(userId).child("transactions").child(id).update({
      "so_tien": soTienMoi,
      "danh_muc_id": danhMucIdMoi,
      "vi_tien_id": viTienIdMoi,
      "ngay": ngayMoi.millisecondsSinceEpoch,
      "ghi_chu": ghiChuMoi,
    });
  }

  Future<void> xoaGiaoDich(String userId, String id) async {
    final snap = await _userRef(userId).child("transactions").child(id).get();
    if (!snap.exists) return;
    final oldRaw = _normalizeSnapshotValue(snap.value);
    final oldSoTien = (oldRaw['so_tien'] as int?) ?? 0;
    final oldViId = oldRaw['vi_tien_id'] as String?;

    if (oldViId != null) {
      await congTienVaoVi(userId, oldViId, oldSoTien);
    }

    await _userRef(userId).child("transactions").child(id).remove();
  }

  Future<int> tinhTongChiTrongKhoang({
    required String userId,
    required int startMs,
    required int endMs,
    bool chiTuNganSach = false,
  }) async {
    final snap = await _userRef(userId)
        .child("transactions")
        .orderByChild("ngay")
        .startAt(startMs)
        .endAt(endMs - 1)
        .get();

    if (!snap.exists) return 0;

    int sum = 0;
    final data = _normalizeSnapshotValue(snap.value);
    for (final v in data.values) {
      if (v is Map) {
        final soTien = (v['so_tien'] as int?) ?? 0;
        final viId = v['vi_tien_id'];
        if (chiTuNganSach) {
          if (viId == null) sum += soTien;
        } else {
          sum += soTien;
        }
      }
    }
    return sum;
  }

  Future<List<GiaoDich>> layGiaoDichTrongKhoang({
    required String userId,
    required int startMs,
    required int endMs,
  }) async {
    final snap = await _userRef(userId)
        .child("transactions")
        .orderByChild("ngay")
        .startAt(startMs)
        .endAt(endMs - 1)
        .get();

    if (!snap.exists) return [];

    final data = _normalizeSnapshotValue(snap.value);
    final list = data.entries.map((e) {
      final v = e.value;
      if (v is Map) {
        final val = Map<String, Object?>.from(v);
        val['id'] = e.key;
        return GiaoDich.fromMap(val);
      }
      return GiaoDich.fromMap({
        'id': e.key,
        'so_tien': 0,
        'danh_muc_id': '',
        'ngay': startMs,
      });
    }).toList();

    list.sort((a, b) {
      int cmp = b.ngay.compareTo(a.ngay);
      if (cmp != 0) return cmp;
      return b.id.compareTo(a.id);
    });

    return list;
  }

  Future<List<Map<String, Object?>>> thongKeTheoDanhMuc({
    required String userId,
    required int startMs,
    required int endMs,
  }) async {
    final txns = await layGiaoDichTrongKhoang(userId: userId, startMs: startMs, endMs: endMs);
    final cats = await layDanhMuc(userId);
    final catMap = {for (var c in cats) c.id: c};

    final result = <String, int>{};
    for (var t in txns) {
      result[t.danhMucId] = (result[t.danhMucId] ?? 0) + t.soTien;
    }

    return result.entries.map((e) {
      final c = catMap[e.key];
      return {
        "ten": c?.ten ?? "Khác",
        "mau": 0xFF000000,
        "tong_tien": e.value,
      };
    }).toList();
  }

  Future<List<Map<String, Object?>>> thongKeTheoThoiGian({
    required String userId,
    required int nam,
  }) async {
    final start = DateTime(nam, 1, 1).millisecondsSinceEpoch;
    final end = DateTime(nam + 1, 1, 1).millisecondsSinceEpoch;

    final txns = await layGiaoDichTrongKhoang(userId: userId, startMs: start, endMs: end);

    final map = <String, int>{};
    for (var t in txns) {
      final m = t.ngay.month.toString().padLeft(2, '0');
      map[m] = (map[m] ?? 0) + t.soTien;
    }

    return map.entries.map((e) => {"thang": e.key, "tong_tien": e.value}).toList();
  }

  Future<int> layTongChiTieuTheoVi(String userId, String viId) async {
    final snap = await _userRef(userId)
        .child("transactions")
        .orderByChild("vi_tien_id")
        .equalTo(viId)
        .get();

    if (!snap.exists) return 0;

    int sum = 0;
    final data = _normalizeSnapshotValue(snap.value);
    for (var v in data.values) {
      if (v is Map) {
        sum += (v['so_tien'] as int?) ?? 0;
      }
    }
    return sum;
  }
}
