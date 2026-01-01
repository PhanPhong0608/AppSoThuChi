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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thống kê"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Theo Danh Mục"),
            Tab(text: "Theo Thời Gian"),
          ],
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
        if (data.isEmpty)
          return const Center(child: Text("Chưa có dữ liệu tháng này"));

        double tong = 0;
        for (var e in data) {
          tong += (e['tong_tien'] as int? ?? 0);
        }

        final sections = data.map((e) {
          final val = (e['tong_tien'] as int? ?? 0).toDouble();
          final title = e['ten'] as String;
          // Màu sắc đơn giản hoá: hash string thành color
          final color =
              Colors.primaries[title.hashCode % Colors.primaries.length];
          final percent = (val / tong * 100).toStringAsFixed(1);

          return PieChartSectionData(
            color: color,
            value: val,
            title: '$percent%',
            radius: 50,
            titleStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(() =>
                        _thangDangXem = DateTime(_thangDangXem.year, _thangDangXem.month - 1)),
                  ),
                  Text(
                    "Tháng ${_thangDangXem.month}/${_thangDangXem.year}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setState(() =>
                        _thangDangXem = DateTime(_thangDangXem.year, _thangDangXem.month + 1)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final e = data[index];
                  final val = e['tong_tien'] as int? ?? 0;
                  final title = e['ten'] as String;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors
                          .primaries[title.hashCode % Colors.primaries.length],
                      radius: 8,
                    ),
                    title: Text(title),
                    trailing: Text(NumberFormat.currency(locale: "vi_VN", symbol: "đ")
                        .format(val)),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

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
                color: Colors.blue,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              )
            ],
          );
        });

        return Column(
          children: [
             Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxVal * 1.2, // Chừa khoảng trống bên trên
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false), // Ẩn số tiền bên trái cho đỡ rối
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) => Text(val.toInt().toString()),
                        ),
                      ),
                    ),
                    barGroups: groups,
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                  ),
                ),
              ),
            ),
             const SizedBox(height: 16),
             const Text("Tổng chi tiêu theo từng tháng (Đơn vị: VNĐ)"),
             const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
