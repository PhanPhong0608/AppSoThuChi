import 'package:flutter/material.dart';
import '../be/xu_ly_thu_chi_service.dart';
import '../db/models/danh_muc.dart';

class TrangQuanLyDanhMuc extends StatefulWidget {
  const TrangQuanLyDanhMuc({super.key, required this.service});

  final XuLyThuChiService service;

  @override
  State<TrangQuanLyDanhMuc> createState() => _TrangQuanLyDanhMucState();
}

class _TrangQuanLyDanhMucState extends State<TrangQuanLyDanhMuc>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<DanhMuc> _danhMuc = [];
  bool _loading = true;

  // Colors removed to use Theme.of(context)

  @override
  void initState() {
    super.initState();
    // Start index 0 (Expense) as default
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final list = await widget.service.layDanhMuc();
      setState(() {
        _danhMuc = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Lỗi tải danh mục: $e")));
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _themHoacSuaDanhMuc({DanhMuc? dm}) async {
    final isEdit = dm != null;
    final tenCtrl = TextEditingController(text: dm?.ten ?? "");
    String loai =
        dm?.loai ?? (_tabController.index == 0 ? "expense" : "income");
    
    // Icon & Color State
    int selectedIcon = dm?.icon ?? 0xe3ac; // default category icon
    int selectedColor = dm?.mau ?? 0xFF90A4AE; // default blueGrey


    // Simple preset lists for picker
    final List<int> icons = [
      0xe532, // fastfood
      0xe59c, // shopping_cart
      0xe6e3, // directions_bus
      0xe3e3, // sports_esports
      0xf1bb, // medical_services
      0xe4b6, // phone_iphone
      0xe55d, // school
      0xe04c, // attach_money
      0xe2e2, // card_giftcard
      0xe6e1, // trending_up
      0xe3ac, // category
      0xe935, // fitness_center
      0xe58f, // home
      0xe57a, // flights
      0xe80c, // pets
    ];
    
    final List<int> colors = [
      0xFFE57373, // Red
      0xFFF06292, // Pink
      0xFFBA68C8, // Purple
      0xFF9575CD, // Deep Purple
      0xFF64B5F6, // Blue
      0xFF4FC3F7, // Light Blue
      0xFF4DD0E1, // Cyan
      0xFF4DB6AC, // Teal
      0xFF81C784, // Green
      0xFFAED581, // Light Green
      0xFFFFD54F, // Amber
      0xFFFFB74D, // Orange
      0xFFA1887F, // Brown
      0xFF90A4AE, // Blue Grey
    ];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? "Cài đặt danh mục" : "Thêm danh mục mới"),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: tenCtrl,
                    decoration: const InputDecoration(
                      labelText: "Tên danh mục",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Icon Selection Row
                  const Align(alignment: Alignment.centerLeft, child: Text("Chọn biểu tượng:", style: TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: icons.map((code) => InkWell(
                      onTap: () => setStateDialog(() => selectedIcon = code),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: selectedIcon == code ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.transparent,
                          shape: BoxShape.circle,
                          border: selectedIcon == code ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
                        ),
                        child: Icon(IconData(code, fontFamily: 'MaterialIcons'), size: 24, color: Theme.of(context).colorScheme.onSurface),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Color Selection Row
                   const Align(alignment: Alignment.centerLeft, child: Text("Chọn màu:", style: TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: colors.map((cVal) => InkWell(
                      onTap: () => setStateDialog(() => selectedColor = cVal),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(cVal),
                          shape: BoxShape.circle,
                          border: selectedColor == cVal ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3) : null,
                        ),
                        child: selectedColor == cVal ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                      ),
                    )).toList(),
                  ),
                  
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text("Chi"),
                          value: "expense",
                          groupValue: loai,
                          onChanged: (v) => setStateDialog(() => loai = v!),
                          contentPadding: EdgeInsets.zero,
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text("Thu"),
                          value: "income",
                          groupValue: loai,
                          onChanged: (v) => setStateDialog(() => loai = v!),
                          contentPadding: EdgeInsets.zero,
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          FilledButton(
            // style: Use default theme style (primary color)
            onPressed: () async {
              final ten = tenCtrl.text.trim();
              if (ten.isEmpty) return;

              try {
                if (isEdit) {
                  await widget.service.suaDanhMuc(
                      id: dm.id, ten: ten, loai: loai, icon: selectedIcon, mau: selectedColor);
                } else {
                  await widget.service.themDanhMuc(ten: ten, loai: loai, icon: selectedIcon, mau: selectedColor);
                }
                if (mounted) Navigator.pop(context);
                _loadData(); // Reload list
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text("Lỗi: $e")));
                }
              }
            },
            child: Text(isEdit ? "Lưu" : "Thêm"),
          ),
        ],
      ),
    );
  }

  Future<void> _xoaDanhMuc(DanhMuc dm) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn xóa danh mục '${dm.ten}'?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Không")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Có")),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await widget.service.xoaDanhMuc(dm.id);
        _loadData();
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Lỗi xóa: $e")));
      }
    }
  }

  Widget _buildList(String loai) {
    // Show items with circular background icons
    final list = _danhMuc.where((d) => d.loai == loai).toList();

    if (list.isEmpty) {
      return const Center(child: Text("Chưa có danh mục nào"));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final iconData = IconData(item.icon ?? 0xe3ac, fontFamily: 'MaterialIcons');
        final color = Color(item.mau ?? 0xFF90A4AE);

        return Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: GestureDetector(
                onTap: () => _xoaDanhMuc(item),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent, // Red minus icon as per design
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.remove, color: Colors.white, size: 16),
                ),
              ),
              title: Row(
                children: [
                  Container(
                    width: 40, 
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.3), // Soft background
                      shape: BoxShape.circle, 
                    ),
                    child: Icon(iconData, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    item.ten,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   IconButton(
                    icon: const Icon(Icons.edit, color: Colors.grey),
                    onPressed: () => _themHoacSuaDanhMuc(dm: item),
                  ),
                   const Icon(Icons.menu, color: Colors.grey), // Drag Handle visual
                ],
              ),
            ),
            const Divider(height: 1, indent: 72, endIndent: 16),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Use default theme
      appBar: AppBar(
        title: const Text(
          "Cài đặt danh mục",
        ),
        centerTitle: true,
        // backgroundColor: Use default theme
        elevation: 0,
        // Leading uses default theme color
        actions: const [
           Padding(
             padding: EdgeInsets.only(right: 16.0),
             child: Icon(Icons.search), // Uses default theme color
           )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Theme.of(context).appBarTheme.backgroundColor, 
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
               decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(25),
                ),
                labelColor: Theme.of(context).colorScheme.onPrimary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: "Chi tiêu"),
                  Tab(text: "Thu nhập"),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList("expense"),
          _buildList("income"),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 50,
          child: FilledButton.icon(
             style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
             ),
             onPressed: () => _themHoacSuaDanhMuc(),
             icon: const Icon(Icons.add),
             label: const Text("Thêm danh mục", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
