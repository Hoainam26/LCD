import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../models/event_model.dart';
import '../models/news_item.dart';
import '../services/api_service.dart';
import '../services/app_state_service.dart';
import 'event_detail_screen.dart';
import 'event_management_screen.dart';
import 'news_management_screen.dart';
import 'training_score_management_screen.dart';
import 'admin_statistics_screen.dart';

class AdminDashboardMobile extends StatefulWidget {
  const AdminDashboardMobile({super.key});

  @override
  State<AdminDashboardMobile> createState() => _AdminDashboardMobileState();
}

class _AdminDashboardMobileState extends State<AdminDashboardMobile> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final appState = Provider.of<AppStateService>(context, listen: false);
      await Future.wait([
        appState.refreshEvents(),
        appState.refreshNews(),
        appState.refreshOfficers(),
        appState.refreshMembers(),
        appState.refreshTrainingPeriods(),
      ]);
      await appState.refreshCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = GoogleFonts.manropeTextTheme(theme.textTheme);

    return Theme(
      data: theme.copyWith(textTheme: textTheme),
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Bảng điều khiển',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                final appState =
                    Provider.of<AppStateService>(context, listen: false);
                await Future.wait([
                  appState.refreshEvents(),
                  appState.refreshNews(),
                  appState.refreshOfficers(),
                  appState.refreshMembers(),
                  appState.refreshTrainingPeriods(),
                ]);
              },
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF5F7FF), Color(0xFFFDFEFF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Consumer<AppStateService>(
            builder: (context, appState, _) {
              final events = appState.events;
              final news = appState.news;
              final officers = appState.officers;
              final members = appState.members;

              final upcoming = List<Event>.from(events)
                ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
              final upcomingThree = upcoming.take(3).toList();

              final latestNews = List<NewsItem>.from(news)
                ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
              final latestNewsThree = latestNews.take(3).toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  _buildHero(appState.currentUser),
                  const SizedBox(height: 16),
                  _buildStatsRow(
                    eventsCount: events.length,
                    newsCount: news.length,
                    officerCount: officers.length,
                    memberCount: members.length,
                  ),
                  const SizedBox(height: 18),
                  _buildQuickActions(context),
                  const SizedBox(height: 18),
                  _buildSectionHeader('Sự kiện sắp diễn ra'),
                  const SizedBox(height: 8),
                  if (upcomingThree.isEmpty)
                    _buildEmptyPlaceholder(
                      icon: Icons.event_available,
                      text: 'Chưa có sự kiện nào',
                    )
                  else
                    ...upcomingThree.map((event) => _buildEventTile(context, event)),
                  const SizedBox(height: 20),
                  _buildSectionHeader('Tin tức mới'),
                  const SizedBox(height: 8),
                  if (latestNewsThree.isEmpty)
                    _buildEmptyPlaceholder(
                      icon: Icons.newspaper,
                      text: 'Chưa có tin tức nào',
                    )
                  else
                    ...latestNewsThree
                        .map((item) => _buildNewsTile(context, item))
                        .toList(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHero(Map<String, dynamic>? user) {
    final name = user?['full_name']?.toString() ?? 'Quản trị viên';
    final email = user?['email']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF2FF), Color(0xFFE0F2FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.12),
            ),
            child: const Icon(Icons.verified_user, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  'Quản lý sự kiện, tin tức, đoàn viên trong một màn hình mobile.',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow({
    required int eventsCount,
    required int newsCount,
    required int officerCount,
    required int memberCount,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Sự kiện',
                value: eventsCount.toString(),
                icon: Icons.event,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Tin tức',
                value: newsCount.toString(),
                icon: Icons.article,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Cán bộ',
                value: officerCount.toString(),
                icon: Icons.manage_accounts,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Đoàn viên',
                value: memberCount.toString(),
                icon: Icons.group,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        label: 'Quản lý sự kiện',
        icon: Icons.calendar_month,
        color: AppColors.primary,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EventManagementScreen()),
        ),
      ),
      _QuickAction(
        label: 'Quản lý tin tức',
        icon: Icons.campaign,
        color: AppColors.secondary,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewsManagementScreen()),
        ),
      ),
      _QuickAction(
        label: 'Chấm điểm RL',
        icon: Icons.checklist_rtl,
        color: AppColors.warning,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const TrainingScoreManagementScreen()),
        ),
      ),
      _QuickAction(
        label: 'Thống kê',
        icon: Icons.bar_chart,
        color: AppColors.primaryDark,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminStatisticsScreen()),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Tác vụ nhanh'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: actions.map((a) => _QuickActionButton(action: a)).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildEmptyPlaceholder({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTile(BuildContext context, Event event) {
    void openDetail() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventDetailScreen(event: event),
        ),
      );
    }

    return GestureDetector(
      onTap: openDetail,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
            GestureDetector(
              onTap: openDetail,
              child: _buildEventThumbnail(event.imageUrl),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.dateTimeString,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildEventThumbnail(String? imageUrl) {
    final fallback = Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.event_available, color: AppColors.primary),
    );

    final resolved = ApiService.resolveMediaUrl(imageUrl);
    if (resolved == null || resolved.isEmpty) {
      return fallback;
    }

    final image = resolved.startsWith('http')
        ? Image.network(
            resolved,
            width: 46,
            height: 46,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback,
          )
        : Image.asset(
            resolved,
            width: 46,
            height: 46,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback,
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(width: 46, height: 46, child: image),
    );
  }

  Widget _buildNewsTile(BuildContext context, NewsItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.secondary.withOpacity(0.12),
            ),
            child: const Icon(Icons.newspaper, color: AppColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.publishedAtString,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
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
              color: color.withOpacity(0.14),
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

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionButton extends StatelessWidget {
  final _QuickAction action;

  const _QuickActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - 52) / 2,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(action.icon, color: action.color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                action.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
