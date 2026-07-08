import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../services/api_service.dart';
import '../widgets/carousel.dart';
import '../services/app_state_service.dart';
import '../models/news_item.dart';
import '../models/user_item.dart';
import '../models/event_model.dart';
import '../models/training_score.dart';
import 'event_detail_screen.dart';
import 'officer_event_detail_screen.dart';
import 'news_detail_screen.dart';
import 'event_management_screen.dart';
import 'news_management_screen.dart';
import 'training_score_management_screen.dart';
import 'training_score_my_screen.dart';
import 'officer_khoa_screen.dart';
import 'officer_chi_doan_screen.dart';
import 'login_screen.dart';
import 'account_profile_screen.dart';
import 'account_change_password_screen.dart';
import 'event_history_screen.dart';
import 'officer_event_registration_screen.dart';
import '../services/officer_event_registration_service.dart';

class OfficerHomeScreen extends StatefulWidget {
  const OfficerHomeScreen({super.key});

  @override
  State<OfficerHomeScreen> createState() => _OfficerHomeScreenState();
}

class _OfficerHomeScreenState extends State<OfficerHomeScreen> {
  final List<String> _logos = [
    'assets/images/logo12.png',
    'assets/images/fitdnu_logo.png',
  ];

  final List<String> _bannerImages = [
    'assets/images/banner1.jpg',
    'assets/images/banner2.jpg',
    'assets/images/banner3.jpg',
    'assets/images/banner4.jpg',
  ];

  final TextEditingController _memberSearchController = TextEditingController();
  String _memberStatusFilter = 'Tất cả';
  String _memberSearchQuery = '';
  String _memberClassFilter = 'all';

  int _currentTab = 0;
  List<OfficerEventRegistrationRequest> _officerRequests = [];
  Set<String> _officerReadSignatures = {};
  int _officerUnreadRequestCount = 0;
  bool _homeAnimated = false;
  int _currentBannerIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppStateService>(context, listen: false);
      appState.refreshEvents();
      appState.refreshNews();
      appState.refreshMembers();
      appState.refreshOfficers();
      appState.refreshMyEventRegistrations();
      _loadOfficerRequests();
      if (mounted) {
        setState(() {
          _homeAnimated = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _memberSearchController.dispose();
    super.dispose();
  }

  Future<String> _computeClassRank(AppStateService appState, int periodId) async {
    try {
      final currentIdRaw = appState.currentUser?['id'] ?? appState.currentUser?['user_id'] ?? appState.currentUser?['memberId'];
      final currentId = int.tryParse(currentIdRaw?.toString() ?? '') ?? 0;
      final currentUnitIdRaw = appState.currentUser?['unit_id'] ?? appState.currentUser?['unitId'];
      final currentUnitId = currentUnitIdRaw is int ? currentUnitIdRaw : int.tryParse(currentUnitIdRaw?.toString() ?? '');
      final className = _resolveCurrentClassName(appState);
      if (currentId == 0 || className.trim().isEmpty) return '--';

      final items = await ApiService.getTrainingScores(periodId: periodId);
      final scores = items.map((i) => TrainingScore.fromApi(i)).toList();

      final classScores = <TrainingScore>[];
      for (final s in scores) {
        final user = _findUserById(appState, s.userId);
        if (user == null) continue;
        final userUnitId = user.unitId;
        final userClass = (user.unitName ?? '').trim();
        final matchesUnit = currentUnitId != null && userUnitId != null && userUnitId == currentUnitId;
        final matchesClassName = userClass.isNotEmpty && userClass == className;
        if (matchesUnit || matchesClassName) classScores.add(s);
      }

      if (classScores.isEmpty) return '--';
      classScores.sort((a, b) => b.totalScore.compareTo(a.totalScore));
      final idx = classScores.indexWhere((s) => s.userId == currentId);
      if (idx == -1) return '--';
      return '${idx + 1}/${classScores.length}';
    } catch (e) {
      return '--';
    }
  }

  String _resolveCurrentClassName(AppStateService appState) {
    final directName = (appState.currentUser?['unit_name'] ??
            appState.currentUser?['unitName'] ??
            appState.currentUser?['unit'])
        ?.toString()
        .trim() ??
        '';
    if (directName.isNotEmpty) return directName;

    final currentIdRaw = appState.currentUser?['id'] ??
        appState.currentUser?['user_id'] ??
        appState.currentUser?['memberId'];
    final currentId = int.tryParse(currentIdRaw?.toString() ?? '') ?? 0;
    if (currentId != 0) {
        final currentUser = _findUserById(appState, currentId);
      final resolved = currentUser?.unitName?.trim() ?? '';
      if (resolved.isNotEmpty) return resolved;
    }

    final currentUnitIdRaw = appState.currentUser?['unit_id'] ?? appState.currentUser?['unitId'];
    final currentUnitId = currentUnitIdRaw is int
        ? currentUnitIdRaw
        : int.tryParse(currentUnitIdRaw?.toString() ?? '');
    if (currentUnitId == null) return '';

    for (final user in [...appState.members, ...appState.officers]) {
      if (user.unitId == currentUnitId && (user.unitName ?? '').trim().isNotEmpty) {
        return user.unitName!.trim();
      }
    }
    return '';
  }

  UserItem? _findUserById(AppStateService appState, int userId) {
    for (final user in appState.members) {
      if (user.id == userId) return user;
    }
    for (final user in appState.officers) {
      if (user.id == userId) return user;
    }
    return null;
  }

  void _onNavTap(int index) {
    if (!mounted) return;
    setState(() {
      _currentTab = index;
    });
  }

  Future<void> _loadOfficerRequests() async {
    final appState = Provider.of<AppStateService>(context, listen: false);
    if (appState.currentUser == null) {
      await appState.refreshCurrentUser();
    }
    final officerId = (appState.currentUser?['id'] ?? '').toString();
    if (officerId.isEmpty) return;
    final requests =
        await OfficerEventRegistrationService.getByOfficer(officerId);
    final readSignatures = await OfficerEventRegistrationService.getReadSignatures();
    final unreadCount = requests
        .where(
          (request) => !readSignatures.contains(
            OfficerEventRegistrationService.signatureFor(request),
          ),
        )
        .length;
    if (!mounted) return;
    setState(() {
      _officerRequests = requests;
      _officerReadSignatures = readSignatures;
      _officerUnreadRequestCount = unreadCount;
    });
  }

  Future<void> _showOfficerNotifications(AppStateService appState) async {
    await _loadOfficerRequests();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Thông báo',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      ..._officerRequests.take(8).map((request) {
                        final signature = OfficerEventRegistrationService.signatureFor(request);
                        final isRead = _officerReadSignatures.contains(signature);
                        final title = request.status == 'approved'
                            ? 'Yêu cầu được duyệt'
                            : request.status == 'rejected'
                                ? 'Yêu cầu bị từ chối'
                                : 'Yêu cầu chờ duyệt';
                        final color = request.status == 'approved'
                            ? Colors.green
                            : request.status == 'rejected'
                                ? Colors.red
                                : Colors.orange;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          onTap: () async {
                            if (!isRead) {
                              await OfficerEventRegistrationService.markAsRead(request);
                              await _loadOfficerRequests();
                            }
                            if (!mounted) return;
                            if (Navigator.canPop(sheetContext)) {
                              Navigator.pop(sheetContext);
                            }
                          },
                          leading: CircleAvatar(
                            backgroundColor: isRead
                                ? Colors.grey[200]
                                : color.withOpacity(0.12),
                            child: Icon(Icons.notifications, color: color),
                          ),
                          title: Text(
                            title,
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                              '${request.eventTitle} • ${request.memberIds.length} đoàn viên'),
                        );
                      }),
                      if (_officerRequests.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text('Chưa có thông báo mới.'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final textTheme = GoogleFonts.manropeTextTheme(baseTheme.textTheme);

    return Theme(
      data: baseTheme.copyWith(textTheme: textTheme),
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: _buildAppBar(),
        body: Consumer<AppStateService>(
          builder: (context, appState, _) => _buildBody(),
        ),
        bottomNavigationBar: Consumer<AppStateService>(
          builder: (context, appState, _) => _buildBottomNav(appState),
        ),
      ),
    );
  }

  // ================= APP BAR =================
  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      toolbarHeight: 65,
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
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
          ),
        ],
      ),
      actions: [
        Consumer<AppStateService>(
          builder: (context, appState, _) {
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: AppColors.textPrimary, size: 24),
                  onPressed: () => _showOfficerNotifications(appState),
                ),
                if (_officerUnreadRequestCount > 0)
                  Positioned(
                    right: 6,
                    top: 8,
                    child: _buildNotifyBadge(_officerUnreadRequestCount),
                  ),
              ],
            );
          },
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
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      child: Text(
        '$count',
        style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ================= BODY =================
  Widget _buildBody() {
    switch (_currentTab) {
      case 1:
        return const OfficerEventRegistrationScreen();
      case 2:
        return _buildMembersTab();
      case 3:
        return _buildStatisticsTab();
      case 4:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  // ================= HOME TAB =================
  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: () async {
        final appState = Provider.of<AppStateService>(context, listen: false);
        await appState.refreshEvents();
        await appState.refreshNews();
        await appState.refreshMembers();
        await appState.refreshOfficers();
      },
      child: AnimatedSlide(
        offset: _homeAnimated ? Offset.zero : const Offset(0, 0.02),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _homeAnimated ? 1 : 0,
          duration: const Duration(milliseconds: 420),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: _buildBannerCarousel(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _bannerImages.length,
                        (index) => Container(
                          width: _currentBannerIndex == index ? 14 : 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: _currentBannerIndex == index
                                ? const Color(0xFF1E3A8A)
                                : const Color(0xFFD1D5DB),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Consumer<AppStateService>(
                      builder: (context, appState, _) {
                        return _buildTrainingSummaryCard(appState);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _buildHomeSectionTitle(
                      'Hoạt động sắp tới',
                      actionLabel: 'Khám phá',
                      onAction: () => setState(() => _currentTab = 1),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Consumer<AppStateService>(
                    builder: (context, appState, _) {
                      final upcoming = appState.events
                          .where((event) => event.isUpcoming)
                          .toList()
                        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
                      final upcomingTop = upcoming.take(4).toList();

                      if (appState.isLoadingEvents) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (upcomingTop.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: _buildHomeEmpty('Chưa có hoạt động sắp tới'),
                        );
                      }

                      return SizedBox(
                        height: _upcomingCardHeight(context),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          scrollDirection: Axis.horizontal,
                          itemCount: upcomingTop.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            return _buildUpcomingEventCard(
                              upcomingTop[index],
                              appState,
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _buildHomeSectionTitle('Tin tức & Thông báo'),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _buildOfficerNewsSection(),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerCarousel() {
    return SimpleCarousel(
      items: _bannerImages.map((image) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0x1A0F172A),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              image,
              fit: BoxFit.cover,
            ),
          ),
        );
      }).toList(),
      height: 200,
      autoPlay: true,
      autoPlayInterval: const Duration(seconds: 4),
      onPageChanged: (index) {
        setState(() {
          _currentBannerIndex = index;
        });
      },
    );
  }

  Widget _buildTrainingSummaryCard(AppStateService appState) {
    final scores = List<TrainingScore>.from(appState.myTrainingScores)
      ..sort((a, b) => b.periodId.compareTo(a.periodId));
    final score = scores.isNotEmpty ? scores.first : null;
    final total = score?.totalScore ?? 0;
    final rankLabel = _rankFromTrainingScore(total);
    final rankColor = _rankColor(total);
    final periodName = score?.period?.name ?? 'Kỳ hiện tại';
    final classRankRaw = appState.currentUser?['class_rank']?.toString() ??
      appState.currentUser?['classRank']?.toString();
    final joinedActivities = appState.events.where((event) {
      final status = appState.getEventRegistrationStatus(event.id)?.toLowerCase();
      return status == 'registered' ||
          status == 'attended' ||
          status == 'checked_in';
    }).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Rèn luyện ${periodName.replaceAll('Năm học', '').trim()}',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: rankColor.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  rankLabel,
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: rankColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1E3A8A), width: 2.6),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$total',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                      Text(
                        'điểm',
                        style: GoogleFonts.manrope(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTrainingInfoRow('Xếp loại', rankLabel),
                    const SizedBox(height: 3),
                    if (classRankRaw != null && classRankRaw.isNotEmpty)
                      _buildTrainingInfoRow('Vị trí lớp', classRankRaw)
                    else
                      FutureBuilder<String>(
                        future: score != null
                            ? _computeClassRank(appState, score.periodId)
                            : Future.value('--'),
                        builder: (context, snap) {
                          final v = (snap.data ?? '--');
                          return _buildTrainingInfoRow('Vị trí lớp', v);
                        },
                      ),
                    const SizedBox(height: 3),
                    _buildTrainingInfoRow('Hoạt động tham gia', '$joinedActivities'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrainingScoreMyScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFDBDFEA)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                foregroundColor: const Color(0xFF1E3A8A),
                padding: const EdgeInsets.symmetric(vertical: 8),
                textStyle: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              child: const Text('Chi tiết bảng điểm'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingInfoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            '$label:',
            style: GoogleFonts.manrope(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  double _upcomingCardHeight(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final extraHeight = ((textScale - 1.0).clamp(0.0, 0.8)) * 36;
    final cardWidth = _upcomingCardWidth(context);
    final imageHeight = cardWidth * 9.0 / 16.0;

    const horizontalPadding = 10.0;
    final titleMaxWidth = (cardWidth - horizontalPadding * 2).clamp(0.0, cardWidth);

    final titleStyle = GoogleFonts.manrope(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      height: 1.25,
    );
    final dateStyle = GoogleFonts.manrope(
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );
    final buttonStyle = GoogleFonts.manrope(
      fontSize: 12,
      fontWeight: FontWeight.w700,
    );

    final titleTp = TextPainter(
      text: TextSpan(text: 'W', style: titleStyle),
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: titleMaxWidth);

    final dateTp = TextPainter(
      text: TextSpan(text: '13/05/2026, 03:00 - 05:00', style: dateStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: titleMaxWidth);

    final buttonTp = TextPainter(
      text: TextSpan(text: 'Tham gia ngay', style: buttonStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: titleMaxWidth);

    const dateVerticalPadding = 8.0 + 8.0;
    const titleBottomGap = 6.0;
    const buttonVerticalInternal = 6.0 * 2;
    const buttonBottomPadding = 8.0;

    const minButtonHeight = 36.0;
    final buttonEffectiveHeight =
      (buttonTp.height + buttonVerticalInternal).clamp(minButtonHeight, double.infinity);

    final nonImageHeight =
      dateVerticalPadding + dateTp.height + titleTp.height + titleBottomGap + buttonEffectiveHeight + buttonBottomPadding;

    const safetyBuffer = 28.0;

    return imageHeight + nonImageHeight + extraHeight + safetyBuffer;
  }

  double _upcomingCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final preferred = (screenWidth - 36) / 2;
    return preferred.clamp(196.0, 230.0);
  }

  Widget _buildUpcomingEventCard(Event event, AppStateService appState) {
    final cardWidth = _upcomingCardWidth(context);
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OfficerEventDetailScreen(event: event),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE6E8F0)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  Positioned.fill(child: _buildEventCover(event.imageUrl)),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '+5 Điểm RL',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0B3A8A),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.dateTimeString,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Tham gia ngay'),
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

  String _rankFromTrainingScore(int score) {
    if (score >= 90) return 'Xuất sắc';
    if (score >= 80) return 'Giỏi';
    if (score >= 65) return 'Khá';
    if (score >= 50) return 'Trung bình';
    return 'Cần cải thiện';
  }

  Color _rankColor(int score) {
    if (score >= 90) return const Color(0xFF10B981);
    if (score >= 80) return const Color(0xFF22C55E);
    if (score >= 65) return const Color(0xFF3B82F6);
    if (score >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Widget _buildEventCover(String? imageUrl) {
    final fallback = Container(
      height: 180,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF17A2B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.event, size: 64, color: Colors.white.withOpacity(0.5)),
      ),
    );

    final resolved = ApiService.resolveMediaUrl(imageUrl);
    if (resolved == null || resolved.isEmpty) {
      return fallback;
    }

    final isNetwork = resolved.startsWith('http');
    if (isNetwork) {
      return Image.network(
        resolved,
        width: double.infinity,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    return Image.asset(
      resolved,
      width: double.infinity,
      height: 180,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  Widget _buildOfficerNewsSection() {
    return Consumer<AppStateService>(
      builder: (context, appState, _) {
        final news = appState.news
            .where((item) => item.status == 'published')
            .toList();
        news.sort(compareNewsItems);
        final visibleNews = news.take(6).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (appState.isLoadingNews)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (visibleNews.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'Chưa có tin tức',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              _buildNewsPreviewSection(visibleNews),
          ],
        );
      },
    );
  }

  Widget _buildCompactNewsTile(NewsItem news) {
    final resolved = ApiService.resolveMediaUrl(news.image) ?? news.image;
    final isNetwork = resolved.startsWith('http');
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NewsDetailScreen(news: news)),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE6E8F0)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 64,
                height: 54,
                child: isNetwork
                    ? Image.network(
                        resolved,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFE5E7EB),
                          child: const Icon(Icons.image_outlined, color: Color(0xFF9CA3AF)),
                        ),
                      )
                    : Image.asset(
                        resolved,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFE5E7EB),
                          child: const Icon(Icons.image_outlined, color: Color(0xFF9CA3AF)),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 12, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          news.date,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsPreviewSection(List<NewsItem> newsTop) {
    if (newsTop.isEmpty) {
      return const SizedBox.shrink();
    }

    final featured = newsTop.firstWhere(
      (item) => item.pinned,
      orElse: () => newsTop.first,
    );
    final otherItems = newsTop.where((item) => item.id != featured.id).take(3).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFeaturedNewsCard(featured),
        if (otherItems.isNotEmpty) ...[
          const SizedBox(height: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: otherItems
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildCompactNewsTile(item),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildFeaturedNewsCard(NewsItem news) {
    final resolved = ApiService.resolveMediaUrl(news.image) ?? news.image;
    final isNetwork = resolved.startsWith('http');
    final isAnnouncement = news.category == 'announcement';
    final tagColor = isAnnouncement ? const Color(0xFFF97316) : const Color(0xFF2563EB);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NewsDetailScreen(news: news)),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0x1F0F172A),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              isNetwork
                  ? Image.network(
                      resolved,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF143A6F),
                      ),
                    )
                  : Image.asset(
                      resolved,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF143A6F),
                      ),
                    ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x7A071224),
                      Color(0xF21B3A78),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isAnnouncement ? 'Thông báo' : 'Tin nổi bật',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: tagColor,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                bottom: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF43F5E),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'NỔI BẬT',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        news.title,
                        maxLines: 2,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        news.publishedAtString,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeSectionTitle(
    String title, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1E3A8A),
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E3A8A),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHomeEmpty(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E8F0)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.manrope(
          fontSize: 13,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF0EA5A4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bảng điều hành cán bộ',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tổng quan quản trị chi đoàn, đoàn viên và hoạt động.',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(Icons.shield_outlined, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Theo dõi nhanh các chỉ số quan trọng và báo cáo tổng hợp',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _currentTab = 3;
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: const Text(
                      'Xem báo cáo',
                      style: TextStyle(fontWeight: FontWeight.w700),
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

  Widget _buildHeaderChip(IconData icon, String title, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
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

  // ================= BOTTOM NAV =================
  BottomNavigationBar _buildBottomNav(AppStateService appState) {
    final upcomingEvents = appState.events.where((e) => e.isActive).length;
    final pendingMembers = appState.members
        .where((m) => m.status.toLowerCase() == 'pending')
        .length;
    final unreadNotifications = appState.unreadNotificationCount;

    return BottomNavigationBar(
      currentIndex: _currentTab,
      onTap: _onNavTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      items: [
        BottomNavigationBarItem(
          icon: _navIcon(Icons.home, badgeCount: 0),
          label: 'Trang chủ',
        ),
        BottomNavigationBarItem(
          icon: _navIcon(Icons.event, badgeCount: upcomingEvents),
          label: 'Hoạt động',
        ),
        BottomNavigationBarItem(
          icon: _navIcon(Icons.people, badgeCount: pendingMembers),
          label: 'Đoàn viên',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Thống kê',
        ),
        BottomNavigationBarItem(
          icon: _navIcon(Icons.person, badgeCount: unreadNotifications),
          label: 'Cá nhân',
        ),
      ],
    );
  }

  Widget _navIcon(IconData icon, {int badgeCount = 0}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (badgeCount > 0)
          Positioned(
            right: -8,
            top: -6,
            child: _buildNotifyBadge(badgeCount),
          ),
      ],
    );
  }

  // ================= PROFILE TAB =================
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1E3A8A), width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const CircleAvatar(
              backgroundImage: AssetImage('assets/images/logo.jpg'),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Cán bộ Đoàn',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Liên chi đoàn CNTT',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          _buildProfileCard(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Đăng xuất'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            offset: Offset(0, 3),
            color: Colors.black12,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildProfileItem(
            Icons.person,
            'Thông tin cá nhân',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccountProfileScreen(),
                ),
              );
            },
          ),
          const Divider(height: 20),
          _buildProfileItem(
            Icons.workspace_premium_outlined,
            'Điểm rèn luyện',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TrainingScoreMyScreen(),
                ),
              );
            },
          ),
          const Divider(height: 20),
          _buildProfileItem(
            Icons.lock_outline,
            'Đổi mật khẩu',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccountChangePasswordScreen(),
                ),
              );
            },
          ),
          const Divider(height: 20),
          _buildProfileItem(
            Icons.history,
            'Lịch sử hoạt động',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EventHistoryScreen(),
                ),
              );
            },
          ),
          const Divider(height: 20),
          _buildProfileItem(Icons.event, 'Quản lý hoạt động'),
          const Divider(height: 20),
          _buildProfileItem(Icons.notifications, 'Cài đặt thông báo'),
          const Divider(height: 20),
          _buildProfileItem(Icons.help_outline, 'Trợ giúp & hỗ trợ'),
        ],
      ),
    );
  }

  Widget _buildProfileItem(
    IconData icon,
    String title, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF1E3A8A), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ================= PLACEHOLDER TABS =================
  Widget _buildMembersTab() {
    return Consumer<AppStateService>(
      builder: (context, appState, _) {
        final members = appState.members;
        final filtered = _filterMembers(members);
        final counts = _countMemberStatus(members);
        final classOptions = _getMemberClasses(members);
        final grouped = _groupMembersByClass(filtered);

        return RefreshIndicator(
          onRefresh: appState.refreshMembers,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quản lý Đoàn viên',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 16),
                _buildClassSummary(members.length, classOptions.length),
                const SizedBox(height: 16),
                TextField(
                  controller: _memberSearchController,
                  onChanged: (value) {
                    setState(() {
                      _memberSearchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên, email, SĐT...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _memberSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _memberSearchController.clear();
                              setState(() {
                                _memberSearchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildMemberStat('Tổng số', counts['total']!, Colors.blue),
                    const SizedBox(width: 12),
                    _buildMemberStat(
                        'Hoạt động', counts['active']!, Colors.green),
                    const SizedBox(width: 12),
                    _buildMemberStat(
                        'Chờ duyệt', counts['pending']!, Colors.orange),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildMemberStat(
                        'Tạm dừng', counts['inactive']!, Colors.red),
                    const SizedBox(width: 12),
                    _buildMemberStat('Cựu ĐV', counts['alumni']!, Colors.grey),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.school,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _memberClassFilter,
                            items: [
                              const DropdownMenuItem(
                                value: 'all',
                                child: Text('Tất cả lớp/chi đoàn'),
                              ),
                              ...classOptions.map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _memberClassFilter = value);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                          'Tất cả', _memberStatusFilter == 'Tất cả'),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                          'Hoạt động', _memberStatusFilter == 'active'),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                          'Chờ duyệt', _memberStatusFilter == 'pending'),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                          'Tạm dừng', _memberStatusFilter == 'inactive'),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                          'Cựu ĐV', _memberStatusFilter == 'alumni'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (appState.isLoadingMembers)
                  const Center(child: CircularProgressIndicator())
                else if (filtered.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.group_off,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'Không có đoàn viên phù hợp',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: _memberClassFilter != 'all'
                        ? [
                            _buildClassSection(
                              _memberClassFilter,
                              grouped[_memberClassFilter] ?? [],
                            ),
                          ]
                        : grouped.entries
                            .map(
                              (entry) => _buildClassSection(
                                entry.key,
                                entry.value,
                              ),
                            )
                            .toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsTab() {
    return Consumer<AppStateService>(
      builder: (context, appState, _) {
        final now = DateTime.now();
        final upcoming =
            appState.events.where((e) => e.dateTime.isAfter(now)).length;
        final completed =
            appState.events.where((e) => e.dateTime.isBefore(now)).length;
        final members = appState.members.length;
        final officers = appState.officers.length;
        final newsCount = appState.news.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Báo cáo & Thống kê',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStat('Hoạt động', appState.events.length.toString(),
                      Icons.event),
                  const SizedBox(width: 12),
                  _buildStat('Sắp tới', upcoming.toString(), Icons.schedule),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStat('Đã tổ chức', completed.toString(),
                      Icons.event_available),
                  const SizedBox(width: 12),
                  _buildStat('Tin tức', newsCount.toString(), Icons.newspaper),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStat('Đoàn viên', members.toString(), Icons.people),
                  const SizedBox(width: 12),
                  _buildStat('Cán bộ', officers.toString(), Icons.badge),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 8,
                      offset: Offset(0, 3),
                      color: Colors.black12,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ghi chú nhanh',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dữ liệu thống kê được tổng hợp từ các hoạt động, đoàn viên và tin tức hiện có.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= MENU + STATS =================
  Widget _buildMenuSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMenuSection(
          'Danh mục chung',
          [
            _MenuItemData(
              icon: Icons.school,
              label: 'Khóa',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OfficerKhoaScreen(),
                ),
              ),
            ),
            _MenuItemData(
              icon: Icons.groups,
              label: 'Chi đoàn',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OfficerChiDoanScreen(
                    readOnly: true,
                    title: 'Chi đoàn',
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMenuSection(
          'Quản lý tổ chức',
          [
            _MenuItemData(
              icon: Icons.account_tree,
              label: 'Quản lý chi đoàn',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OfficerChiDoanScreen(),
                ),
              ),
            ),
            _MenuItemData(
              icon: Icons.groups,
              label: 'Quản lý đoàn viên theo lớp',
              onTap: () {
                setState(() {
                  _memberClassFilter = 'all';
                  _currentTab = 2;
                });
              },
            ),
            _MenuItemData(
              icon: Icons.people,
              label: 'Quản lý đoàn viên',
              onTap: () {
                setState(() {
                  _currentTab = 2;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMenuSection(
          'Quản lý người dùng',
          [
            _MenuItemData(
              icon: Icons.manage_accounts,
              label: 'Quản lý tất cả tài khoản người dùng',
              onTap: () => _showComingSoon('Quản lý tài khoản'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMenuSection(
          'Quản lý hoạt động',
          [
            _MenuItemData(
              icon: Icons.app_registration,
              label: 'Đăng ký đoàn viên tham gia sự kiện',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OfficerEventRegistrationScreen(),
                ),
              ),
            ),
            _MenuItemData(
              icon: Icons.event,
              label: 'Danh sách hoạt động',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EventManagementScreen(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuSection(String title, List<_MenuItemData> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            offset: Offset(0, 3),
            color: Colors.black12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < items.length; i++) ...[
            _buildMenuRow(items[i]),
            if (i != items.length - 1)
              const Divider(height: 18, color: AppColors.borderColor),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuRow(_MenuItemData item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, size: 18, color: const Color(0xFF1E3A8A)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label đang phát triển')),
    );
  }

  Widget _buildQuickStats() {
    return Consumer<AppStateService>(
      builder: (context, appState, _) {
        return Row(
          children: [
            _buildStat(
                'Hoạt động', appState.events.length.toString(), Icons.event),
            const SizedBox(width: 12),
            _buildStat('Thông báo', appState.unreadNotificationCount.toString(),
                Icons.notifications),
          ],
        );
      },
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              offset: Offset(0, 3),
              color: Colors.black12,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Consumer<AppStateService>(
      builder: (context, appState, _) {
        final events = List.of(appState.events)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (events.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 8,
                  offset: Offset(0, 3),
                  color: Colors.black12,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.inbox, color: Colors.grey[500]),
                const SizedBox(width: 12),
                Text('Chưa có hoạt động gần đây',
                    style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }

        final tiles = <Widget>[];
        for (final event in events.take(3)) {
          tiles.add(_buildActivityCard(event));
        }

        return Column(
          children: [
            for (int i = 0; i < tiles.length; i++) ...[
              tiles[i],
              if (i != tiles.length - 1) const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }

  String _formatRelativeTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }

  String _formatUnitName(String? unitName) {
    if (unitName == null || unitName.isEmpty) {
      return 'Chưa phân công';
    }
    return unitName.trim();
  }

  Widget _buildActivityCard(Event event) {
    void openDetail() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OfficerEventDetailScreen(event: event),
        ),
      );
    }

    final description = event.description.trim().isNotEmpty
        ? event.description.trim()
        : event.location.trim().isNotEmpty
            ? event.location.trim()
            : 'Xem chi tiết hoạt động';

    return GestureDetector(
      onTap: openDetail,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              blurRadius: 12,
              offset: Offset(0, 6),
              color: Colors.black12,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  GestureDetector(
                    onTap: openDetail,
                    child: _buildActivityImage(event.imageUrl),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${event.dateTime.day}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E3A8A),
                              height: 1,
                            ),
                          ),
                          Text(
                            'Th${event.dateTime.month}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: event.isFull ? const Color(0xFF16A34A) : const Color(0xFF22C55E),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        event.isFull ? 'ĐÃ ĐẦY' : 'CÒN CHỖ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Text(
                          '${event.dateTime.hour.toString().padLeft(2, '0')}:${event.dateTime.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.location_on, size: 16, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.people, size: 16, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Text(
                          event.isRequired ? 'Bắt buộc' : 'Tự nguyện',
                          style: TextStyle(
                            fontSize: 13,
                            color: event.isRequired ? Colors.red : Colors.blueGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityImage(String? imageUrl) {
    final fallback = Container(
      height: 190,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1B9AAA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.event,
          size: 66,
          color: Colors.white.withOpacity(0.45),
        ),
      ),
    );

    final resolved = ApiService.resolveMediaUrl(imageUrl);
    if (resolved == null || resolved.isEmpty) {
      return fallback;
    }

    final image = resolved.startsWith('http')
        ? Image.network(
            resolved,
            height: 190,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback,
          )
        : Image.asset(
            resolved,
            height: 190,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback,
          );

    return image;
  }

  // ================= MEMBER HELPER WIDGETS =================
  Map<String, int> _countMemberStatus(List<UserItem> members) {
    int countBy(String status) =>
        members.where((m) => m.status == status).length;
    return {
      'total': members.length,
      'active': countBy('active'),
      'pending': countBy('pending'),
      'inactive': countBy('inactive'),
      'alumni': countBy('alumni'),
    };
  }

  List<UserItem> _filterMembers(List<UserItem> members) {
    return members.where((member) {
      final query = _memberSearchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          member.fullName.toLowerCase().contains(query) ||
          member.email.toLowerCase().contains(query) ||
          member.phone.contains(query) ||
          (member.unitName ?? '').toLowerCase().contains(query) ||
          member.id.toString().contains(query);
      final matchesStatus = _memberStatusFilter == 'Tất cả' ||
          member.status == _memberStatusFilter;
      final matchesClass = _memberClassFilter == 'all' ||
          (member.unitName ?? 'Chưa phân công') == _memberClassFilter;
      return matchesSearch && matchesStatus && matchesClass;
    }).toList();
  }

  List<String> _getMemberClasses(List<UserItem> members) {
    final classes = members
        .map((member) => (member.unitName ?? 'Chưa phân công').trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    classes.sort();
    return classes;
  }

  Widget _buildMemberStat(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    String statusValue;
    switch (label) {
      case 'Hoạt động':
        statusValue = 'active';
        break;
      case 'Chờ duyệt':
        statusValue = 'pending';
        break;
      case 'Tạm dừng':
        statusValue = 'inactive';
        break;
      case 'Cựu ĐV':
        statusValue = 'alumni';
        break;
      default:
        statusValue = 'Tất cả';
        break;
    }

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        setState(() {
          _memberStatusFilter = statusValue;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF1E3A8A).withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF1E3A8A) : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
    );
  }

  Widget _buildClassSummary(int totalMembers, int classCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF0EA5A4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quản lý theo lớp',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$classCount lớp, $totalMembers đoàn viên',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.groups, color: Colors.white),
        ],
      ),
    );
  }

  Map<String, List<UserItem>> _groupMembersByClass(List<UserItem> members) {
    final grouped = <String, List<UserItem>>{};
    for (final member in members) {
      final className = (member.unitName ?? 'Chưa phân công').trim();
      grouped.putIfAbsent(
          className.isEmpty ? 'Chưa phân công' : className, () => []);
      grouped[className.isEmpty ? 'Chưa phân công' : className]!.add(member);
    }
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  Widget _buildClassSection(String className, List<UserItem> members) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ExpansionTile(
          initiallyExpanded:
              _memberClassFilter != 'all' && _memberClassFilter == className,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            _formatUnitName(className),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text('${members.length} đoàn viên'),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildClassStat(
                      'Hoạt động',
                      members.where((m) => m.status == 'active').length,
                      Colors.green),
                  _buildClassStat(
                      'Chờ duyệt',
                      members.where((m) => m.status == 'pending').length,
                      Colors.orange),
                  _buildClassStat(
                      'Tạm dừng',
                      members.where((m) => m.status == 'inactive').length,
                      Colors.red),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...members.map(
              (member) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildMemberCard(member),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassStat(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMemberCard(UserItem member) {
    final statusColor = _getMemberStatusColor(member.status);
    final unitName = member.unitName ?? 'Chưa phân công';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
          child: Text(
            member.fullName.isNotEmpty ? member.fullName.substring(0, 1) : '?',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
        ),
        title: Text(
          member.fullName,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Lớp/chi đoàn: $unitName',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Email: ${member.email.isEmpty ? '-' : member.email}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            member.displayStatus,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ),
        onTap: () => _showMemberDetail(member),
      ),
    );
  }

  Color _getMemberStatusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFF16A34A);
      case 'pending':
        return const Color(0xFFEA580C);
      case 'inactive':
        return const Color(0xFFDC2626);
      case 'alumni':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _showMemberDetail(UserItem member) {
    final statusColor = _getMemberStatusColor(member.status);
    final unitName = member.unitName ?? 'Chưa phân công';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
              child: Text(
                member.fullName.isNotEmpty
                    ? member.fullName.substring(0, 1)
                    : '?',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              member.fullName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                member.displayStatus,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoRow(Icons.school, 'Đơn vị', unitName),
            _buildInfoRow(Icons.badge, 'ID', member.id.toString()),
            _buildInfoRow(Icons.email, 'Email',
                member.email.isEmpty ? '-' : member.email),
            _buildInfoRow(
                Icons.phone, 'SĐT', member.phone.isEmpty ? '-' : member.phone),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF1E3A8A)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
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

class _MenuItemData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItemData({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
