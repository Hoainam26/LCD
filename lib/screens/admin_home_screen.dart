import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/colors.dart';
import '../models/event_model.dart';
import '../models/news_item.dart';
import '../services/api_service.dart';
import '../services/app_state_service.dart';
import '../services/officer_event_registration_service.dart';
import '../widgets/carousel.dart';
import 'event_participants_screen.dart';
import 'event_detail_screen.dart';
import 'event_management_screen.dart';
import 'admin_contact_inbox_screen.dart';
import 'news_management_screen.dart';
import 'training_score_management_screen.dart';
import 'account_profile_screen.dart';
import 'admin_statistics_screen.dart';
import 'admin_member_role_screen.dart';
import 'admin_user_accounts_screen.dart';
import 'admin_officer_event_requests_screen.dart';
import 'officer_khoa_screen.dart';
import 'officer_chi_doan_screen.dart';
import 'news_detail_screen.dart' as news_detail;

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final List<String> _logos = [
    'assets/images/logo12.png',
    'assets/images/fitdnu_logo.png',
  ];

  static const String _adminNotificationsKey =
      'admin_notifications_storage_v1';
  static const String _eventRegistrationSnapshotKey =
      'admin_event_registration_snapshot_v1';

  int _selectedTabIndex = 0;
  bool _isLoadingAdminNotifications = false;
  List<_AdminNotificationItem> _adminNotifications = [];

  int get _adminUnreadNotificationCount =>
      _adminNotifications.where((item) => !item.isRead).length;

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
      await _loadAdminNotifications(appState);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = GoogleFonts.manropeTextTheme(theme.textTheme);

    return Theme(
      data: theme.copyWith(textTheme: textTheme),
      child: Scaffold(
        backgroundColor: AppColors.surfaceColor,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceColor,
          elevation: 0,
          toolbarHeight: 64,
          title: Row(
            children: [
              SizedBox(
                width: 45,
                height: 45,
                child: SimpleCarousel(
                  items: _logos.map((logo) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(logo, fit: BoxFit.contain),
                    );
                  }).toList(),
                  height: 45,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 3),
                  onPageChanged: (_) {},
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LIÊN CHI ĐOÀN',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'Khoa CNTT',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications,
                      color: AppColors.textPrimary, size: 24),
                  onPressed: _openAdminNotifications,
                ),
                if (_adminUnreadNotificationCount > 0)
                  Positioned(
                    right: 6,
                    top: 8,
                    child: _buildNotifyBadge(_adminUnreadNotificationCount),
                  ),
              ],
            ),
          ],
        ),
        body: Consumer<AppStateService>(
          builder: (context, appState, _) {
            return RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  appState.refreshEvents(),
                  appState.refreshNews(),
                  appState.refreshOfficers(),
                  appState.refreshMembers(),
                  appState.refreshTrainingPeriods(),
                ]);
                await _loadAdminNotifications(appState);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                children: [
                  _buildStatisticsSection(appState),
                  const SizedBox(height: 18),
                  _buildManagementSection(context),
                  const SizedBox(height: 18),
                  _buildLatestEventsSection(appState),
                  const SizedBox(height: 18),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: _buildBottomNavigation(context),
      ),
    );
  }

  Widget _buildStatisticsSection(AppStateService appState) {
    final totalMembers = appState.members.length;
    final totalEvents = appState.events.where((e) => e.isActive).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 Số liệu tổng quan',
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          totalMembers.toString(),
                          style: GoogleFonts.manrope(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+12%',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4CAF50),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Đoàn viên',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          totalEvents.toString().padLeft(2, '0'),
                          style: GoogleFonts.manrope(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Mới',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Sự kiện',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotifyBadge(int count) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(
        minWidth: 18,
        minHeight: 18,
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildManagementSection(BuildContext context) {
    final menuItems = [
      (label: 'Quản lý Khóa', icon: Icons.school_outlined, onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OfficerKhoaScreen()),
        );
      }),
      (label: 'Chi đoàn', icon: Icons.account_tree_outlined, onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OfficerChiDoanScreen()),
        );
      }),
      (label: 'Đoàn viên', icon: Icons.people_outline, onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminMemberRoleScreen()),
        );
      }),
      (label: 'Tài khoản', icon: Icons.manage_accounts_outlined, onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminUserAccountsScreen()),
        );
      }),
      (label: 'Sự kiện', icon: Icons.event_outlined, onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EventManagementScreen()),
        );
      }),
      (label: 'Tin tức', icon: Icons.newspaper_outlined, onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewsManagementScreen()),
        );
      }),
      (label: 'Rèn luyện', icon: Icons.checklist_rtl, onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TrainingScoreManagementScreen()),
        );
      }),
      (label: 'Thống kê', icon: Icons.bar_chart_outlined, onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminStatisticsScreen()),
        );
      }),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⚙️ Quản lý hệ thống',
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.05,
          children: menuItems.map((item) {
            return GestureDetector(
              onTap: item.onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, color: AppColors.primary, size: 26),
                    const SizedBox(height: 8),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLatestEventsSection(AppStateService appState) {
    final upcoming = List<Event>.from(appState.events)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final upcomingThree = upcoming.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '⚡ Hoạt động mới nhất',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EventManagementScreen()),
                );
              },
              child: Text(
                'Xem tất cả',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (upcomingThree.isEmpty)
          Center(
            child: Text(
              'Chưa có sự kiện nào',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          Column(
            children: upcomingThree.map((event) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.event, color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            event.dateTimeString,
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        border: Border(
          top: BorderSide(
            color: AppColors.borderColor,
          ),
        ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surfaceColor,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        currentIndex: _selectedTabIndex,
        elevation: 0,
        showUnselectedLabels: true,
        onTap: (index) {
          setState(() => _selectedTabIndex = index);
          switch (index) {
            case 0:
              // Stay on home - do nothing
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminMemberRoleScreen()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EventManagementScreen()),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccountProfileScreen()),
              );
              break;
            default:
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_outline),
            activeIcon: const Icon(Icons.people),
            label: 'Quản lý',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.event_outlined),
            activeIcon: const Icon(Icons.event),
            label: 'Sự kiện',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }

  Future<void> _openAdminNotifications() async {
    final appState = Provider.of<AppStateService>(context, listen: false);
    await _loadAdminNotifications(appState);
    if (!mounted) return;
    _showAdminNotifications(appState);
  }

  Future<void> _loadAdminNotifications(AppStateService appState) async {
    if (!mounted) return;
    setState(() {
      _isLoadingAdminNotifications = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      final rawStoredNotifications =
          prefs.getString(_adminNotificationsKey) ?? '[]';
      final storedList = (jsonDecode(rawStoredNotifications) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(_AdminNotificationItem.fromJson)
          .toList();

      final merged = <String, _AdminNotificationItem>{
        for (final item in storedList) item.id: item,
      };

      final contactItems = await ApiService.getContactMessages(limit: 120);
      for (final raw in contactItems.whereType<Map<String, dynamic>>()) {
        final id = raw['id']?.toString();
        if (id == null || id.isEmpty) {
          continue;
        }

        final notificationId = 'contact_$id';
        if (merged.containsKey(notificationId)) {
          continue;
        }

        final fullName = (raw['full_name'] ?? raw['fullName'] ?? 'Đoàn viên')
            .toString()
            .trim();
        final topic = (raw['topic'] ?? 'Liên hệ hỗ trợ').toString().trim();
        final createdAt = _parseApiDateTime(
          raw['created_at']?.toString() ?? raw['createdAt']?.toString(),
        );

        merged[notificationId] = _AdminNotificationItem(
          id: notificationId,
          title: 'Liên hệ mới',
          message: '$fullName: $topic',
          type: 'contact_message',
          createdAt: createdAt,
          relatedId: id,
          isRead: false,
        );
      }

      final rawSnapshot = prefs.getString(_eventRegistrationSnapshotKey) ?? '{}';
      final snapshotJson = jsonDecode(rawSnapshot) as Map<String, dynamic>;
      final eventRegistrationSnapshot = <String, int>{
        for (final entry in snapshotJson.entries)
          entry.key: int.tryParse(entry.value.toString()) ?? 0,
      };

      for (final event in appState.events) {
        final participants = await ApiService.getEventParticipants(event.id);
        final currentCount = participants.length;
        final previousCount =
            eventRegistrationSnapshot[event.id] ?? currentCount;

        if (currentCount > previousCount) {
          final delta = currentCount - previousCount;
          final notificationId = 'event_${event.id}_$currentCount';
          if (!merged.containsKey(notificationId)) {
            merged[notificationId] = _AdminNotificationItem(
              id: notificationId,
              title: 'Đăng ký hoạt động mới',
              message: '${event.title}: +$delta đăng ký mới',
              type: 'event_registration',
              createdAt: DateTime.now(),
              relatedId: event.id,
              isRead: false,
            );
          }
        }

        eventRegistrationSnapshot[event.id] = currentCount;
      }

      final officerRequests =
          await OfficerEventRegistrationService.getPendingRequests();
      for (final request in officerRequests) {
        final notificationId = 'officer_request_${request.id}';
        if (merged.containsKey(notificationId)) {
          continue;
        }

        merged[notificationId] = _AdminNotificationItem(
          id: notificationId,
          title: 'Yêu cầu đăng ký từ cán bộ',
          message:
              '${request.officerName} (${request.officerUnit}) gửi ${request.memberIds.length} đoàn viên cho "${request.eventTitle}"',
          type: 'officer_event_request',
          createdAt: request.createdAt,
          relatedId: request.id,
          isRead: false,
        );
      }

      final mergedList = merged.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final trimmedList = mergedList.take(120).toList();

      await prefs.setString(
        _adminNotificationsKey,
        jsonEncode(trimmedList.map((item) => item.toJson()).toList()),
      );
      await prefs.setString(
        _eventRegistrationSnapshotKey,
        jsonEncode(eventRegistrationSnapshot),
      );

      if (!mounted) return;
      setState(() {
        _adminNotifications = trimmedList;
        _isLoadingAdminNotifications = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingAdminNotifications = false;
      });
    }
  }

  Future<void> _markAdminNotificationAsRead(String id) async {
    final index = _adminNotifications.indexWhere((item) => item.id == id);
    if (index == -1 || _adminNotifications[index].isRead) {
      return;
    }

    setState(() {
      _adminNotifications[index] = _adminNotifications[index].copyWith(
        isRead: true,
      );
    });
    await _saveAdminNotifications();
  }

  Future<void> _markAllAdminNotificationsAsRead() async {
    setState(() {
      _adminNotifications = _adminNotifications
          .map((item) => item.copyWith(isRead: true))
          .toList();
    });
    await _saveAdminNotifications();
  }

  Future<void> _saveAdminNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _adminNotificationsKey,
      jsonEncode(_adminNotifications.map((item) => item.toJson()).toList()),
    );
  }

  void _showAdminNotifications(AppStateService appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final notifications = _adminNotifications;

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                      color: Colors.white,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {
                              if (Navigator.canPop(sheetContext)) {
                                Navigator.pop(sheetContext);
                              }
                            },
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: AppColors.textPrimary,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                          ),
                          const Expanded(
                            child: Center(
                              child: Text(
                                'Thông báo',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 28, height: 28),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    if (_isLoadingAdminNotifications)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      )
                    else if (notifications.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.notifications_off,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Chưa có thông báo quản trị',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: notifications.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final item = notifications[index];
                            return ListTile(
                              onTap: () async {
                                if (!item.isRead) {
                                  await _markAdminNotificationAsRead(item.id);
                                  setSheetState(() {});
                                }
                                if (!mounted) return;
                                if (Navigator.canPop(sheetContext)) {
                                  Navigator.pop(sheetContext);
                                }
                                _openAdminNotificationTarget(item, appState);
                              },
                              leading: CircleAvatar(
                                backgroundColor: item.isRead
                                    ? Colors.grey[200]
                                    : const Color(0xFF1E3A8A).withOpacity(0.1),
                                child: Icon(
                                  item.type == 'event_registration'
                                    ? Icons.how_to_reg
                                    : item.type == 'officer_event_request'
                                      ? Icons.group_add
                                      : Icons.contact_mail_outlined,
                                  color: item.isRead
                                      ? Colors.grey[600]
                                      : const Color(0xFF1E3A8A),
                                ),
                              ),
                              title: Text(
                                item.title,
                                style: TextStyle(
                                  fontWeight: item.isRead
                                      ? FontWeight.w500
                                      : FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(item.message),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatTime(item.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openAdminNotificationTarget(
    _AdminNotificationItem item,
    AppStateService appState,
  ) {
    if (item.type == 'officer_event_request') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdminOfficerEventRequestsScreen(
            initialRequestId: item.relatedId,
          ),
        ),
      );
      return;
    }

    if (item.type == 'event_registration' && item.relatedId != null) {
      Event? matchedEvent;
      for (final event in appState.events) {
        if (event.id == item.relatedId) {
          matchedEvent = event;
          break;
        }
      }

      if (matchedEvent != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EventParticipantsScreen(event: matchedEvent!),
          ),
        );
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const EventManagementScreen()),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminContactInboxScreen(
          initialMessageId: item.relatedId,
        ),
      ),
    );
  }

  DateTime _parseApiDateTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return DateTime.now();
    }
    return DateTime.tryParse(value.trim()) ?? DateTime.now();
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} $hour:$minute';
  }

  Widget _buildHero(Map<String, dynamic>? user) {
    final name = user?['full_name']?.toString() ?? 'Quản trị viên';
    final email = user?['email']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
              color: Colors.white.withOpacity(0.14),
            ),
            child: const Icon(Icons.verified_user, color: Colors.white),
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
                    color: Colors.white,
                  ),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  'Quản lý sự kiện, tin tức, đoàn viên trong một màn hình mobile.',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Admin',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralCatalogSection(BuildContext context) {
    final cards = [
      _CatalogCardData(
        label: 'Khóa',
        icon: Icons.school_outlined,
        color: const Color(0xFF2563EB),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OfficerKhoaScreen()),
        ),
      ),
      _CatalogCardData(
        label: 'Chi đoàn',
        icon: Icons.account_tree_outlined,
        color: const Color(0xFF0EA5E9),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OfficerChiDoanScreen()),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Danh mục chung'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards.map((card) => _CatalogCard(data: card)).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        label: 'Quản lý tổ chức',
        icon: Icons.account_tree,
        color: AppColors.primary,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OfficerChiDoanScreen()),
        ),
      ),
      _QuickAction(
        label: 'Quản lý đoàn viên',
        icon: Icons.group,
        color: AppColors.secondary,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminMemberRoleScreen()),
        ),
      ),
      _QuickAction(
        label: 'Quản lý tài khoản người dùng',
        icon: Icons.manage_accounts,
        color: AppColors.warning,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminUserAccountsScreen(),
          ),
        ),
      ),
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
        label: 'Điểm rèn luyện',
        icon: Icons.checklist_rtl,
        color: AppColors.warning,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TrainingScoreManagementScreen(),
          ),
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
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: actions.map((a) => _QuickActionButton(action: a)).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildEmptyPlaceholder({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 14,
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
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F0F172A),
              blurRadius: 14,
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
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
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
        gradient: const LinearGradient(
          colors: [Color(0xFFDBEAFE), Color(0xFFE0F2FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.event_available, color: Color(0xFF2563EB)),
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
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => news_detail.NewsDetailScreen(news: item),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F0F172A),
              blurRadius: 14,
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
                gradient: const LinearGradient(
                  colors: [Color(0xFFDCFCE7), Color(0xFFD1FAE5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.newspaper, color: Color(0xFF059669)),
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
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

class _AdminNotificationItem {
  final String id;
  final String title;
  final String message;
  final String type;
  final DateTime createdAt;
  final String? relatedId;
  final bool isRead;

  const _AdminNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.relatedId,
  });

  _AdminNotificationItem copyWith({bool? isRead}) {
    return _AdminNotificationItem(
      id: id,
      title: title,
      message: message,
      type: type,
      createdAt: createdAt,
      relatedId: relatedId,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'relatedId': relatedId,
      'isRead': isRead,
    };
  }

  factory _AdminNotificationItem.fromJson(Map<String, dynamic> json) {
    return _AdminNotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      relatedId: json['relatedId']?.toString(),
      isRead: json['isRead'] == true,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F0F172A),
              blurRadius: 14,
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
      ),
    );
  }
}

class _CatalogCardData {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _CatalogCardData({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _CatalogCard extends StatelessWidget {
  final _CatalogCardData data;

  const _CatalogCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - 44) / 2,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F0F172A),
              blurRadius: 14,
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
                color: data.color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data.icon, color: data.color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.label,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
          ],
        ),
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
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F0F172A),
              blurRadius: 14,
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
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
