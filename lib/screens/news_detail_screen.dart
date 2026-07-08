import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/colors.dart';
import '../models/news_item.dart';
import '../services/api_service.dart';
import '../services/app_state_service.dart';

class NewsDetailScreen extends StatefulWidget {
  final NewsItem news;

  const NewsDetailScreen({super.key, required this.news});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motionController;
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  int _activeIndex = 0;

  NewsItem get news => widget.news;

  List<String> get _images {
    final images = <String>[];
    if (news.image.trim().isNotEmpty) {
      images.add(news.image);
    }
    for (final image in news.galleryImages) {
      if (image.trim().isNotEmpty && !images.contains(image)) {
        images.add(image);
      }
    }
    return images;
  }

  bool get _hasGallery => _images.length > 1;

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _motionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    if (!mounted || !_hasGallery) return;
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final nextIndex = _activeIndex >= _images.length - 1 ? 0 : _activeIndex + 1;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOut,
      );
      _activeIndex = nextIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final readMinutes = _estimateReadMinutes(news.content);
    final appState = Provider.of<AppStateService>(context);
    final relatedNews = _getRelatedNews(appState.news).take(6).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 360,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            backgroundColor: const Color(0xFFF7F8FC),
            foregroundColor: AppColors.textPrimary,
            title: Text(
              'Chi tiết tin tức',
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildAnimatedHeaderImage(),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0x0A000000), Color(0xE60F172A)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCategoryBadge(),
                        const SizedBox(height: 12),
                        Text(
                          news.title,
                          style: GoogleFonts.manrope(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildMetaRow(readMinutes, textColor: Colors.white70),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLeadCard(),
                  const SizedBox(height: 14),
                  _buildQuickInfoCard(readMinutes),
                  const SizedBox(height: 14),
                  _buildContentCard(),
                  if (relatedNews.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _buildRelatedSection(relatedNews, context),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildActionDock(context, appState),
    );
  }

  Widget _buildAnimatedHeaderImage() {
    if (_images.isEmpty) {
      return _buildImageFrame(_buildImageFallback());
    }

    final imageBuilder = (String imageUrl) {
      return _buildImageFrame(_buildResolvedImage(imageUrl));
    };

    if (_hasGallery) {
      return PageView.builder(
        controller: _pageController,
        itemCount: _images.length,
        onPageChanged: (index) => _activeIndex = index,
        itemBuilder: (context, index) => imageBuilder(_images[index]),
      );
    }

    return _buildImageFrame(
      AnimatedBuilder(
        animation: _motionController,
        builder: (context, child) {
          final shift = (0.5 - _motionController.value) * 26;
          return Transform.translate(
            offset: Offset(shift, 0),
            child: Transform.scale(scale: 1.06, child: child),
          );
        },
        child: _buildResolvedImage(_images.first),
      ),
    );
  }

  Widget _buildImageFrame(Widget child) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      child: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: child,
        ),
      ),
    );
  }

  Widget _buildResolvedImage(String imagePath) {
    final resolved = ApiService.resolveMediaUrl(imagePath) ?? imagePath;
    final isNetwork = resolved.startsWith('http');
    return isNetwork
        ? Image.network(
            resolved,
            fit: BoxFit.cover,
            width: double.infinity,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) => _buildImageFallback(),
          )
        : Image.asset(
            resolved,
            fit: BoxFit.cover,
            width: double.infinity,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) => _buildImageFallback(),
          );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFD9182E),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _categoryLabel(news.category),
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildMetaRow(int readMinutes, {required Color textColor}) {
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        _metaItem(Icons.calendar_today, news.date, textColor),
        _metaItem(Icons.timer, '$readMinutes phút đọc', textColor),
      ],
    );
  }

  Widget _metaItem(IconData icon, String label, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: textColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLeadCard() {
    final summary = news.description.trim().isNotEmpty
        ? news.description
        : news.content.trim();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDE4FA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0E0F172A),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_stories,
                    size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                'Tóm lược sự kiện',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '“$summary”',
            style: GoogleFonts.manrope(
              fontSize: 14,
              height: 1.6,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Nội dung bên dưới trình bày đầy đủ thông tin về sự kiện, thời gian, địa điểm và các lưu ý quan trọng.',
            style: GoogleFonts.manrope(
              fontSize: 13,
              height: 1.55,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoCard(int readMinutes) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAF5)),
      ),
      child: Row(
        children: [
          _buildQuickInfoItem(
            icon: Icons.folder_open,
            label: 'Danh mục',
            value: _categoryLabel(news.category),
          ),
          _buildQuickInfoDivider(),
          _buildQuickInfoItem(
            icon: Icons.calendar_today,
            label: 'Ngày đăng',
            value: news.date,
          ),
          _buildQuickInfoDivider(),
          _buildQuickInfoItem(
            icon: Icons.timer,
            label: 'Thời gian',
            value: '$readMinutes phút',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoDivider() {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: AppColors.borderColor,
    );
  }

  Widget _buildQuickInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard() {
    final hasDescription = news.description.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5EAF5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0E0F172A),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nội dung',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: const Color(0xFFE8EDF7)),
          const SizedBox(height: 16),
          if (hasDescription)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                news.description,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          SelectionArea(
            child: Text(
              news.content,
              style: GoogleFonts.manrope(
                fontSize: 15,
                height: 1.75,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lưu tin để xem lại sau hoặc chia sẻ cho bạn bè, đoàn viên trong khoa.',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<NewsItem> _getRelatedNews(List<NewsItem> items) {
    if (items.isEmpty) return [];
    final sameCategory = items
        .where((item) => item.id != news.id && item.category == news.category)
        .toList();
    if (sameCategory.isNotEmpty) return sameCategory;
    return items.where((item) => item.id != news.id).toList();
  }

  Widget _buildRelatedSection(List<NewsItem> items, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tin tức liên quan',
              style: GoogleFonts.playfairDisplay(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Xem tất cả',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 224,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _buildRelatedCard(items[index], context),
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedCard(NewsItem item, BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NewsDetailScreen(news: item),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5EAF5)),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0E0F172A),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildResolvedImage(item.image),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00000000), Color(0xAA0F172A)],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A).withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _categoryLabel(item.category),
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.date,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: AppColors.textSecondary,
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
      ),
    );
  }

  Widget _buildActionDock(BuildContext context, AppStateService appState) {
    final role = appState.currentUser?['role']?.toString().toLowerCase();
    final canArchiveFromDetail = role == 'admin';
    final canRestore = role == 'admin';
    final isAdmin = role == 'admin';

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FC),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: news.status == 'archived'
                    ? (canRestore ? () => _restoreNews(context, appState) : null)
                    : (canArchiveFromDetail
                        ? () => _archiveNews(context, appState)
                        : isAdmin
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã lưu tin'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            : null),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.22)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                icon: Icon(
                  news.status == 'archived'
                      ? Icons.restore_rounded
                      : isAdmin
                          ? Icons.remove_circle_outline_rounded
                          : Icons.bookmark_add_outlined,
                  color: AppColors.primary,
                ),
                label: Text(
                  news.status == 'archived'
                      ? 'Khôi phục'
                      : isAdmin
                          ? 'Gỡ bỏ bài'
                          : 'Lưu tin',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showShareOptions(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.share, color: Colors.white),
                label: Text(
                  'Chia sẻ ngay',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _archiveNews(
    BuildContext context,
    AppStateService appState,
  ) async {
    final result = await appState.archiveNews(news.id.toString());
    if (!context.mounted) return;
    if (result['success'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gỡ bài thất bại')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bài đã được chuyển vào kho lưu trữ')),
    );
    Navigator.pop(context);
  }

  Future<void> _restoreNews(
    BuildContext context,
    AppStateService appState,
  ) async {
    final result = await appState.restoreNews(news.id.toString());
    if (!context.mounted) return;
    if (result['success'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Khôi phục bài thất bại')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bài đã được khôi phục')),
    );
    Navigator.pop(context);
  }

  int _estimateReadMinutes(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return 1;
    final words = trimmed.split(RegExp(r'\s+')).length;
    final minutes = (words / 200).ceil();
    if (minutes < 1) return 1;
    if (minutes > 99) return 99;
    return minutes;
  }

  Widget _buildImageFallback() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Không có ảnh',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(String category) {
    switch (category.trim().toLowerCase()) {
      case 'announcement':
        return 'Thông báo';
      case 'news':
      default:
        return 'Tin tức';
    }
  }

  void _showShareOptions(BuildContext context) {
    final newsTitle = news.title;
    final newsUrl = '${ApiService.baseUrl}/news/${news.id}/preview';
    final shareText = '$newsTitle\n\nXem thêm tại: $newsUrl';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
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
                    const SizedBox(height: 20),
                    Text(
                      'Chia sẻ tin tức',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GridView.count(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildShareOption(
                          icon: Icons.facebook,
                          label: 'Facebook',
                          color: const Color(0xFF1877F2),
                          onTap: () => _shareFacebook(newsUrl, newsTitle, context),
                        ),
                        _buildShareOption(
                          icon: Icons.message,
                          label: 'Zalo',
                          color: const Color(0xFF0084FF),
                          onTap: () => _shareZalo(shareText, context),
                        ),
                        _buildShareOption(
                          icon: Icons.camera_alt,
                          label: 'Instagram',
                          color: const Color(0xFFE4405F),
                          onTap: () => _shareInstagram(shareText, context),
                        ),
                        _buildShareOption(
                          icon: Icons.chat,
                          label: 'WhatsApp',
                          color: const Color(0xFF25D366),
                          onTap: () => _shareWhatsApp(shareText, context),
                        ),
                        _buildShareOption(
                          icon: Icons.sms,
                          label: 'SMS',
                          color: const Color(0xFF34C759),
                          onTap: () => _shareSMS(shareText, context),
                        ),
                        _buildShareOption(
                          icon: Icons.link,
                          label: 'Sao chép',
                          color: AppColors.primary,
                          onTap: () => _copyToClipboard(newsUrl, context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareFacebook(String url, String title, BuildContext context) async {
    try {
      final facebookUrl = 'fb://facewebmodal/f?href=${Uri.encodeComponent(url)}';
      final webUrl = 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(url)}';
      if (await canLaunchUrl(Uri.parse(facebookUrl))) {
        await launchUrl(Uri.parse(facebookUrl));
      } else if (await canLaunchUrl(Uri.parse(webUrl))) {
        await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể chia sẻ trên Facebook'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi chia sẻ'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _shareZalo(String text, BuildContext context) async {
    try {
      final zaloUrl = 'zalo://qr/share?text=${Uri.encodeComponent(text)}';
      if (await canLaunchUrl(Uri.parse(zaloUrl))) {
        await launchUrl(Uri.parse(zaloUrl));
      } else {
        if (context.mounted) {
          Navigator.pop(context);
          await _copyToClipboard(text, context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi chia sẻ trên Zalo'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _shareInstagram(String text, BuildContext context) async {
    try {
      final instagramUrl = 'instagram://user';
      if (await canLaunchUrl(Uri.parse(instagramUrl))) {
        await launchUrl(Uri.parse(instagramUrl));
      } else {
        if (context.mounted) {
          Navigator.pop(context);
          await _copyToClipboard(text, context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi chia sẻ trên Instagram'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _shareWhatsApp(String text, BuildContext context) async {
    try {
      final whatsappUrl = 'whatsapp://send?text=${Uri.encodeComponent(text)}';
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl));
      } else {
        if (context.mounted) {
          Navigator.pop(context);
          await _copyToClipboard(text, context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi chia sẻ trên WhatsApp'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _shareSMS(String text, BuildContext context) async {
    try {
      final smsUrl = 'sms:?body=${Uri.encodeComponent(text)}';
      if (await canLaunchUrl(Uri.parse(smsUrl))) {
        await launchUrl(Uri.parse(smsUrl));
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể chia sẻ qua SMS'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi chia sẻ qua SMS'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _copyToClipboard(String text, BuildContext context) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã sao chép vào clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi sao chép'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
