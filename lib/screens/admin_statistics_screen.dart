import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../models/event_model.dart';
import '../models/news_item.dart';
import '../models/user_item.dart';
import '../services/app_state_service.dart';

class AdminStatisticsScreen extends StatefulWidget {
  const AdminStatisticsScreen({super.key});

  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen> {
  _StatView _selectedView = _StatView.activeMembers;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final appState = Provider.of<AppStateService>(context, listen: false);
      await Future.wait([
        appState.refreshEvents(),
        appState.refreshNews(),
        appState.refreshMembers(),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = GoogleFonts.manropeTextTheme(theme.textTheme);

    return Theme(
      data: theme.copyWith(textTheme: textTheme),
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F5FB),
        appBar: AppBar(
          title: Text(
            'Thống kê tổng quan',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: false,
          backgroundColor: const Color(0xFFF2F5FB),
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          actions: [],
        ),
        body: Consumer<AppStateService>(
          builder: (context, appState, _) {
            final events = appState.events;
            final news = appState.news;
            final members = appState.members;

            final isLoading =
                appState.isLoadingEvents || appState.isLoadingNews || appState.isLoadingMembers;

            return RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  appState.refreshEvents(),
                  appState.refreshNews(),
                  appState.refreshMembers(),
                ]);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPageHeader(),
                          const SizedBox(height: 14),
                          _buildKpiRow(events, news, members),
                          const SizedBox(height: 14),
                          if (isLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else
                            _buildDashboardLayout(
                              events: events,
                              news: news,
                              members: members,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330F172A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.analytics_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bảng điều khiển phân tích',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chọn chủ đề bên dưới để tập trung vào biểu đồ bạn cần xem.',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardLayout({
    required List<Event> events,
    required List<NewsItem> news,
    required List<UserItem> members,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 920;
        final chart = _buildSelectedChart(
          view: _selectedView,
          events: events,
          news: news,
          members: members,
        );

        if (!wide) {
          return Column(
            children: [
              _buildViewSelector(compact: true),
              const SizedBox(height: 12),
              chart,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 290,
              child: _buildViewSelector(compact: false),
            ),
            const SizedBox(width: 14),
            Expanded(child: chart),
          ],
        );
      },
    );
  }

  Widget _buildViewSelector({required bool compact}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x110F172A),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bạn muốn xem thống kê gì?',
          style: GoogleFonts.playfairDisplay(
            fontSize: compact ? 16 : 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Bấm vào từng mục để hiển thị biểu đồ tương ứng.',
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ..._viewOptions.map((option) {
          final selected = option.view == _selectedView;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    _selectedView = option.view;
                  });
                },
                child: Ink(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: selected ? option.color.withOpacity(0.12) : const Color(0xFFF8FAFC),
                    border: Border.all(
                      color: selected ? option.color.withOpacity(0.7) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(option.icon, size: 18, color: option.color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          option.label,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: selected ? option.color : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Icon(
                        selected ? Icons.check_circle : Icons.chevron_right,
                        size: 18,
                        color: selected ? option.color : const Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    ));
  }

  Widget _buildSelectedChart({
    required _StatView view,
    required List<Event> events,
    required List<NewsItem> news,
    required List<UserItem> members,
  }) {
    switch (view) {
      case _StatView.activeMembers:
        return _buildActiveMemberChart(members);
      case _StatView.memberStatus:
        return _buildMemberStatusChart(members);
      case _StatView.eventTrend:
        return _buildEventTrendChart(events);
      case _StatView.newsStructure:
        return _buildNewsCategoryChart(news);
    }
  }

  Widget _buildKpiRow(List<Event> events, List<NewsItem> news, List<UserItem> members) {
    final upcoming = events.where((e) => e.isActive).length;
    final openNews = news.where((n) => n.category.toLowerCase() == 'announcement').length;

    final items = [
      _KpiSpec(label: 'Tổng sự kiện', value: '${events.length}', icon: Icons.event, color: const Color(0xFF2563EB)),
      _KpiSpec(label: 'Sắp diễn ra', value: '$upcoming', icon: Icons.schedule, color: const Color(0xFF0EA5E9)),
      _KpiSpec(label: 'Đoàn viên', value: '${members.length}', icon: Icons.group, color: const Color(0xFF16A34A)),
      _KpiSpec(label: 'Thông báo', value: '$openNews', icon: Icons.campaign, color: const Color(0xFFF97316)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 2;
        if (constraints.maxWidth >= 960) {
          columns = 4;
        } else if (constraints.maxWidth >= 560) {
          columns = 2;
        }

        const spacing = 10.0;
        final cardWidth = (constraints.maxWidth - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items
              .map(
                (item) => SizedBox(
                  width: cardWidth,
                  child: _KpiCard(
                    label: item.label,
                    value: item.value,
                    icon: item.icon,
                    color: item.color,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildEventTrendChart(List<Event> events) {
    final now = DateTime.now();
    final labels = <String>[];
    final values = <double>[];

    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final count = events.where((event) {
        return event.dateTime.year == monthDate.year && event.dateTime.month == monthDate.month;
      }).length;
      labels.add('T${monthDate.month}');
      values.add(count.toDouble());
    }

    return _ChartCard(
      title: 'Xu hướng sự kiện 6 tháng',
      subtitle: 'Số lượng sự kiện theo từng tháng',
      child: SizedBox(
        height: 220,
        child: _LineChart(values: values, labels: labels, lineColor: const Color(0xFF2563EB)),
      ),
    );
  }

  Widget _buildActiveMemberChart(List<UserItem> members) {
    final active = members.where((m) => m.status.toLowerCase() == 'active').length;
    final inactive = members.length - active;

    final data = [
      _LabeledValue('Còn sử dụng', active.toDouble(), const Color(0xFF16A34A)),
      _LabeledValue('Ngừng sử dụng', inactive.toDouble(), const Color(0xFFEF4444)),
    ];

    return _ChartCard(
      title: 'Tài khoản đoàn viên còn sử dụng',
      subtitle: 'So sánh tài khoản active và không active',
      child: SizedBox(
        height: 230,
        child: Column(
          children: [
            Expanded(child: _BarChart(data: data)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF334155), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hiện có $active/${members.length} tài khoản đoàn viên còn hoạt động.',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberStatusChart(List<UserItem> members) {
    final active = members.where((m) => m.status.toLowerCase() == 'active').length;
    final pending = members.where((m) => m.status.toLowerCase() == 'pending').length;
    final inactive = members.where((m) => m.status.toLowerCase() == 'inactive').length;
    final alumni = members.where((m) => m.status.toLowerCase() == 'alumni').length;

    final data = [
      _LabeledValue('Hoạt động', active.toDouble(), const Color(0xFF16A34A)),
      _LabeledValue('Chờ duyệt', pending.toDouble(), const Color(0xFFF59E0B)),
      _LabeledValue('Ngưng', inactive.toDouble(), const Color(0xFFEF4444)),
      _LabeledValue('Cựu ĐV', alumni.toDouble(), const Color(0xFF64748B)),
    ];

    return _ChartCard(
      title: 'Trạng thái đoàn viên',
      subtitle: 'Biểu đồ cột theo số lượng trạng thái',
      child: SizedBox(height: 220, child: _BarChart(data: data)),
    );
  }

  Widget _buildNewsCategoryChart(List<NewsItem> news) {
    final newsCount = news.where((n) => n.category.toLowerCase() == 'news').length;
    final announceCount = news.where((n) => n.category.toLowerCase() == 'announcement').length;
    final otherCount = news.length - newsCount - announceCount;

    final data = [
      _LabeledValue('Tin tức', newsCount.toDouble(), const Color(0xFF0EA5E9)),
      _LabeledValue('Thông báo', announceCount.toDouble(), const Color(0xFFF97316)),
      _LabeledValue('Khác', math.max(0, otherCount).toDouble(), const Color(0xFF8B5CF6)),
    ].where((item) => item.value > 0).toList();

    return _ChartCard(
      title: 'Cơ cấu nội dung',
      subtitle: 'Tỷ lệ tin tức và thông báo',
      child: SizedBox(
        height: 220,
        child: Row(
          children: [
            Expanded(
              flex: 6,
              child: _DonutChart(data: data.isEmpty ? [_LabeledValue('Không có', 1, Colors.grey)] : data),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (data.isEmpty
                        ? [_LabeledValue('Không có dữ liệu', 1, Colors.grey)]
                        : data)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: item.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${item.label} (${item.value.toInt()})',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x110F172A),
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiSpec {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiSpec({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x110F172A),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LabeledValue {
  final String label;
  final double value;
  final Color color;

  const _LabeledValue(this.label, this.value, this.color);
}

class _BarChart extends StatelessWidget {
  final List<_LabeledValue> data;

  const _BarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxValue = data.fold<double>(1, (max, item) => item.value > max ? item.value : max);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((item) {
        final ratio = item.value / maxValue;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  item.value.toInt().toString(),
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 130,
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: ratio == 0 ? 0.04 : ratio,
                    child: Container(
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LineChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color lineColor;

  const _LineChart({
    required this.values,
    required this.labels,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _LineChartPainter(values: values, lineColor: lineColor),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: labels
              .map(
                (label) => Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;

  _LineChartPainter({required this.values, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1;

    final paintLine = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintDot = Paint()..color = lineColor;
    final maxValue = values.isEmpty ? 1.0 : values.reduce(math.max).clamp(1, double.infinity);

    for (int i = 0; i < 4; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    if (values.isEmpty) return;

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final dx = values.length == 1 ? size.width / 2 : (size.width * i) / (values.length - 1);
      final dy = size.height - (values[i] / maxValue) * (size.height - 6);
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }

    canvas.drawPath(path, paintLine);

    for (int i = 0; i < values.length; i++) {
      final dx = values.length == 1 ? size.width / 2 : (size.width * i) / (values.length - 1);
      final dy = size.height - (values[i] / maxValue) * (size.height - 6);
      canvas.drawCircle(Offset(dx, dy), 4, paintDot);
      canvas.drawCircle(
        Offset(dx, dy),
        2,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.lineColor != lineColor;
  }
}

class _DonutChart extends StatelessWidget {
  final List<_LabeledValue> data;

  const _DonutChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.fold<double>(0, (sum, item) => sum + item.value);
    final centerText = total <= 0 ? '0' : total.toInt().toString();

    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size.square(170),
          painter: _DonutPainter(data: data),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              centerText,
              style: GoogleFonts.manrope(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Bản ghi',
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<_LabeledValue> data;

  _DonutPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.fold<double>(0, (sum, item) => sum + item.value);
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2.2);
    final strokeWidth = size.width * 0.17;

    final basePaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, 0, math.pi * 2, false, basePaint);

    if (total <= 0) return;

    double start = -math.pi / 2;
    for (final segment in data) {
      final sweep = (segment.value / total) * math.pi * 2;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

enum _StatView {
  activeMembers,
  memberStatus,
  eventTrend,
  newsStructure,
}

class _ViewOption {
  final _StatView view;
  final String label;
  final IconData icon;
  final Color color;

  const _ViewOption({
    required this.view,
    required this.label,
    required this.icon,
    required this.color,
  });
}

const List<_ViewOption> _viewOptions = [
  _ViewOption(
    view: _StatView.activeMembers,
    label: 'Tài khoản dùng',
    icon: Icons.verified_user,
    color: Color(0xFF16A34A),
  ),
  _ViewOption(
    view: _StatView.memberStatus,
    label: 'Trạng thái ĐV',
    icon: Icons.stacked_bar_chart,
    color: Color(0xFFF59E0B),
  ),
  _ViewOption(
    view: _StatView.eventTrend,
    label: 'Xu hướng sự kiện',
    icon: Icons.show_chart,
    color: Color(0xFF2563EB),
  ),
  _ViewOption(
    view: _StatView.newsStructure,
    label: 'Cơ cấu tin',
    icon: Icons.pie_chart,
    color: Color(0xFFF97316),
  ),
];