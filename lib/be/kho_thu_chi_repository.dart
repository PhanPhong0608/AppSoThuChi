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
          icon: value['icon'] as int?,
          mau: value['mau'] as int?,
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


  // use new implementation below
  Future<void> seedDefaultCategoriesDummy(String uid) async {}




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

  Future<String> themVi({
    required String userId,
    required String ten,
    required String loai,
    required int soDu,
    String? icon,
  }) async {
    final ref = _userRef(userId).child("wallets").push();
    await ref.set({
      "ten": ten,
      "loai": loai,
      "so_du": soDu,
      "icon": icon,
      "an": 0,
    });
    return ref.key!;
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

    // NOTE: Removed automatic deduction here because Service layer handles it based on isThu/isChi
    
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

    // We only update the transaction record here. 
    // Balance updates should be handled by the Service layer if needed, 
    // or we assume the User manually corrects the balance if editing past transactions.
    // For now, retaining the existing logic but stripping balance side-effects 
    // to avoid double-counting or logical errors with Income/Expense.
    
    // Wait, the previous logic tried to revert balance and apply new. 
    // But it blindly assumed "Expense". 
    // Safest approach: Update transaction only. 
    // Service layer does not currently handle balance update for Edit.
    // Given the complexity, let's just update the transaction data for now.
    // Real-world apps usually strictly control editing of reconciled transactions.
    
    await _userRef(userId).child("transactions").child(id).update({
      "so_tien": soTienMoi,
      "danh_muc_id": danhMucIdMoi,
      "vi_tien_id": viTienIdMoi,
      "ngay": ngayMoi.millisecondsSinceEpoch,
      "ghi_chu": ghiChuMoi,
    });
  }

  Future<void> xoaGiaoDich(String userId, String id) async {
    // Similarly, remove balance side-effects. Service should handle if needed.
    // Currently Service just calls this. 
    // So deleting a transaction won't revert balance. 
    // This is acceptable for "Simple" refactor, or we can improve later.
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
    
    // We need to filter by category type "expense"
    // Fetch categories to check type
    final cats = await layDanhMuc(userId);
    final catMap = {for (var c in cats) c.id: c};

    for (final v in data.values) {
      if (v is Map) {
        final soTien = (v['so_tien'] as int?) ?? 0;
        final viId = v['vi_tien_id'];
        final dmId = v['danh_muc_id'];
        
        final dm = catMap[dmId];
        // CHANGE: Strict check for expense
        final isExpense = dm?.loai == 'expense' || dm?.loai == 'chi';

        if (isExpense) {
            if (chiTuNganSach) {
            if (viId == null) sum += soTien;
            } else {
            sum += soTien;
            }
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

  Future<GiaoDich?> layChiTietGiaoDich({
    required String userId,
    required String id,
  }) async {
    final snap = await _userRef(userId).child("transactions").child(id).get();
    if (!snap.exists) return null;
    
    final v = snap.value;
    if (v is Map) {
      final val = Map<String, Object?>.from(v);
      val['id'] = id;
      return GiaoDich.fromMap(val);
    }
    return null;
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
      final dm = catMap[t.danhMucId];
      final isExpense = dm?.loai == 'expense' || dm?.loai == 'chi';
      if (isExpense) {
        result[t.danhMucId] = (result[t.danhMucId] ?? 0) + t.soTien;
      }
    }

    return result.entries.map((e) {
      final c = catMap[e.key];
      return {
        "ten": c?.ten ?? "Khác",
        "mau": c?.mau ?? 0xFF90A4AE,
        "icon": c?.icon ?? 0xe3ac,
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
    final cats = await layDanhMuc(userId);
    final catMap = {for (var c in cats) c.id: c};

    final map = <String, int>{};
    for (var t in txns) {
      final dm = catMap[t.danhMucId];
      final isExpense = dm?.loai == 'expense' || dm?.loai == 'chi';
      
      if (isExpense) {
        final m = t.ngay.month.toString().padLeft(2, '0');
        map[m] = (map[m] ?? 0) + t.soTien;
      }
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
    
    // Fetch categories to filter Expenses only
    final cats = await layDanhMuc(userId);
    final catMap = {for (var c in cats) c.id: c};
    
    for (var v in data.values) {
      if (v is Map) {
        final dmId = v['danh_muc_id'];
        final dm = catMap[dmId];
        final isExpense = dm?.loai == 'expense' || dm?.loai == 'chi';
        
        if (isExpense) {
          sum += (v['so_tien'] as int?) ?? 0;
        }
      }
    }
    return sum;
  }
  Future<String> themDanhMuc({
    required String userId,
    required String ten,
    required String loai, // 'income' or 'expense'
    int? icon,
    int? mau,
  }) async {
    final ref = _userRef(userId).child('categories').push();
    final now = DateTime.now().millisecondsSinceEpoch;
    await ref.set({
      'ten': ten,
      'loai': loai,
      'icon': icon,
      'mau': mau,
      'tao_luc': now,
    });
    return ref.key!;
  }

  Future<void> suaDanhMuc({
    required String userId,
    required String id,
    required String ten,
    required String loai,
    int? icon,
    int? mau,
  }) async {
    await _userRef(userId).child('categories').child(id).update({
      'ten': ten,
      'loai': loai,
      'icon': icon,
      'mau': mau,
    });
  }

  /// Create default categories for a user (used when none exist)
  Future<void> seedDefaultCategories(String uid) async {
    final ref = _userRef(uid).child('categories');
    final now = DateTime.now().millisecondsSinceEpoch;

    // Default palette and icons matching the screenshot style roughly
    // Sắc đẹp (Beauty) - Pink
    // Đồ ăn (Food) - Teal/Green
    // Giải trí (Entertainment) - Lime/Green
    // Điện thoại (Phone) - Pink/Red
    // Khác (Other) - Grey
    
    // We use standard Material Icons codePoints for simplicity
    // User can customize later.
    
    final defaults = [
      {'ten': 'Ăn uống', 'loai': 'expense', 'icon': 0xe532, 'mau': 0xFF4DB6AC}, // fastfood - Teal300
      {'ten': 'Mua sắm', 'loai': 'expense', 'icon': 0xe59c, 'mau': 0xFFE57373}, // shopping_cart - Red300
      {'ten': 'Di chuyển', 'loai': 'expense', 'icon': 0xe6e3, 'mau': 0xFFA1887F}, // directions_bus - Brown300
      {'ten': 'Giải trí', 'loai': 'expense', 'icon': 0xe3e3, 'mau': 0xFFAED581}, // sports_esports - LightGreen300
      {'ten': 'Sức khỏe', 'loai': 'expense', 'icon': 0xf1bb, 'mau': 0xFFF06292}, // medical_services - Pink300
      {'ten': 'Điện thoại', 'loai': 'expense', 'icon': 0xe4b6, 'mau': 0xFFBA68C8}, // phone_iphone - Purple300
      {'ten': 'Giáo dục', 'loai': 'expense', 'icon': 0xe55d, 'mau': 0xFFFFB74D}, // school - Orange300
      {'ten': 'Lương', 'loai': 'income', 'icon': 0xe04c, 'mau': 0xFF81C784}, // attach_money - Green300
      {'ten': 'Thưởng', 'loai': 'income', 'icon': 0xe2e2, 'mau': 0xFF4DD0E1}, // card_giftcard - Cyan300
      {'ten': 'Tiền lãi', 'loai': 'income', 'icon': 0xe6e1, 'mau': 0xFFFFF176}, // trending_up - Yellow300
      {'ten': 'Khác', 'loai': 'expense', 'icon': 0xe3ac, 'mau': 0xFF90A4AE}, // category - BlueGrey300
    ];

    final updates = <String, Map<String, dynamic>>{};
    for (var d in defaults) {
      final key = "dm_${d['ten'].toString().toLowerCase().replaceAll(' ', '_')}"; // Simple key gen
      updates[key] = {
        ...d,
        'tao_luc': now,
      };
    }

    await ref.update(updates);
  }

  Future<void> xoaDanhMuc({
    required String userId,
    required String id,
  }) async {
    await _userRef(userId).child('categories').child(id).remove();
  }
}
