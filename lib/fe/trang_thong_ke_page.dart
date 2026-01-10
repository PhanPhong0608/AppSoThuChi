import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../be/xu_ly_thu_chi_service.dart';

class TrangThongKePage extends StatefulWidget {
  const TrangThongKePage({
    super.key,
    required this.taiKhoanId,
    required this.service,
  });

  final String taiKhoanId;
  final XuLyThuChiService service;

  @override
  State<TrangThongKePage> createState() => _TrangThongKePageState();
}

class _TrangThongKePageState extends State<TrangThongKePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _thangDangXem = DateTime.now();
  int _namDangXem = DateTime.now().year;

  // Define colors
  // Removed hardcoded colors to use Theme.of(context)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // backgroundColor: Use default theme background
      appBar: AppBar(
        elevation: 0,
        // backgroundColor: Use default theme primary/surface
        title: const Text("Thống kê"),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(25),
              ),
              labelColor: colorScheme.onPrimary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(child: Text("Theo Danh Mục", style: TextStyle(fontWeight: FontWeight.bold))),
                Tab(child: Text("Theo Thời Gian", style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBieuDoTron(),
          _buildBieuDoCot(),
        ],
      ),
    );
  }

  // --- Biểu đồ tròn (Theo danh mục) ---
  Widget _buildBieuDoTron() {
    return FutureBuilder<List<Map<String, Object?>>>(
      future: widget.service.layThongKeTheoDanhMuc(
          taiKhoanId: widget.taiKhoanId, thang: _thangDangXem),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final data = snapshot.data!;
        // Tính tổng
        double tong = 0;
        for (var e in data) {
          tong += (e['tong_tien'] as int? ?? 0);
        }

        // Sử dụng màu từ danh mục (nếu có)
        // Cần map id danh mục sang màu/tên để hiển thị đúng
        // Tuy nhiên API hiện tại trả về list Map, có thể chứa 'ten' và 'danh_muc_id'?
        // Kiểm tra lại service layThongKeTheoDanhMuc: nó join với categories rồi trả về 'ten', 'loai', 'tong_tien'.
        // Để lấy màu, ta cần sửa lại backend một chút hoặc load danh mục ở client và map.
        // Tạm thời, giả sử backend trả về 'mau' hoặc ta load danh mục để map.

        // Cách nhanh nhất bây giờ: Service layThongKeTheoDanhMuc hiện tại chỉ trả về tên.
        // Ta cần sửa Service/Repo trả thêm 'mau' và 'icon'.
        
        // NHƯNG, để tránh sửa backend quá nhiều, ta có thể load tất cả danh mục về cache map.
        // Hoặc palette dự phòng.
        // Updated Palette to be safer for dark mode (avoid too dark colors)
        final List<Color> fallbackPalette = [
          Colors.orange, Colors.blue, Colors.green, Colors.pink, Colors.purple, Colors.teal, Colors.redAccent, Colors.amber,
          Colors.indigo, Colors.cyan,
        ];

        final sections = data.asMap().entries.map((entry) {
            final index = entry.key;
            final e = entry.value;
            final val = (e['tong_tien'] as int? ?? 0).toDouble();
            
            // Try parse color from map if backend provides it, else fallback
            Color color;
            if (e['mau'] != null && e['mau'] is int) {
                 color = Color(e['mau'] as int);
            } else {
                 color = fallbackPalette[index % fallbackPalette.length];
            }

            return PieChartSectionData(
              color: color,
              value: val,
              showTitle: false, 
              radius: 25, 
            );
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Thanh chọn tháng
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => setState(() => _thangDangXem =
                            DateTime(_thangDangXem.year, _thangDangXem.month - 1))),
                    Column(
                      children: [
                        Text(
                          "Tháng ${_thangDangXem.month}/${_thangDangXem.year}",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Tổng chi: ${NumberFormat.currency(locale: "vi_VN", symbol: "đ").format(tong)}",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => setState(() => _thangDangXem =
                            DateTime(_thangDangXem.year, _thangDangXem.month + 1))),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Biểu đồ Donut với Card
              if (data.isEmpty)
                const SizedBox(
                    height: 200, child: Center(child: Text("Chưa có dữ liệu tháng này")))
              else
                Card(
                  elevation: 4,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: SizedBox(
                      height: 250,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sections: sections,
                              centerSpaceRadius: 70,
                              sectionsSpace: 4,
                              startDegreeOffset: -90,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text("Tổng chi tiêu",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(
                                NumberFormat.compact(locale: "vi_VN").format(tong), // Rút gọn số cho đẹp
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),
              
              // Danh sách chi tiết
              if (data.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Chi tiết",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                ...data.asMap().entries.map((entry) {
                  final index = entry.key;
                  final e = entry.value;
                  final val = (e['tong_tien'] as int? ?? 0).toDouble();
                  final title = e['ten'] as String;
                  
                  Color color;
                  if (e['mau'] != null && e['mau'] is int) {
                       color = Color(e['mau'] as int);
                  } else {
                       color = fallbackPalette[index % fallbackPalette.length];
                  }

                  IconData iconData = Icons.category;
                  if (e['icon'] != null && e['icon'] is int) {
                      iconData = IconData(e['icon'] as int, fontFamily: 'MaterialIcons');
                  }

                  final percent = tong > 0 ? (val / tong) : 0.0;
 
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
           
                    ),
                    child: Row(
                      children: [
                        // Icon Circle
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(iconData, color: color, size: 20),
                        ),
                        const SizedBox(width: 16),
                        // Thông tin
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16)),
                                  Text(
                                    NumberFormat.currency(
                                            locale: "vi_VN", symbol: "đ")
                                        .format(val),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Progress Bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percent,
                                  backgroundColor: Colors.grey[200],
                                  color: color,
                                  minHeight: 6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${(percent * 100).toStringAsFixed(1)}%",
                                style: TextStyle(
                                    fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ]
            ],
          ),
        );
      },
    );
  }

  // --- Biểu đồ cột (Theo năm) ---
  // --- Biểu đồ cột (Theo năm) ---
  Widget _buildBieuDoCot() {
    return FutureBuilder<List<Map<String, Object?>>>(
      future: widget.service
          .layThongKeTheoNam(taiKhoanId: widget.taiKhoanId, nam: _namDangXem),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final data = snapshot.data!;
        // Tạo map tháng -> tiền
        final mapData = <int, double>{};
        double maxVal = 0;

        for (var e in data) {
          final t = int.tryParse(e['thang'].toString()) ?? 1;
          final v = (e['tong_tien'] as int? ?? 0).toDouble();
          mapData[t] = v;
          if (v > maxVal) maxVal = v;
        }

        final groups = List.generate(12, (index) {
          final thang = index + 1;
          final val = mapData[thang] ?? 0;
          return BarChartGroupData(
            x: thang,
            barRods: [
              BarChartRodData(
                toY: val,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.tertiary,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 12, // Mỏng hơn chút cho thanh thoát
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                    show: true, toY: maxVal * 1.1, color: Colors.grey[100]), // Nền mờ phía sau
              )
            ],
          );
        });

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
               // Thanh chọn năm
              Container(
                 decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setState(() => _namDangXem--),
                    ),
                    Text(
                      "Năm $_namDangXem",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => setState(() => _namDangXem++),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Card(
                elevation: 4,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                 child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text("Biểu đồ chi tiêu theo tháng",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 300,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: maxVal * 1.25, 
                            barTouchData: BarTouchData(
                              enabled: true, 
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (group) => Colors.grey[800]!,
                                tooltipPadding: const EdgeInsets.all(8),
                                tooltipMargin: 8,
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  return BarTooltipItem(
                                    NumberFormat.compact(locale: "vi_VN").format(rod.toY),
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (val, meta) => Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      "T${val.toInt()}",
                                      style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            barGroups: groups,
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: maxVal > 0 ? maxVal / 5 : 1000000,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Colors.grey[200],
                                strokeWidth: 1,
                                dashArray: [5, 5],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
