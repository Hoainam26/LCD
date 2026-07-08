import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../services/app_state_service.dart';
import '../services/api_service.dart';
import '../models/event_model.dart';
import '../models/news_item.dart';
import '../models/notification_model.dart';
import '../models/training_score.dart';
import '../models/user_item.dart';
import '../widgets/carousel.dart';
import 'contact_screen.dart';
import 'news_detail_screen.dart';
import 'news_list_screen.dart';
import 'union_officers_screen.dart';
import 'training_score_my_screen.dart';
import 'login_screen.dart';
import 'event_detail_member_screen.dart';
import 'event_history_screen.dart';
import 'account_profile_screen.dart';
import 'account_change_password_screen.dart';

class MemberHomeScreen extends StatefulWidget {
  const MemberHomeScreen({super.key});

  @override
  State<MemberHomeScreen> createState() => _MemberHomeScreenState();
}

class _MemberHomeScreenState extends State<MemberHomeScreen> {
  final List<String> _logos = [
    'assets/images/logo12.png',
    'assets/images/fitdnu_logo.png',
  ];

  // Banner carousel images - users can easily add more images to assets/images/
  final List<String> _bannerImages = [
    'assets/images/banner1.jpg',
    'assets/images/banner2.jpg',
    'assets/images/banner3.jpg',
    'assets/images/banner4.jpg',
  ];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  int? _selectedPeriodId;
  int? _selectedCriterionId;
  String _eventFilter = 'current';
  String _newsFilter = 'all';
  String _bchUnitFilter = 'all';
  String _bchRoleFilter = 'all';
  String _bchFacultyFilter = 'all';

  int _currentTab = 0;
  bool _homeAnimated = false;
  int _currentBannerIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppStateService>(context, listen: false);
      appState.refreshEvents();
      appState.refreshNews();
    appState.refreshCurrentUser();
    // Ensure we load the member's latest training scores when opening home
    appState.refreshMyTrainingScores();
      appState.refreshOfficers();
      appState.refreshMyEventRegistrations();
      if (mounted) {
        setState(() {
          _homeAnimated = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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
    // With 5 tabs: 0=Home,1=Events,2=BCH,3=Search,4=Profile
    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AccountProfileScreen()),
      );
      return;
    }

    setState(() {
      _currentTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final textTheme = GoogleFonts.manropeTextTheme(baseTheme.textTheme);
    final appState = Provider.of<AppStateService>(context);

    return Theme(
      data: baseTheme.copyWith(textTheme: textTheme),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
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
              builder: (context, appState, child) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined,
                          color: AppColors.textPrimary, size: 24),
                      onPressed: () => _showNotifications(context, appState),
                    ),
                    if (appState.unreadNotificationCount > 0)
                      Positioned(
                        right: 6,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              appState.unreadNotificationCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        body: Consumer<AppStateService>(
          builder: (context, appState, _) => _buildTabBody(appState),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: _onNavTap,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_outlined),
              label: 'Hoạt động',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined),
              label: 'BCH',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'tra cứu',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBody(AppStateService appState) {
    switch (_currentTab) {
      case 0:
        return _buildHomeTab(appState);
      case 1:
        return _buildEventsTab();
      case 2:
        return UnionOfficersScreen();
      case 3:
        return _buildSearchTab();
      case 4:
        return _buildProfileTab();
      default:
        return _buildHomeTab(appState);
    }
  }

  Widget _buildHomeTab(AppStateService appState) {
    final upcomingEvents = appState.events
        .where((event) => event.isUpcoming)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final upcomingTop = upcomingEvents.take(6).toList();
    final newsTop = appState.news
        .where((item) => item.status == 'published')
        .toList()
      ..sort(compareNewsItems);

    return RefreshIndicator(
      onRefresh: () async {
        await appState.refreshEvents();
        await appState.refreshNews();
        await appState.refreshCurrentUser();
        await appState.refreshMyTrainingScores();
        await appState.refreshTrainingPeriods();
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
              color: const Color(0xFFF5F6FA),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                    child: SimpleCarousel(
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
                    ),
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
                    child: _buildTrainingSummaryCard(appState),
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
                  if (upcomingTop.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _buildHomeEmpty('Chưa có hoạt động sắp tới'),
                    )
                  else
                    SizedBox(
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
                    ),

                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHomeSectionTitle(
                          'Tin tức & Thông báo',
                        ),
                        const SizedBox(height: 10),
                        if (appState.isLoadingNews)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (appState.news.isEmpty)
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
                          _buildNewsPreviewSection(newsTop),
                      ],
                    ),
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Rèn luyện ${periodName.replaceAll('Năm học', '').trim()}',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: rankColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1E3A8A), width: 3),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$total',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                      Text(
                        'điểm',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTrainingInfoRow('Xếp loại', rankLabel),
                    const SizedBox(height: 4),
                    // Show server-provided class rank if available, otherwise compute it
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
                    const SizedBox(height: 4),
                    _buildTrainingInfoRow('Hoạt động tham gia', '$joinedActivities'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
                  borderRadius: BorderRadius.circular(10),
                ),
                foregroundColor: const Color(0xFF1E3A8A),
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700),
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
              fontSize: 11,
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
              fontSize: 12,
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

    // Dynamically measure the non-image content (date row, title, button)
    const horizontalPadding = 10.0; // padding used around title/button
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
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );

    // Approximate heights using TextPainter for accurate layout accounting
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

    // paddings: date row has vertical padding 8(top)+8(bottom) inside its Padding
    const dateVerticalPadding = 8.0 + 8.0; // from Padding(... fromLTRB(10,8,10,8))
    // title has no vertical padding but we leave a small gap above (none) and below 6px SizedBox
    const titleBottomGap = 6.0;
    // button has bottom padding 8 from its Padding(... fromLTRB(10,0,10,8)) and internal vertical padding 6
    const buttonVerticalInternal = 6.0 * 2; // top+bottom padding inside button style
    const buttonBottomPadding = 8.0;

    // Some platforms enforce a minimum interactive button height; ensure we account for that
    const minButtonHeight = 36.0;
    final buttonEffectiveHeight =
      (buttonTp.height + buttonVerticalInternal).clamp(minButtonHeight, double.infinity);

    final nonImageHeight =
      dateVerticalPadding + dateTp.height + titleTp.height + titleBottomGap + buttonEffectiveHeight + buttonBottomPadding;

    // Safety buffer increased to handle rounding and platform-specific minimums
    const safetyBuffer = 28.0;

    return imageHeight + nonImageHeight + extraHeight + safetyBuffer;
  }

  double _upcomingCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final preferred = (screenWidth - 36) / 2;
    return preferred.clamp(196.0, 230.0);
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
        if (actionLabel != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  Text(
                    actionLabel,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4B67B2),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right, size: 18, color: Color(0xFF4B67B2)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUpcomingEventCard(Event event, AppStateService appState) {
    final memberId = appState.currentUser?['id']?.toString() ?? '';
    final cardWidth = _upcomingCardWidth(context);
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailMemberScreen(event: event, memberId: memberId),
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
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF6B7280)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.dateTimeString,
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SizedBox(
                height: 35,
                child: Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.25,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailMemberScreen(event: event, memberId: memberId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF173B90),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Tham gia ngay'),
                ),
              ),
            ),
          ],
        ),
      ),
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
                    color: Colors.white.withOpacity(0.98),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    isAnnouncement ? 'Thông báo' : 'Tin tức',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: tagColor,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE11D48),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x66E11D48),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        'NỔI BẬT',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            news.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time, size: 12, color: Colors.white.withOpacity(0.9)),
                              const SizedBox(width: 4),
                              Text(
                                news.date,
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.95),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeEmpty(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E8F0)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.manrope(
          fontSize: 13,
          color: AppColors.textSecondary,
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

  Widget _buildTrainingTab(AppStateService appState) {
    final scores = appState.myTrainingScores.where((score) {
      if (_selectedPeriodId != null && score.periodId != _selectedPeriodId) {
        return false;
      }
      if (_selectedCriterionId != null) {
        final match =
            score.items.any((item) => item.criterionId == _selectedCriterionId);
        if (!match) return false;
      }
      return true;
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        await appState.refreshMyTrainingScores(periodId: _selectedPeriodId);
        await appState.refreshTrainingPeriods();
        await appState.refreshTrainingCriteria();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTrainingFilterCard(
                appState,
                _selectedPeriodId,
                _selectedCriterionId,
              ),
              const SizedBox(height: 16),
              if (appState.isLoadingTraining)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (scores.isEmpty)
                Text(
                  'Chưa có điểm rèn luyện phù hợp',
                  style: TextStyle(color: Colors.grey[600]),
                )
              else
                Column(
                  children: scores
                      .map((score) => _buildTrainingScoreTile(score))
                      .toList(),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsTab() {
    return Consumer<AppStateService>(
      builder: (context, appState, child) {
        final filteredEvents = _filteredMemberEvents(appState);

        return RefreshIndicator(
          onRefresh: () async {
            await appState.refreshEvents();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            children: [
              Text(
                'Hoạt động Đoàn',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _buildEventFilterChips(),
              const SizedBox(height: 12),
              if (filteredEvents.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 70),
                  child: _buildHomeEmpty(_eventEmptyMessage()),
                )
              else
                ...filteredEvents.map((event) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildMemberEventCard(event, appState),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  List<Event> _filteredMemberEvents(AppStateService appState) {
    final events = List<Event>.from(appState.events);

    bool isWithinNextTwoDays(Event event) {
      final now = DateTime.now();
      if (!event.dateTime.isAfter(now)) return false;
      final diff = event.dateTime.difference(now);
      return diff <= const Duration(days: 2);
    }

    switch (_eventFilter) {
      case 'current':
        return events
            .where((event) => !event.isClosed)
            .where((event) => event.isOngoing || isWithinNextTwoDays(event))
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      case 'upcoming':
        return events
            .where((event) => event.isUpcoming)
            .where((event) => !isWithinNextTwoDays(event))
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      case 'history':
        return events.where((event) => event.hasEnded || event.isClosed).toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
      case 'registered':
        return events.where((event) => appState.isEventRegistered(event.id)).toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
      case 'all':
      default:
        return events
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    }
  }

  String _eventEmptyMessage() {
    switch (_eventFilter) {
      case 'current':
        return 'Hiện chưa có hoạt động đang diễn ra hoặc sắp diễn ra trong 1-2 ngày';
      case 'upcoming':
        return 'Chưa có hoạt động sắp tới';
      case 'history':
        return 'Chưa có hoạt động lịch sử';
      default:
        return 'Chưa có hoạt động phù hợp';
    }
  }

  Widget _buildMemberEventCard(Event event, AppStateService appState) {
    final hasRegistered = appState.isEventRegistered(event.id);
    final memberId = appState.currentUser?['id']?.toString() ?? '';
    final isEnded = event.hasEnded || event.isClosed;
    final canRegister = !hasRegistered &&
      !event.isRequired &&
      event.isRegistrationOpen &&
      !event.isFull &&
      !event.hasEnded;
    final badgeLabel = isEnded
        ? 'ĐÃ KẾT THÚC'
        : event.isFull
            ? 'ĐÃ ĐẦY'
            : canRegister
                ? 'CÒN CHỖ'
                : 'ĐANG DIỄN RA';
    final badgeColor = isEnded
        ? const Color(0xFF94A3B8)
        : event.isFull
            ? const Color(0xFFEF4444)
            : canRegister
                ? const Color(0xFF16A34A)
                : const Color(0xFF2563EB);
    final buttonLabel = event.isRequired
      ? 'Bắt buộc tham gia'
      : canRegister && !isEnded
        ? 'Đăng ký ngay'
        : 'Xem chi tiết';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailMemberScreen(
              event: event,
              memberId: memberId,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F0F172A),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: _buildEventCover(event.imageUrl),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badgeLabel,
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    width: 42,
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          event.dateTime.day.toString().padLeft(2, '0'),
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E3A8A),
                          ),
                        ),
                        Text(
                          'TH${event.dateTime.month}',
                          style: GoogleFonts.manrope(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Text(
                event.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E2A47),
                  height: 1.2,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                event.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  height: 1.35,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 13, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    _formatEventTime(event.dateTime),
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildEventTypeTag(event),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canRegister && !isEnded
                      ? () => _registerForEvent(event, appState)
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventDetailMemberScreen(
                                event: event,
                                memberId: memberId,
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D3D91),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(buttonLabel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatEventTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildEventTypeTag(Event event) {
    final label = event.isRequired ? 'Bắt buộc' : 'Tự nguyện';
    final color = event.isRequired ? const Color(0xFFEF4444) : const Color(0xFF2563EB);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
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
        child:
            Icon(Icons.event, size: 64, color: Colors.white.withOpacity(0.5)),
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

  Widget _buildEventThumbnail(String? imageUrl) {
    final fallback = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.image_outlined,
        color: const Color(0xFF1E3A8A).withOpacity(0.45),
        size: 28,
      ),
    );

    final resolved = ApiService.resolveMediaUrl(imageUrl);
    if (resolved == null || resolved.isEmpty) {
      return fallback;
    }

    final image = resolved.startsWith('http')
        ? Image.network(
            resolved,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback,
          )
        : Image.asset(
            resolved,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback,
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(width: 64, height: 64, child: image),
    );
  }

  void _showEventDetails(Event event, bool hasRegistered) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.event, color: Color(0xFF1E3A8A)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                event.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(Icons.description, 'Mô tả', event.description),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.access_time,
                'Thời gian',
                _formatDateTime(event.dateTime),
              ),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.location_on, 'Địa điểm', event.location),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.people,
                'Bắt buộc',
                event.isRequired ? 'Có' : 'Không',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasRegistered
                      ? Colors.green.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasRegistered ? Icons.check_circle : Icons.info_outline,
                      color: hasRegistered ? Colors.green : Colors.blue,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        hasRegistered
                            ? 'Bạn đã đăng ký tham gia hoạt động này'
                            : 'Bạn chưa đăng ký tham gia hoạt động này',
                        style: TextStyle(
                          fontSize: 13,
                          color: hasRegistered
                              ? Colors.green[700]
                              : Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1E3A8A)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _registerForEvent(Event event, AppStateService appState) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đăng ký: ${event.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hoạt động sẽ diễn ra vào ${_formatDateTime(event.dateTime)}',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                border: OutlineInputBorder(),
                hintText: 'Lý do tham gia, mong muốn...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await appState.registerForEvent(event.id);
              if (!mounted) return;

              // Refresh registration status from backend
              await appState.refreshMyEventRegistrations();
              if (!mounted) return;

              Navigator.pop(context);
              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success ? 'Đăng ký thành công' : 'Đăng ký thất bại',
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A)),
            child: const Text('Đăng ký'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkInForEvent(Event event, AppStateService appState) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient background
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Xác nhận tham gia hoạt động',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event details with icons
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.access_time,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'THỜI GIAN',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDateTime(event.dateTime),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Location
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ĐỊA ĐIỂM',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              event.location ?? 'Chưa xác định',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Confirmation message
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Bạn xác nhận đã tham gia hoạt động này?',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Buttons
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Xác nhận',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
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

    if (confirmed != true || !mounted) return;

    // Perform check-in
    final result = await ApiService.checkInMember(
      eventId: event.id,
      memberId: appState.currentUser?['id']?.toString() ?? '',
    );

    if (!mounted) return;

    // Refresh registration status
    await appState.refreshMyEventRegistrations();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['success'] == true
              ? 'Điểm danh thành công!'
              : (result['message'] ?? 'Điểm danh thất bại, vui lòng thử lại'),
        ),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildSearchTab() {
    final appState = Provider.of<AppStateService>(context);
    final query = _searchQuery.trim().toLowerCase();
    final officers = appState.officers.where(_isClassUnionOfficer).toList();
    final units = officers
        .map((item) => item.unitName?.trim() ?? '')
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => _unitSortValue(a).compareTo(_unitSortValue(b)));
    final roles = <String>{'Bí thư', 'Phó bí thư', 'Ủy viên'};
    final faculties = officers
        .map(_deriveKhoaFromOfficer)
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => _khoaSortValue(a).compareTo(_khoaSortValue(b)));

    final selectedUnit =
        units.contains(_bchUnitFilter) ? _bchUnitFilter : 'all';
    final selectedRole =
        roles.contains(_bchRoleFilter) ? _bchRoleFilter : 'all';
    final selectedFaculty =
        faculties.contains(_bchFacultyFilter) ? _bchFacultyFilter : 'all';

    final filteredOfficers = officers.where((officer) {
      if (_excludeBchName(officer.fullName)) {
        return false;
      }
      if ((officer.unitName ?? '').trim().isEmpty) {
        return false;
      }
      final resolvedRole = _resolveBchPosition(officer);
      final faculty = _deriveKhoaFromOfficer(officer);

      if (selectedFaculty != 'all' && faculty != selectedFaculty) {
        return false;
      }
      if (selectedUnit != 'all' && officer.unitName != selectedUnit) {
        return false;
      }
      if (selectedRole != 'all' && resolvedRole != selectedRole) {
        return false;
      }
      if (query.isNotEmpty) {
        final haystack =
            '${officer.fullName} ${officer.email} ${officer.phone} ${officer.studentCode ?? ''} '
            '${officer.unitName ?? ''} $resolvedRole $faculty'
                .toLowerCase();
        if (!haystack.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await appState.refreshOfficers();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBchHeaderCard(officers.length),
                const SizedBox(height: 16),
                _buildBchFilterCard(
                  faculties,
                  units,
                  selectedFaculty,
                  selectedUnit,
                  selectedRole,
                ),
                const SizedBox(height: 12),
                _buildBchSearchField(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.people,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Danh sách BCH (${filteredOfficers.length})',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (filteredOfficers.isEmpty)
                  Text(
                    'Không tìm thấy cán bộ phù hợp',
                    style: TextStyle(color: Colors.grey[600]),
                  )
                else
                  Column(
                    children: List.generate(
                      filteredOfficers.length,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildBchMemberCard(filteredOfficers[index]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrainingFilterCard(
    AppStateService appState,
    int? selectedPeriodId,
    int? selectedCriterionId,
  ) {
    final periods = appState.trainingPeriods;
    final criteria = appState.trainingCriteria;

    return _buildFilterCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune,
                    color: AppColors.secondary, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Lọc theo học kỳ và tiêu chí',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TrainingScoreMyScreen(),
                    ),
                  );
                },
                child: const Text('Chi tiết'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            value: selectedPeriodId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Học kỳ / Năm học',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Tất cả học kỳ'),
              ),
              ...periods.map(
                (period) => DropdownMenuItem<int?>(
                  value: period.id,
                  child: Text(period.name),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedPeriodId = value;
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            value: selectedCriterionId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Tiêu chí',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Tất cả tiêu chí'),
              ),
              ...criteria.map(
                (criterion) => DropdownMenuItem<int?>(
                  value: criterion.id,
                  child: Text(criterion.name),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCriterionId = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventFilterChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          label: 'Hiện tại',
          selected: _eventFilter == 'current',
          color: AppColors.primary,
          onTap: () => setState(() => _eventFilter = 'current'),
        ),
        _buildFilterChip(
          label: 'Sắp tới',
          selected: _eventFilter == 'upcoming',
          color: AppColors.primary,
          onTap: () => setState(() => _eventFilter = 'upcoming'),
        ),
        _buildFilterChip(
          label: 'Lịch sử',
          selected: _eventFilter == 'history',
          color: AppColors.primary,
          onTap: () => setState(() => _eventFilter = 'history'),
        ),
      ],
    );
  }

  Widget _buildNewsFilterChips(
      List<String> categories, String selectedCategory) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          label: 'Tất cả',
          selected: selectedCategory == 'all',
          color: AppColors.secondary,
          onTap: () => setState(() => _newsFilter = 'all'),
        ),
        ...categories.map(
          (category) => _buildFilterChip(
            label: _newsCategoryLabel(category),
            selected: selectedCategory == category,
            color: AppColors.secondary,
            onTap: () => setState(() => _newsFilter = category),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: color.withOpacity(0.15),
      backgroundColor: Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? color : AppColors.borderColor,
        ),
      ),
      labelStyle: TextStyle(
        color: selected ? color : AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildFilterCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTrainingScoreTile(TrainingScore score) {
    final periodName = score.period?.name ?? 'Học kỳ ${score.periodId}';
    final statusColor = _trainingStatusColor(score.status);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TrainingScoreMyScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.assignment_turned_in,
                color: AppColors.secondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    periodName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tổng điểm: ${score.totalScore} · ${score.displayStatus}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                score.displayStatus,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _trainingStatusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'submitted':
        return AppColors.warning;
      case 'rejected':
        return AppColors.danger;
      case 'draft':
      default:
        return AppColors.textSecondary;
    }
  }

  String _newsCategoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'news':
        return 'Tin tức';
      case 'announcement':
        return 'Thông báo';
      case 'event':
        return 'Hoạt động';
      default:
        return category;
    }
  }

  Widget _buildSearchSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSearchEventTile(Event event, AppStateService appState) {
    final memberId = appState.currentUser?['id']?.toString() ?? '';
    void openDetail() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventDetailMemberScreen(
            event: event,
            memberId: memberId,
          ),
        ),
      );
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: openDetail,
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${event.dateTime.day}/${event.dateTime.month}/${event.dateTime.year}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchNewsTile(NewsItem news) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.newspaper, color: Color(0xFF3B82F6)),
      title: Text(news.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        news.date,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NewsDetailScreen(news: news),
          ),
        );
      },
    );
  }

  Widget _buildBchHeaderCard(int totalCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFDC2626), Color(0xFF7C3AED)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Thông tin BCH Khoa CNTT',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ban Chấp hành Chi đoàn',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _buildHeaderPill('${totalCount} thành viên BCH', Icons.groups),
              _buildHeaderPill('Khoa CNTT', Icons.school),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderPill(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBchFilterCard(
    List<String> faculties,
    List<String> units,
    String selectedFaculty,
    String selectedUnit,
    String selectedRole,
  ) {
    // Filter layout: full-width Khóa, then two side-by-side Chi đoàn + Chức vụ, then search
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            children: [
              const Icon(Icons.tune, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bộ lọc & Tìm kiếm',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _bchFacultyFilter = 'all';
                    _bchUnitFilter = 'all';
                    _bchRoleFilter = 'all';
                    _searchController.clear();
                    _searchQuery = '';
                  });
                },
                child: Text(
                  'XÓA LỌC',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Full-width Khóa dropdown
          DropdownButtonFormField<String>(
            value: selectedFaculty,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Khóa',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
            ),
            items: [
              const DropdownMenuItem(value: 'all', child: Text('Tất cả các khóa')),
              ...faculties.map((faculty) => DropdownMenuItem(value: faculty, child: Text(faculty))),
            ],
            onChanged: (value) {
              setState(() {
                _bchFacultyFilter = value ?? 'all';
              });
            },
          ),
          const SizedBox(height: 12),

          // Row: Chi đoàn (lớp) | Chức vụ
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedUnit,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Chi đoàn (lớp)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                  ),
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                    ...units.map((unit) => DropdownMenuItem(value: unit, child: Text(_formatUnitName(unit)))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _bchUnitFilter = value ?? 'all';
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedRole,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Chức vụ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                    DropdownMenuItem(value: 'Bí thư', child: Text('Bí thư')),
                    DropdownMenuItem(value: 'Phó bí thư', child: Text('Phó bí thư')),
                    DropdownMenuItem(value: 'Ủy viên', child: Text('Ủy viên')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _bchRoleFilter = value ?? 'all';
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search field
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Tìm theo họ tên, lớp, MSSV, SĐT',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBchSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Tìm theo họ tên, lớp, MSSV, SĐT',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
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
      ),
    );
  }

  Widget _buildCompactDropdown({
    required String label,
    required String value,
    required List<String> items,
    required String Function(String?) display,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items
              .map((it) => DropdownMenuItem<String>(
                    value: it,
                    child: Text(
                      display(it),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
        ),
      ),
    );
  }

  Widget _buildBchMemberCard(UserItem officer) {
    final avatarUrl = officer.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final rawUnit = officer.unitName ?? '';
    final unitLabel =
        rawUnit.trim().isEmpty ? 'Chưa rõ' : _formatUnitName(rawUnit);
    final resolvedRole = _resolveBchPosition(officer);
    final studentCode = officer.studentCode ?? '';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 52,
              height: 52,
              child: hasAvatar
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildOfficerFallback(),
                    )
                  : _buildOfficerFallback(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        officer.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _buildRoleBadge(resolvedRole),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  unitLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (studentCode.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.badge,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        studentCode,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.email,
                        size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        officer.email.isNotEmpty
                            ? officer.email
                            : 'Chưa cập nhật email',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.phone,
                        size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      officer.phone.isNotEmpty
                          ? officer.phone
                          : 'Chưa cập nhật SĐT',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficerFallback() {
    return Container(
      color: const Color(0xFFEFF4FF),
      child: const Icon(Icons.person, color: AppColors.primary),
    );
  }

  String _deriveKhoaFromOfficer(UserItem officer) {
    final rawCode = (officer.studentCode ?? '').trim();
    final source = rawCode.isNotEmpty ? rawCode : officer.id.toString();
    if (source.length < 2) return '';
    final prefix = source.substring(0, 2);
    final prefixNum = int.tryParse(prefix);
    if (prefixNum == null) return '';
    if (prefixNum == 16) return 'Khóa 2024';
    if (prefixNum == 17) return 'Khóa 2025';
    return '';
  }

  int _khoaSortValue(String label) {
    final match = RegExp(r'(\d{4})').firstMatch(label);
    if (match == null) return 9999;
    return int.tryParse(match.group(1) ?? '') ?? 9999;
  }

  int _unitSortValue(String unit) {
    final match = RegExp(r'(\d{2})\D*(\d{2})').firstMatch(unit);
    if (match == null) return 9999;
    final khoa = int.tryParse(match.group(1) ?? '') ?? 99;
    final lop = int.tryParse(match.group(2) ?? '') ?? 99;
    return khoa * 100 + lop;
  }

  String _formatUnitName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;
    final match = RegExp(r'^([A-Za-z]+)\s*(\d{2})\s*[-_/\\]?\s*(\d{2})$')
        .firstMatch(trimmed);
    if (match == null) return trimmed;
    final prefix = (match.group(1) ?? '').toUpperCase();
    final year = match.group(2) ?? '';
    final group = match.group(3) ?? '';
    return '$prefix $year-$group';
  }

  String _resolveBchPosition(UserItem officer) {
    const override = {
      'Lê Văn Phong': 'Bí thư',
      'Nguyễn Thị Kim Hoa': 'Ủy viên',
      'Lê Thị Vân Anh': 'Ủy viên',
      'Nguyễn Thị Phương': 'Ủy viên',
    };
    final byName = override[officer.fullName.trim()];
    if (byName != null) return byName;
    if (officer.position != null && officer.position!.trim().isNotEmpty) {
      final raw = officer.position!.trim();
      final normalized = raw.toLowerCase();
      if (normalized.contains('bí thư') && !normalized.contains('phó')) {
        return 'Bí thư';
      }
      if (normalized.contains('phó') && normalized.contains('bí thư')) {
        return 'Phó bí thư';
      }
      if (normalized.contains('ủy viên') ||
          normalized.contains('uỷ viên') ||
          normalized.contains('can bo') ||
          normalized.contains('cán bộ')) {
        return 'Ủy viên';
      }
      return raw;
    }
    switch (officer.role) {
      case 'admin':
        return 'Bí thư';
      case 'staff':
        return 'Phó bí thư';
      case 'member':
      default:
        return 'Ủy viên';
    }
  }

  bool _isClassUnionOfficer(UserItem officer) {
    if (_excludeBchName(officer.fullName)) return false;
    final hasUnit = (officer.unitName ?? '').trim().isNotEmpty;
    if (!hasUnit) return false;

    final role = officer.role.trim().toLowerCase();
    if (role == 'admin' || role == 'staff') return true;

    final position = (officer.position ?? '').trim().toLowerCase();
    return position.contains('bí thư') ||
        position.contains('bi thu') ||
        position.contains('ủy viên') ||
        position.contains('uỷ viên') ||
        position.contains('uy vien') ||
        position.contains('cán bộ') ||
        position.contains('can bo');
  }

  Widget _buildRoleBadge(String role) {
    final isLeader = role == 'Bí thư';
    final isDeputy = role == 'Phó bí thư';
    final bg = isLeader
        ? const Color(0xFFFFE4E6)
        : isDeputy
            ? const Color(0xFFE0F2FE)
            : const Color(0xFFECFDF3);
    final fg = isLeader
        ? const Color(0xFFBE123C)
        : isDeputy
            ? const Color(0xFF0369A1)
            : const Color(0xFF047857);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }

  bool _excludeBchName(String fullName) {
    const excluded = {
      'Nguyễn Hoài Nam',
      'Nguyen Hoai Nam',
    };
    return excluded.contains(fullName.trim());
  }

  Widget _buildSearchCategory(String title, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildBCHTab() {
    return const UnionOfficersScreen();
  }

  Widget _buildProfileTab() {
    final appState = Provider.of<AppStateService>(context);
    final user = appState.currentUser;
    final loginName = user?['external_username'] ??
        user?['username'] ??
        user?['userName'] ??
        user?['email'] ??
        '';
    final displayName = loginName.isNotEmpty
        ? loginName
        : user?['full_name'] ?? user?['fullName'] ?? 'Đoàn viên';
    final email = user?['email'] ?? '';
    final rawAvatar = user?['avatar_url']?.toString() ??
        user?['avatarUrl']?.toString() ??
        user?['avatar']?.toString();
    final avatarUrl = ApiService.resolveAvatarUrl(rawAvatar);
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    return RefreshIndicator(
      onRefresh: () async {
        await appState.refreshCurrentUser();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF3B82F6),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: hasAvatar
                            ? Image.network(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Icon(Icons.person,
                                        size: 50, color: Colors.grey[400]),
                                  );
                                },
                              )
                            : Image.asset(
                                'assets/images/logo.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Icon(Icons.person,
                                        size: 50, color: Colors.grey[400]),
                                  );
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email.isNotEmpty ? email : 'Chưa cập nhật email',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Profile Menu Items
              _buildProfileMenuItem(
                Icons.person_outline,
                'Thông tin cá nhân',
                'Xem và chỉnh sửa thông tin',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AccountProfileScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildProfileMenuItem(
                Icons.lock_outline,
                'Đổi mật khẩu',
                'Cập nhật mật khẩu tài khoản',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AccountChangePasswordScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildProfileMenuItem(
                Icons.history,
                'Lịch sử hoạt động',
                'Xem các hoạt động đã tham gia',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EventHistoryScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildProfileMenuItem(
                Icons.emoji_events,
                'Thành tích',
                'Xem danh sách thành tích',
                () {},
              ),
              const SizedBox(height: 12),
              _buildProfileMenuItem(
                Icons.assignment,
                'Điểm rèn luyện',
                'Xem chi tiết điểm rèn luyện của bạn',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TrainingScoreMyScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildProfileMenuItem(
                Icons.settings_outlined,
                'Cài đặt',
                'Tùy chỉnh ứng dụng',
                () {},
              ),
              const SizedBox(height: 12),
              _buildProfileMenuItem(
                Icons.help_outline,
                'Trợ giúp',
                'Hướng dẫn sử dụng',
                () {},
              ),
              const SizedBox(height: 12),
              _buildProfileMenuItem(
                Icons.phone_outlined,
                'Liên hệ',
                'Thông tin liên hệ và hỗ trợ',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ContactScreen()),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Đăng xuất'),
                        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Đóng dialog
                              // Quay về màn hình đăng nhập và xóa toàn bộ navigation stack
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            },
                            child: const Text(
                              'Đăng xuất',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Đăng xuất',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF3B82F6),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(
    IconData icon,
    String value,
    String label,
    Color accent,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 14, color: accent),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: ' $label',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.9),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNewsCard(NewsItem news) {
    final isAnnouncement = news.category == 'announcement';
    final color =
        isAnnouncement ? const Color(0xFFEF4444) : const Color(0xFF3B82F6);
    final icon = isAnnouncement ? Icons.campaign : Icons.newspaper;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailScreen(news: news),
            ),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    style: const TextStyle(
                      fontFamily: 'Times New Roman',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    news.description,
                    style: TextStyle(
                      fontFamily: 'Times New Roman',
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        news.date,
                        style: TextStyle(
                          fontFamily: 'Times New Roman',
                          fontSize: 12,
                          color: Colors.grey[500],
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

  // Vertical news card widget for news feed
  Widget _buildNewsCardVertical(NewsItem news) {
    final resolved = ApiService.resolveMediaUrl(news.image) ?? news.image;
    final isNetwork = resolved.startsWith('http');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NewsDetailScreen(news: news),
          ),
        );
      },
      child: SizedBox(
        height: 120, // Explicit height constraint
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                // Image
                Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey[100],
                  child: isNetwork
                      ? Image.network(
                          resolved,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image,
                                size: 40,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : Image.asset(
                          resolved,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image,
                                size: 40,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title
                        Text(
                          news.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Description
                        Text(
                          news.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Date
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              news.date,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Large news card widget (image on top) for full news list
  Widget _buildNewsCardLarge(NewsItem news) {
    final resolved = ApiService.resolveMediaUrl(news.image) ?? news.image;
    final isNetwork = resolved.startsWith('http');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NewsDetailScreen(news: news),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: isNetwork
                    ? Image.network(
                        resolved,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image,
                              size: 48,
                              color: Colors.grey,
                            ),
                          );
                        },
                      )
                    : Image.asset(
                        resolved,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image,
                              size: 48,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      news.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      news.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 13,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          news.date,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
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
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Times New Roman',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: Text(
              actionLabel,
              style: const TextStyle(
                fontFamily: 'Times New Roman',
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              foregroundColor: AppColors.primary,
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActionGrid() {
    final items = [
      _buildQuickAction(
        'Hoạt động',
        Icons.event_available,
        const Color(0xFF2563EB),
        backgroundColor: const Color(0xFFDDE9FF),
        onTap: () => setState(() => _currentTab = 1),
      ),
      _buildQuickAction(
        'Tin tức',
        Icons.newspaper,
        const Color(0xFF0EA5E9),
        backgroundColor: const Color(0xFFD9F2F8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewsListScreen()),
          );
        },
      ),
      _buildQuickAction(
        'Ban Chấp Hành\nLiên Chi Đoàn',
        Icons.groups,
        const Color(0xFFF59E0B),
        backgroundColor: const Color(0xFFFDE4C1),
        onTap: () => setState(() => _currentTab = 3),
      ),
      _buildQuickAction(
        'Hỗ trợ',
        Icons.headset_mic_outlined,
        const Color(0xFFF97316),
        backgroundColor: const Color(0xFFFFE2C7),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ContactScreen()),
          );
        },
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final itemWidth = (constraints.maxWidth - spacing * 3) / 4;
        return Wrap(
          spacing: spacing,
          runSpacing: 12,
          children: items
              .map((item) => SizedBox(width: itemWidth, child: item))
              .toList(),
        );
      },
    );
  }

  Widget _buildHighlightCard(
    String title,
    String date,
    String image, {
    VoidCallback? onTap,
  }) {
    final isNetwork = image.startsWith('http');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16, top: 4, bottom: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              isNetwork
                  ? Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image,
                            size: 64,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                  : Image.asset(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image,
                            size: 64,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Times New Roman',
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 14, color: Colors.white70),
                          const SizedBox(width: 6),
                          Text(
                            date,
                            style: const TextStyle(
                              fontFamily: 'Times New Roman',
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
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

  Widget _buildQuickAction(
    String label,
    IconData icon,
    Color color, {
    Color? backgroundColor,
    VoidCallback? onTap,
  }) {
    final bgColor = backgroundColor ?? color.withOpacity(0.16);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
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
    );
  }

  Widget _buildEventCard(Event event, AppStateService appState) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventDetailMemberScreen(
                  event: event,
                  memberId: appState.currentUser?['id']?.toString() ?? '',
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${event.dateTime.day}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      Text(
                        'Th${event.dateTime.month}',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF1E3A8A).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontFamily: 'Times New Roman',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${event.dateTime.hour}:${event.dateTime.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                                fontFamily: 'Times New Roman',
                                fontSize: 13,
                                color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.location_on,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location,
                              style: TextStyle(
                                  fontFamily: 'Times New Roman',
                                  fontSize: 13,
                                  color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBCHMemberAvatar(
    String name,
    String position,
    String imagePath,
    Color borderColor,
    IconData icon,
  ) {
    return InkWell(
      onTap: () {
        _showMemberDetail(name, position, imagePath);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: borderColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.person,
                              size: 35, color: Colors.grey[400]),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: borderColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(icon, size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              position,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showMemberDetail(String name, String position, String imagePath) {
    showModalBottomSheet(
      context: context,
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
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1E3A8A), width: 3),
              ),
              child: ClipOval(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child:
                          Icon(Icons.person, size: 50, color: Colors.grey[400]),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              position,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.phone),
                    label: const Text('Gọi điện'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.message),
                    label: const Text('Nhắn tin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFullBCH(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'BAN CHẤP HÀNH LIÊN CHI ĐOÀN\nKHOA CÔNG NGHỆ THÔNG TIN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        'Bí thư',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFullBCHCard(
                          'Lê Văn Phong',
                          'Bí thư',
                          'assets/images/secretary.jpg',
                          const Color(0xFFD4AF37)),
                      const SizedBox(height: 24),
                      const Text(
                        'Phó Bí thư',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFullBCHCard('Lê Tuấn Anh', 'Phó Bí thư',
                          'assets/images/vice1.jpg', const Color(0xFFC0C0C0)),
                      const SizedBox(height: 12),
                      _buildFullBCHCard('Nguyễn Thái Khánh', 'Phó Bí thư',
                          'assets/images/vice2.jpg', const Color(0xFFC0C0C0)),
                      const SizedBox(height: 12),
                      _buildFullBCHCard('Trần Thị Thanh Nhàn', 'Phó Bí thư',
                          'assets/images/vice3.jpg', const Color(0xFFC0C0C0)),
                      const SizedBox(height: 24),
                      const Text(
                        'Ủy viên',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFullBCHCard('Nguyễn Thị Phương', 'Ủy viên',
                          'assets/images/member1.jpg', const Color(0xFFCD7F32)),
                      const SizedBox(height: 12),
                      _buildFullBCHCard('Lê Thị Vân Anh', 'Ủy viên',
                          'assets/images/member2.jpg', const Color(0xFFCD7F32)),
                      const SizedBox(height: 12),
                      _buildFullBCHCard('Nguyễn Thị Kim Hoa', 'Ủy viên',
                          'assets/images/member3.jpg', const Color(0xFFCD7F32)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFullBCHCard(
      String name, String position, String imagePath, Color accentColor) {
    return InkWell(
      onTap: () => _showMemberDetail(name, position, imagePath),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accentColor, width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child:
                          Icon(Icons.person, size: 25, color: Colors.grey[400]),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    position,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showNotifications(
    BuildContext context,
    AppStateService appState,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final notifications = appState.notifications;
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Thông báo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await appState.markAllNotificationsAsRead();
                          if (Navigator.canPop(sheetContext)) {
                            Navigator.pop(sheetContext);
                          }
                        },
                        child: const Text('Đánh dấu đã đọc'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (notifications.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.notifications_off,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có thông báo nào',
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
                              await appState.markNotificationAsRead(item.id);
                            }
                            if (!mounted) return;
                            await _openNotificationTarget(this.context, item, appState);
                          },
                          leading: CircleAvatar(
                            backgroundColor: item.isRead
                                ? Colors.grey[200]
                                : const Color(0xFF1E3A8A).withOpacity(0.1),
                            child: Icon(
                              _notificationIcon(item.type),
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
  }

  IconData _notificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'activity':
      case 'success':
      case 'error':
      case 'event':
        return Icons.event;
      case 'news':
        return Icons.newspaper;
      case 'training':
        return Icons.assignment_turned_in;
      case 'contact':
        return Icons.support_agent;
      default:
        return Icons.notifications;
    }
  }

  Future<void> _openNotificationTarget(
    BuildContext context,
    NotificationModel item,
    AppStateService appState,
  ) async {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    switch (item.type.toLowerCase()) {
      case 'activity':
      case 'event':
      case 'success':
      case 'error':
        final eventId = item.relatedId;
        if (eventId != null && eventId.isNotEmpty) {
          final event = appState.events.cast<Event?>().firstWhere(
                (value) => value?.id == eventId,
                orElse: () => null,
              );
          if (event != null) {
            final memberId = appState.currentUser?['id']?.toString() ?? '';
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EventDetailMemberScreen(
                  event: event,
                  memberId: memberId,
                ),
              ),
            );
            return;
          }
        }
        setState(() {
          _currentTab = 1;
        });
        return;
      case 'news':
        final newsId = int.tryParse(item.relatedId ?? '');
        if (newsId != null) {
          final article = appState.news
              .where((item) => item.status == 'published')
              .cast<NewsItem?>()
              .firstWhere(
                (value) => value?.id == newsId,
                orElse: () => null,
              );
          if (article != null) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NewsDetailScreen(news: article),
              ),
            );
            return;
          }
        }
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewsListScreen()),
        );
        return;
      case 'training':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TrainingScoreMyScreen()),
        );
        return;
      case 'contact':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ContactScreen()),
        );
        return;
      default:
        return;
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} $hour:$minute';
  }
}
