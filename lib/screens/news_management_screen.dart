import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../models/news_item.dart';
import '../services/app_state_service.dart';
import '../widgets/carousel.dart';
import '../widgets/carousel.dart';

class NewsManagementScreen extends StatefulWidget {
  const NewsManagementScreen({super.key});

  @override
  State<NewsManagementScreen> createState() => _NewsManagementScreenState();
}

class _NewsManagementScreenState extends State<NewsManagementScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  final List<String> _logos = [
    'assets/images/logo.jpg',
    'assets/images/fitdnu_logo.png',
  ];
  int _selectedTabIndex = 0;
  String _historyFilter = 'all';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    Future.microtask(() {
      Provider.of<AppStateService>(context, listen: false).refreshNews();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final textTheme = GoogleFonts.manropeTextTheme(baseTheme.textTheme);

    return Theme(
      data: baseTheme.copyWith(textTheme: textTheme),
      child: Scaffold(
        backgroundColor: _NewsTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          toolbarHeight: 56,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: _NewsTheme.textPrimary,
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 0,
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
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Khoa CNTT',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
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
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bộ lọc đang được phát triển')),
                );
              },
              icon: const Icon(Icons.search_rounded),
              color: _NewsTheme.textPrimary,
              tooltip: 'Tìm kiếm',
            ),
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const _NewsArchiveScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.inventory_2_outlined),
              color: _NewsTheme.textPrimary,
              tooltip: 'Kho lưu',
            ),
          ],
        ),
        body: Container(
          color: _NewsTheme.background,
          child: Consumer<AppStateService>(
            builder: (context, appState, _) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0, 0.02),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: appState.isLoadingNews
                    ? NewsSkeletonList(
                        key: const ValueKey('loading'),
                        pulse: _pulseController,
                      )
                    : _buildLoadedState(context, appState),
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openCreateDialog(context),
          backgroundColor: _NewsTheme.fab,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Đăng bài mới'),
        ),
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context, AppStateService appState) {
    final items = _itemsForSelectedTab(appState);
    if (items.isEmpty) {
      return _buildEmptyState(context, tabIndex: _selectedTabIndex);
    }

    return RefreshIndicator(
      color: _NewsTheme.primary,
      onRefresh: appState.refreshNews,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildTabHeader(),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Tổng cộng: ${items.length} bài viết',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _NewsTheme.textSecondary,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.tune, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Lọc theo',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          NewsList(
            key: ValueKey('loaded-$_selectedTabIndex'),
            items: items,
            selectedTabIndex: _selectedTabIndex,
            onDelete: (news) => _confirmDelete(context, news, appState),
            onEdit: (news) => _openEditDialog(context, news),
            onArchive: (news) => _confirmArchive(context, news, appState),
            onRestore: (news) => _confirmRestore(context, news, appState),
          ),
        ],
      ),
    );
  }

  List<NewsItem> _itemsForSelectedTab(AppStateService appState) {
    final newsItems = appState.news
        .where((item) => item.category.toLowerCase() == 'news')
        .toList()
      ..sort(compareNewsItems);
    final announcementItems = appState.news
        .where((item) => item.category.toLowerCase() == 'announcement')
        .toList()
      ..sort(compareNewsItems);

    switch (_selectedTabIndex) {
      case 0:
        return newsItems;
      case 1:
        return announcementItems;
      case 2:
      default:
        return newsItems;
    }
  }

  Widget _buildEmptyState(BuildContext context, {required int tabIndex}) {
    final title = switch (tabIndex) {
      0 => 'Chưa có tin tức nào',
      1 => 'Chưa có thông báo nào',
      _ => 'Chưa có tin nào',
    };
    final subtitle = switch (tabIndex) {
      0 => 'Hãy tạo bài đăng mới để cập nhật thông tin cho đoàn viên.',
      1 => 'Thông báo sẽ hiển thị ở đây khi được tạo.',
      _ => 'Dữ liệu sẽ hiển thị ở đây khi có bài viết phù hợp.',
    };

    return RefreshIndicator(
      color: _NewsTheme.primary,
      onRefresh: () =>
          Provider.of<AppStateService>(context, listen: false).refreshNews(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildTabHeader(),
          const SizedBox(height: 20),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _NewsTheme.card,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xAA000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _NewsTheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(Icons.newspaper,
                        size: 36, color: _NewsTheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _NewsTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: _NewsTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabHeader() {
    final tabs = const ['Tin tức', 'Thông báo'];

    return Container(
      height: 46,
      padding: const EdgeInsets.only(left: 2, right: 2, top: 2),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _NewsTheme.divider, width: 1),
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    tabs[index],
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? const Color(0xFF60A5FA)
                          : _NewsTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 3,
                    width: 52,
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF2563EB)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    NewsItem news,
    AppStateService appState,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa tin tức này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await appState.deleteNews(news.id.toString());
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa tin tức')),
              );
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _confirmArchive(
    BuildContext context,
    NewsItem news,
    AppStateService appState,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Gỡ bài tin tức'),
        content: const Text(
          'Bạn có chắc chắn muốn gỡ bài tin tức này? Nó sẽ không hiển thị trên trang chủ và sẽ được chuyển vào lịch sử.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await appState.archiveNews(news.id.toString());
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã gỡ bài và chuyển vào lịch sử')),
              );
            },
            child: const Text('Gỡ bài'),
          ),
        ],
      ),
    );
  }

  void _confirmRestore(
    BuildContext context,
    NewsItem news,
    AppStateService appState,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Khôi phục tin tức'),
        content: const Text('Bạn có chắc chắn muốn khôi phục tin tức này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await appState.restoreNews(news.id.toString());
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã khôi phục tin tức')),
              );
            },
            child: const Text('Khôi phục'),
          ),
        ],
      ),
    );
  }

  void _openCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _NewsCreateSheet(),
    );
  }

  void _openEditDialog(BuildContext context, NewsItem news) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NewsCreateSheet(initialNews: news),
    );
  }
}

class _NewsArchiveScreen extends StatefulWidget {
  const _NewsArchiveScreen();

  @override
  State<_NewsArchiveScreen> createState() => _NewsArchiveScreenState();
}

class _NewsArchiveScreenState extends State<_NewsArchiveScreen>
    with SingleTickerProviderStateMixin {
  final List<String> _logos = [
    'assets/images/fitdnu_logo.png',
    'assets/images/fitdnu_logo.png',
  ];
  final TextEditingController _searchController = TextEditingController();
  String _selectedTab = 'news';
  String _query = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<AppStateService>(context, listen: false).refreshNews();
    });
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _NewsTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        toolbarHeight: 65,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: _NewsTheme.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
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
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'Kho lưu trữ',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
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
      ),
      body: Consumer<AppStateService>(
        builder: (context, appState, _) {
          final archivedItems = appState.news
              .where((item) => item.status.toLowerCase() == 'archived')
              .where((item) => _selectedTab == 'news'
                  ? item.category.toLowerCase() == 'news'
                  : item.category.toLowerCase() == 'announcement')
              .where((item) {
                if (_query.isEmpty) return true;
                final title = item.title.toLowerCase();
                final description = item.description.toLowerCase();
                return title.contains(_query) || description.contains(_query);
              })
              .toList()
            ..sort(compareNewsItems);

          return RefreshIndicator(
            color: _NewsTheme.primary,
            onRefresh: appState.refreshNews,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _ArchiveSearchBar(
                  controller: _searchController,
                  onFilterTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bộ lọc đang được phát triển')),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ArchiveTabBar(
                  selectedTab: _selectedTab,
                  onChanged: (value) => setState(() => _selectedTab = value),
                ),
                const SizedBox(height: 16),
                if (archivedItems.isEmpty)
                  _ArchiveEmptyState(selectedTab: _selectedTab)
                else
                  ...List.generate(archivedItems.length, (index) {
                    final news = archivedItems[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: index == archivedItems.length - 1 ? 0 : 12),
                      child: _ArchiveNewsCard(news: news),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ArchiveSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onFilterTap;

  const _ArchiveSearchBar({
    required this.controller,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bài viết...',
                hintStyle: GoogleFonts.manrope(
                  fontSize: 13,
                  color: _NewsTheme.textSecondary,
                ),
                prefixIcon: const Icon(Icons.search, size: 20),
                prefixIconColor: _NewsTheme.textSecondary,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              style: GoogleFonts.manrope(fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: IconButton(
            onPressed: onFilterTap,
            icon: const Icon(Icons.tune, size: 20),
            color: _NewsTheme.textPrimary,
            tooltip: 'Lọc',
          ),
        ),
      ],
    );
  }
}

class _ArchiveTabBar extends StatelessWidget {
  final String selectedTab;
  final ValueChanged<String> onChanged;

  const _ArchiveTabBar({
    required this.selectedTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = const [
      ('news', 'Tin tức'),
      ('announcement', 'Thông báo'),
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _NewsTheme.divider, width: 1),
        ),
      ),
      child: Row(
        children: tabs.map((tab) {
          final value = tab.$1;
          final label = tab.$2;
          final selected = selectedTab == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(value),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected ? _NewsTheme.primary : _NewsTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 3,
                    width: 58,
                    decoration: BoxDecoration(
                      color: selected ? _NewsTheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ArchiveEmptyState extends StatelessWidget {
  final String selectedTab;

  const _ArchiveEmptyState({required this.selectedTab});

  @override
  Widget build(BuildContext context) {
    final title = selectedTab == 'news'
        ? 'Chưa có bài tin tức nào'
        : 'Chưa có bài thông báo nào';

    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 36),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: _NewsTheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 40,
                color: _NewsTheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _NewsTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Các bài đã gỡ hoặc lưu trữ sẽ xuất hiện tại đây.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: _NewsTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchiveNewsCard extends StatelessWidget {
  final NewsItem news;

  const _ArchiveNewsCard({required this.news});

  @override
  Widget build(BuildContext context) {
    final statusText = news.status == 'archived' ? 'Đã gỡ' : 'Đã đăng';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _NewsThumbnail(
                image: news.image,
                width: 92,
                height: 92,
                radius: 12,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0ECFF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          news.category.toLowerCase() == 'announcement' ? 'THÔNG BÁO' : 'TIN TỨC',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        news.date,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _NewsTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    news.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _NewsTheme.textPrimary,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.brightness_1, size: 8, color: Color(0xFF2563EB)),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2563EB),
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
}

class _NewsCreateSheet extends StatefulWidget {
  final NewsItem? initialNews;

  const _NewsCreateSheet({this.initialNews});

  @override
  State<_NewsCreateSheet> createState() => _NewsCreateSheetState();
}

class _NewsCreateSheetState extends State<_NewsCreateSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _type = 'news';
  String _status = 'published';
  bool _pinned = false;
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  Uint8List? _pickedCoverImageBytes;
  String? _pickedCoverImageName;
  final List<Uint8List> _pickedGalleryImageBytes = [];
  final List<String> _pickedGalleryImageNames = [];
  String? _existingImageUrl;
  final List<String> _existingGalleryImageUrls = [];
  DateTime? _scheduledAt;

  @override
  void initState() {
    super.initState();
    final news = widget.initialNews;
    if (news != null) {
      _titleController.text = news.title;
      _contentController.text = news.content;
      _type = news.category == 'announcement' ? 'announcement' : 'news';
      // Convert archived status to draft so it can be re-published
      _status = news.status == 'archived' ? 'draft' : news.status;
      _pinned = news.pinned;
      _existingImageUrl = news.image;
      _existingGalleryImageUrls.addAll(news.galleryImages);
      _scheduledAt = news.publishedAtValue ?? news.publishedAt;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).viewInsets;
    final baseDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.borderColor),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      labelStyle: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
      hintStyle: GoogleFonts.manrope(
        fontSize: 12,
        color: AppColors.textSecondary,
      ),
    );

    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                      color: AppColors.primary,
                      iconSize: 24,
                    ),
                    Text(
                      widget.initialNews == null
                          ? 'Tạo tin tức mới'
                          : 'Chỉnh sửa tin tức',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Hướng dẫn chỉnh sửa tin tức')),
                    );
                  },
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          Divider(color: AppColors.borderColor, height: 1),
          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, padding.bottom + 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Description
                  Text(
                    'Cập nhật thông tin',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: baseDecoration.copyWith(labelText: 'Tiêu đề *'),
                    style: GoogleFonts.manrope(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contentController,
                    maxLines: 4,
                    decoration: baseDecoration.copyWith(
                      labelText: 'Nội dung *',
                      alignLabelWithHint: true,
                    ),
                    style: GoogleFonts.manrope(fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  // Cover Image Section
                  _buildCoverImageSection(baseDecoration),
                  const SizedBox(height: 20),
                  // Schedule and Settings
                  Text(
                    'Hạn giờ & Thiết lập',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap:
                              _status == 'scheduled' ? _pickScheduleDate : null,
                          child: InputDecorator(
                            decoration: baseDecoration.copyWith(
                              labelText: 'Ngày đăng',
                              enabled: _status == 'scheduled',
                            ),
                            child: Text(
                              _status == 'scheduled' && _scheduledAt != null
                                  ? DateFormat('dd/MM/yyyy')
                                      .format(_scheduledAt!)
                                  : 'Chọn ngày',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: _status == 'scheduled'
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap:
                              _status == 'scheduled' ? _pickScheduleTime : null,
                          child: InputDecorator(
                            decoration: baseDecoration.copyWith(
                              labelText: 'Giờ đăng',
                              enabled: _status == 'scheduled',
                            ),
                            child: Text(
                              _status == 'scheduled' && _scheduledAt != null
                                  ? DateFormat('HH:mm').format(_scheduledAt!)
                                  : 'Chọn giờ',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: _status == 'scheduled'
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _type,
                          decoration:
                              baseDecoration.copyWith(labelText: 'Loại'),
                          items: const [
                            DropdownMenuItem(
                                value: 'news', child: Text('Tin tức')),
                            DropdownMenuItem(
                                value: 'announcement',
                                child: Text('Thông báo')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _type = value ?? 'news';
                            });
                          },
                          icon: const SizedBox.shrink(),
                          isExpanded: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _status,
                          decoration:
                              baseDecoration.copyWith(labelText: 'Trạng thái'),
                          items: const [
                            DropdownMenuItem(
                              value: 'scheduled',
                              child: Text('Hẹn giờ đăng'),
                            ),
                            DropdownMenuItem(
                                value: 'published', child: Text('Đăng')),
                            DropdownMenuItem(
                                value: 'draft', child: Text('Nháp')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _status = value ?? 'draft';
                              if (_status == 'scheduled') {
                                _scheduledAt = DateTime.now()
                                    .add(const Duration(hours: 1));
                              } else if (_status == 'published') {
                                _scheduledAt = DateTime.now();
                              } else {
                                _scheduledAt = null;
                              }
                            });
                          },
                          icon: const SizedBox.shrink(),
                          isExpanded: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(Icons.check_circle, size: 20),
                      label: Text(
                        _isSubmitting
                            ? (widget.initialNews == null
                                ? 'Đang tạo...'
                                : 'Đang cập nhật...')
                            : (widget.initialNews == null
                                ? 'Tạo tin tức'
                                : 'Cập nhật tin tức'),
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImageSection(InputDecoration baseDecoration) {
    final hasPickedCover = _pickedCoverImageBytes != null;
    final hasExisting =
        _existingImageUrl != null && _existingImageUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ảnh bìa bản tin',
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasPickedCover)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    _pickedCoverImageBytes!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else if (hasExisting)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildExistingImage(_existingImageUrl!),
                )
              else
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 40,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickCoverImage,
                      icon: const Icon(Icons.upload, size: 18),
                      label: const Text('Dự án bìa'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickGalleryImages,
                      icon: const Icon(Icons.add_photo_alternate, size: 18),
                      label: const Text('Thêm ảnh'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker(InputDecoration baseDecoration) {
    final hasPickedCover = _pickedCoverImageBytes != null;
    final hasExisting =
        _existingImageUrl != null && _existingImageUrl!.isNotEmpty;
    final hasPickedGallery = _pickedGalleryImageBytes.isNotEmpty;
    final hasExistingGallery = _existingGalleryImageUrls.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ảnh bìa',
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderColor),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              if (hasPickedCover)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _pickedCoverImageBytes!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else if (hasExisting)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildExistingImage(_existingImageUrl!),
                )
              else
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.image, size: 40, color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 160,
                    child: OutlinedButton.icon(
                      onPressed: _isUploadingImage ? null : _pickCoverImage,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(
                        _isUploadingImage
                            ? 'Đang tải...'
                            : (hasPickedCover || hasExisting)
                                ? 'Đổi ảnh bìa'
                                : 'Chọn ảnh bìa',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: AppColors.borderColor),
                        foregroundColor: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: OutlinedButton.icon(
                      onPressed: _isUploadingImage ? null : _pickGalleryImages,
                      icon: const Icon(Icons.collections_outlined),
                      label: const Text('Thêm nhiều ảnh'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: AppColors.borderColor),
                        foregroundColor: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (hasPickedCover)
                    SizedBox(
                      width: 52,
                      child: IconButton(
                        onPressed:
                            _isUploadingImage ? null : _clearPickedCoverImage,
                        icon: const Icon(Icons.close),
                        color: Colors.redAccent,
                      ),
                    ),
                ],
              ),
              if (hasPickedGallery || hasExistingGallery) ...[
                const SizedBox(height: 12),
                _buildGalleryPreview(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSchedulePicker(InputDecoration baseDecoration) {
    final isScheduled = _status == 'scheduled';
    final dateLabel = _scheduledAt == null
        ? 'Chưa chọn'
        : DateFormat('dd/MM/yyyy').format(_scheduledAt!);
    final timeLabel = _scheduledAt == null
        ? 'Chưa chọn'
        : DateFormat('HH:mm').format(_scheduledAt!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hẹn giờ đăng bài',
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: isScheduled ? _pickScheduleDate : null,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: baseDecoration.copyWith(
                    labelText: 'Ngày đăng',
                    suffixIcon: const Icon(Icons.event),
                    enabled: isScheduled,
                  ),
                  child: Text(
                    isScheduled ? dateLabel : 'Chọn trạng thái “Hẹn giờ đăng”',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: isScheduled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: isScheduled ? _pickScheduleTime : null,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: baseDecoration.copyWith(
                    labelText: 'Giờ đăng',
                    suffixIcon: const Icon(Icons.schedule),
                    enabled: isScheduled,
                  ),
                  child: Text(
                    isScheduled ? timeLabel : 'Chọn trạng thái “Hẹn giờ đăng”',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: isScheduled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGalleryPreview() {
    final thumbs = <Widget>[];

    for (final bytes in _pickedGalleryImageBytes) {
      thumbs.add(_buildGalleryThumb(Image.memory(bytes, fit: BoxFit.cover)));
    }

    for (final url in _existingGalleryImageUrls) {
      thumbs.add(_buildGalleryThumb(_buildStoredImage(url)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ảnh bổ sung',
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: thumbs),
      ],
    );
  }

  Widget _buildGalleryThumb(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(width: 72, height: 72, child: child),
    );
  }

  Widget _buildExistingImage(String imageUrl) {
    final isNetwork = imageUrl.startsWith('http');
    return SizedBox(
      height: 140,
      width: double.infinity,
      child: isNetwork
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildImageFallback(),
            )
          : Image.asset(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildImageFallback(),
            ),
    );
  }

  Widget _buildStoredImage(String imageUrl) {
    final isNetwork = imageUrl.startsWith('http');
    return isNetwork
        ? Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildImageFallback(),
          )
        : Image.asset(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildImageFallback(),
          );
  }

  Widget _buildImageFallback() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.image, size: 40, color: Colors.grey),
      ),
    );
  }

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    setState(() {
      _pickedCoverImageBytes = bytes;
      _pickedCoverImageName =
          file.name.isNotEmpty ? file.name : 'news_cover.jpg';
    });
  }

  Future<void> _pickGalleryImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;

    final bytesList = <Uint8List>[];
    final namesList = <String>[];
    for (final file in files) {
      bytesList.add(await file.readAsBytes());
      namesList.add(file.name.isNotEmpty ? file.name : 'news_gallery.jpg');
    }

    if (!mounted) return;

    setState(() {
      _pickedGalleryImageBytes.addAll(bytesList);
      _pickedGalleryImageNames.addAll(namesList);
    });
  }

  Future<void> _pickScheduleDate() async {
    final current =
        _scheduledAt ?? DateTime.now().add(const Duration(hours: 1));
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (pickedDate == null || !mounted) return;

    setState(() {
      _scheduledAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        current.hour,
        current.minute,
      );
    });
  }

  Future<void> _pickScheduleTime() async {
    final current =
        _scheduledAt ?? DateTime.now().add(const Duration(hours: 1));
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _scheduledAt = DateTime(
        current.year,
        current.month,
        current.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _clearPickedCoverImage() {
    setState(() {
      _pickedCoverImageBytes = null;
      _pickedCoverImageName = null;
    });
  }

  Future<String?> _uploadImage(
    AppStateService appState,
    Uint8List bytes,
    String filename,
  ) async {
    final uploadResult = await appState.uploadNewsImage(
      bytes: bytes,
      filename: filename,
    );

    if (uploadResult['success'] == false) {
      return null;
    }

    final data = uploadResult['data'];
    if (data is Map && data['url'] != null) {
      return data['url']?.toString();
    }
    if (data is Map && data['cover_image_url'] != null) {
      return data['cover_image_url']?.toString();
    }
    return null;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ tiêu đề và nội dung.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_status == 'scheduled' && _scheduledAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn thời gian hẹn giờ đăng bài.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_status == 'scheduled' &&
        _scheduledAt != null &&
        !_scheduledAt!.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thời gian hẹn giờ phải lớn hơn thời điểm hiện tại.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final appState = Provider.of<AppStateService>(context, listen: false);
    String? coverImageUrl = _existingImageUrl;
    final galleryImageUrls = <String>[..._existingGalleryImageUrls];

    if (_pickedCoverImageBytes != null && _pickedCoverImageName != null) {
      setState(() => _isUploadingImage = true);
      coverImageUrl = await _uploadImage(
        appState,
        _pickedCoverImageBytes!,
        _pickedCoverImageName!,
      );
      if (!mounted) return;
      setState(() => _isUploadingImage = false);

      if (coverImageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tải ảnh bìa thất bại. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSubmitting = false);
        return;
      }
    }

    if (_pickedGalleryImageBytes.isNotEmpty) {
      setState(() => _isUploadingImage = true);
      for (var i = 0; i < _pickedGalleryImageBytes.length; i++) {
        final uploaded = await _uploadImage(
          appState,
          _pickedGalleryImageBytes[i],
          _pickedGalleryImageNames[i],
        );
        if (!mounted) return;
        if (uploaded == null) {
          setState(() => _isUploadingImage = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tải một hoặc nhiều ảnh bổ sung thất bại.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isSubmitting = false);
          return;
        }
        galleryImageUrls.add(uploaded);
      }
      setState(() => _isUploadingImage = false);
    }

    if ((coverImageUrl == null || coverImageUrl.isEmpty) &&
        galleryImageUrls.isNotEmpty) {
      coverImageUrl = galleryImageUrls.removeAt(0);
    }

    final publishedAt = _status == 'scheduled'
      ? _scheduledAt
      : _status == 'published'
        ? (_scheduledAt ?? DateTime.now())
        : null;

    final isEdit = widget.initialNews != null;
    final result = isEdit
        ? await appState.updateNews(
            newsId: widget.initialNews!.id.toString(),
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            type: _type,
            status: _status,
            pinned: _pinned,
            publishedAt: publishedAt,
            coverImageUrl: coverImageUrl,
            galleryImageUrls: galleryImageUrls,
          )
        : await appState.createNews(
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            type: _type,
            status: _status,
            pinned: _pinned,
            publishedAt: publishedAt,
            coverImageUrl: coverImageUrl,
            galleryImageUrls: galleryImageUrls,
          );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == false) {
      final message = result['message']?.toString() ??
          (widget.initialNews == null
              ? 'Tạo tin tức thất bại. Vui lòng thử lại.'
              : 'Cập nhật tin tức thất bại. Vui lòng thử lại.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
      return;
    }

    if (!context.mounted) return;
    await appState.refreshNews();
    // Debug: log number of news items after refresh
    // ignore: avoid_print
    print('news_management: appState.news length = ${appState.news.length}');
    if (!context.mounted) return;
    
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.initialNews == null
              ? 'Tạo tin tức thành công!'
              : 'Cập nhật tin tức thành công!',
        ),
      ),
    );
  }
}

class NewsList extends StatelessWidget {
  final List<NewsItem> items;
  final int selectedTabIndex;
  final ValueChanged<NewsItem> onDelete;
  final ValueChanged<NewsItem> onEdit;
  final ValueChanged<NewsItem>? onArchive;
  final ValueChanged<NewsItem>? onRestore;

  const NewsList({
    required this.items,
    required this.selectedTabIndex,
    required this.onDelete,
    required this.onEdit,
    this.onArchive,
    this.onRestore,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final news = items[index];
        if (index == 0) {
          return FeaturedNewsCard(
            news: news,
            onDelete: () => onDelete(news),
            onEdit: () => onEdit(news),
            onTap: () => onEdit(news),
            onArchive: onArchive != null ? () => onArchive!(news) : null,
            onRestore: onRestore != null ? () => onRestore!(news) : null,
            isHistory: selectedTabIndex == 2,
          );
        }
        return NewsCard(
          news: news,
          isHistory: selectedTabIndex == 2,
          onDelete: () => onDelete(news),
          onEdit: () => onEdit(news),
          onTap: () => onEdit(news),
          onArchive: onArchive != null ? () => onArchive!(news) : null,
          onRestore: onRestore != null ? () => onRestore!(news) : null,
        );
      },
    );
  }
}

class FeaturedNewsCard extends StatelessWidget {
  final NewsItem news;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onRestore;
  final bool isHistory;

  const FeaturedNewsCard({
    required this.news,
    required this.onDelete,
    required this.onEdit,
    required this.onTap,
    this.onArchive,
    this.onRestore,
    this.isHistory = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _NewsTheme.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: _NewsTheme.border, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 190,
                      width: double.infinity,
                      child: _NewsThumbnail(
                          image: news.image,
                          width: double.infinity,
                          height: 190,
                          radius: 0),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D4ED8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Nổi bật',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            news.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _NewsTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          color: Colors.white,
                          surfaceTintColor: Colors.white,
                          elevation: 10,
                          offset: const Offset(0, 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: const Color(0xFFE5E7EB).withOpacity(0.9),
                            ),
                          ),
                          onSelected: (value) {
                            if (value == 'edit') onEdit();
                            if (value == 'delete') onDelete();
                            if (value == 'archive') onArchive?.call();
                            if (value == 'restore') onRestore?.call();
                          },
                          itemBuilder: (context) {
                            final items = <PopupMenuEntry<String>>[
                              _buildNewsActionMenuItem(
                                value: 'edit',
                                label: 'Chỉnh sửa',
                                icon: Icons.edit_rounded,
                                iconColor: const Color(0xFF2563EB),
                              ),
                            ];

                            if (news.status == 'archived') {
                              items.add(_buildNewsActionMenuItem(
                                value: 'restore',
                                label: 'Khôi phục',
                                icon: Icons.restore_rounded,
                                iconColor: const Color(0xFFF59E0B),
                              ));
                            } else {
                              items.add(_buildNewsActionMenuItem(
                                value: 'archive',
                                label: 'Gỡ bài',
                                icon: Icons.visibility_off_rounded,
                                iconColor: const Color(0xFFF59E0B),
                              ));
                            }

                                items.add(const PopupMenuDivider(height: 10));

                            items.add(_buildNewsActionMenuItem(
                              value: 'delete',
                              label: 'Xóa bài viết',
                              icon: Icons.delete_outline,
                              iconColor: const Color(0xFFEF4444),
                              labelColor: const Color(0xFFEF4444),
                              isDanger: true,
                            ));

                            return items;
                          },
                          child: const Icon(Icons.more_vert, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      news.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _NewsTheme.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 14, color: _NewsTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          news.date,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _NewsTheme.textSecondary,
                            fontWeight: FontWeight.w600,
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
}

class NewsCard extends StatelessWidget {
  final NewsItem news;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onRestore;
  final bool isHistory;

  const NewsCard({
    required this.news,
    required this.onDelete,
    required this.onEdit,
    required this.onTap,
    this.onArchive,
    this.onRestore,
    this.isHistory = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (isHistory) {
      return Container(
        decoration: BoxDecoration(
          color: _NewsTheme.card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFE6E9EE)),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _NewsThumbnail(
                        image: news.image, width: 96, height: 84, radius: 12),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            NewsBadge(type: news.category),
                            const SizedBox(width: 8),
                            _StatusPill(status: news.status),
                            const Spacer(),
                            PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.more_horiz,
                                  size: 18, color: _NewsTheme.textSecondary),
                              color: Colors.white,
                              surfaceTintColor: Colors.white,
                              elevation: 10,
                              offset: const Offset(0, 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: BorderSide(
                                  color: const Color(0xFFE5E7EB).withOpacity(0.9),
                                ),
                              ),
                              onSelected: (value) {
                                if (value == 'edit') onEdit();
                                if (value == 'delete') onDelete();
                                if (value == 'archive') onArchive?.call();
                                if (value == 'restore') onRestore?.call();
                              },
                              itemBuilder: (context) {
                                final items = <PopupMenuEntry<String>>[
                                  _buildNewsActionMenuItem(
                                    value: 'edit',
                                    label: 'Chỉnh sửa',
                                    icon: Icons.edit_rounded,
                                    iconColor: const Color(0xFF2563EB),
                                  ),
                                ];
                                if (news.status == 'archived') {
                                  items.add(_buildNewsActionMenuItem(
                                    value: 'restore',
                                    label: 'Khôi phục',
                                    icon: Icons.restore_rounded,
                                    iconColor: const Color(0xFFF59E0B),
                                  ));
                                } else {
                                  items.add(_buildNewsActionMenuItem(
                                    value: 'archive',
                                    label: 'Gỡ bài',
                                    icon: Icons.visibility_off_rounded,
                                    iconColor: const Color(0xFFF59E0B),
                                  ));
                                }
                                items.add(_buildNewsActionMenuItem(
                                  value: 'delete',
                                  label: 'Xóa bài viết',
                                  icon: Icons.delete_outline,
                                  iconColor: const Color(0xFFEF4444),
                                  labelColor: const Color(0xFFEF4444),
                                  isDanger: true,
                                ));
                                return items;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          news.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _NewsTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 14, color: _NewsTheme.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              news.date,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: _NewsTheme.textSecondary),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.remove_red_eye_outlined,
                                size: 14, color: _NewsTheme.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              '0 lượt xem',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: _NewsTheme.textSecondary),
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
        ),
      );
    }

    // Regular (non-history) card layout
    return Container(
      decoration: BoxDecoration(
        color: _NewsTheme.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE6E9EE)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _NewsThumbnail(
                      image: news.image, width: 96, height: 84, radius: 12),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          NewsBadge(type: news.category),
                          const SizedBox(width: 8),
                          _StatusPill(status: news.status),
                          const Spacer(),
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.more_horiz,
                                size: 18, color: _NewsTheme.textSecondary),
                            color: Colors.white,
                            surfaceTintColor: Colors.white,
                            elevation: 10,
                            offset: const Offset(0, 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: const Color(0xFFE5E7EB).withOpacity(0.9),
                              ),
                            ),
                            onSelected: (value) {
                              if (value == 'edit') onEdit();
                              if (value == 'delete') onDelete();
                              if (value == 'archive') onArchive?.call();
                              if (value == 'restore') onRestore?.call();
                            },
                            itemBuilder: (context) {
                              final items = <PopupMenuEntry<String>>[
                                _buildNewsActionMenuItem(
                                  value: 'edit',
                                  label: 'Chỉnh sửa',
                                  icon: Icons.edit_rounded,
                                  iconColor: const Color(0xFF2563EB),
                                ),
                              ];
                              if (news.status == 'archived') {
                                items.add(_buildNewsActionMenuItem(
                                  value: 'restore',
                                  label: 'Khôi phục',
                                  icon: Icons.restore_rounded,
                                  iconColor: const Color(0xFFF59E0B),
                                ));
                              } else {
                                items.add(_buildNewsActionMenuItem(
                                  value: 'archive',
                                  label: 'Gỡ bài',
                                  icon: Icons.visibility_off_rounded,
                                  iconColor: const Color(0xFFF59E0B),
                                ));
                              }
                              items.add(_buildNewsActionMenuItem(
                                value: 'delete',
                                label: 'Xóa bài viết',
                                icon: Icons.delete_outline,
                                iconColor: const Color(0xFFEF4444),
                                labelColor: const Color(0xFFEF4444),
                                isDanger: true,
                              ));
                              return items;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        news.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _NewsTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 14, color: _NewsTheme.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            news.date,
                            style: const TextStyle(
                                fontSize: 12, color: _NewsTheme.textSecondary),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.remove_red_eye_outlined,
                              size: 14, color: _NewsTheme.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            '0 lượt xem',
                            style: const TextStyle(
                                fontSize: 12, color: _NewsTheme.textSecondary),
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
      ),
    );
  }
}

PopupMenuItem<String> _buildNewsActionMenuItem({
  required String value,
  required String label,
  required IconData icon,
  required Color iconColor,
  Color? labelColor,
  bool isDanger = false,
}) {
  return PopupMenuItem<String>(
    value: value,
    height: 48,
    child: Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: labelColor ?? _NewsTheme.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}

class _NewsThumbnail extends StatelessWidget {
  final String image;
  final double width;
  final double height;
  final double radius;

  const _NewsThumbnail({
    required this.image,
    this.width = 72,
    this.height = 72,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isNetwork = image.startsWith('http');
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: isNetwork
            ? Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallback(),
              )
            : Image.asset(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallback(),
              ),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      color: const Color(0xFF1E293B),
      child: const Icon(Icons.image, color: Colors.white54),
    );
  }
}

class NewsBadge extends StatelessWidget {
  final String type;

  const NewsBadge({required this.type, super.key});

  @override
  Widget build(BuildContext context) {
    final isAnnouncement = type == 'announcement';
    final background =
        isAnnouncement ? _NewsTheme.badgeAnnouncement : _NewsTheme.badgeNews;
    final foreground = isAnnouncement
        ? _NewsTheme.badgeAnnouncementText
        : _NewsTheme.badgeNewsText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isAnnouncement ? 'Thông báo' : 'Tin tức',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    Color bg;
    Color fg = Colors.white;
    switch (lower) {
      case 'published':
        bg = const Color(0xFF16A34A);
        break;
      case 'draft':
        bg = const Color(0xFF9CA3AF);
        fg = Colors.white;
        break;
      case 'scheduled':
        bg = const Color(0xFF2563EB);
        break;
      case 'archived':
        bg = const Color(0xFF6B7280);
        break;
      default:
        bg = const Color(0xFF6B7280);
    }

    String text;
    if (lower == 'published') {
      text = 'Đã đăng';
    } else if (lower == 'draft') {
      text = 'Nháp';
    } else if (lower == 'scheduled') {
      text = 'Đã đặt';
    } else if (lower == 'archived') {
      text = 'Đã lưu';
    } else {
      text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class NewsSkeletonList extends StatelessWidget {
  final Animation<double> pulse;

  const NewsSkeletonList({super.key, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => _NewsSkeletonCard(pulse: pulse),
    );
  }
}

class _NewsSkeletonCard extends StatelessWidget {
  final Animation<double> pulse;

  const _NewsSkeletonCard({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _NewsTheme.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFF2A3345), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(width: 72, height: 72, radius: 12, pulse: pulse),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _SkeletonBox(width: 72, height: 20, pulse: pulse),
                    const Spacer(),
                    _SkeletonBox(
                        width: 20, height: 20, radius: 6, pulse: pulse),
                    const SizedBox(width: 8),
                    _SkeletonBox(
                        width: 20, height: 20, radius: 6, pulse: pulse),
                  ],
                ),
                const SizedBox(height: 10),
                _SkeletonBox(width: double.infinity, height: 16, pulse: pulse),
                const SizedBox(height: 8),
                _SkeletonBox(width: double.infinity, height: 12, pulse: pulse),
                const SizedBox(height: 6),
                _SkeletonBox(width: 160, height: 12, pulse: pulse),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _SkeletonBox(
                        width: 14, height: 14, radius: 4, pulse: pulse),
                    const SizedBox(width: 6),
                    _SkeletonBox(width: 90, height: 12, pulse: pulse),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final Animation<double> pulse;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.pulse,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final color = Color.lerp(
          _NewsTheme.skeletonBase,
          _NewsTheme.skeletonHighlight,
          pulse.value,
        )!;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(radius),
          ),
        );
      },
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Icon(icon, size: 20, color: color),
    );
  }
}

class _NewsTheme {
  static const Color primary = AppColors.primary;
  static const Color background = Color(0xFFF8FAFC);
  static const Color card = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color fab = Color(0xFF123C97);
  static const Color danger = AppColors.danger;
  static const Color badgeAnnouncement = Color(0xFFFFF4E5);
  static const Color badgeAnnouncementText = Color(0xFFB45309);
  static const Color badgeNews = Color(0xFFE0ECFF);
  static const Color badgeNewsText = Color(0xFF1D4ED8);
  static const Color skeletonBase = Color(0xFFE5E7EB);
  static const Color skeletonHighlight = Color(0xFFF0F1F3);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFD1D5DB);
}
