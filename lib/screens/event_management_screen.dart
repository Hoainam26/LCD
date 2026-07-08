import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../models/event_model.dart';
import '../services/api_service.dart';
import '../services/app_state_service.dart';
import 'event_detail_screen.dart';
import 'create_event_dialog.dart';

class EventManagementScreen extends StatefulWidget {
  const EventManagementScreen({super.key});

  @override
  State<EventManagementScreen> createState() => _EventManagementScreenState();
}

class _EventManagementScreenState extends State<EventManagementScreen>
    with SingleTickerProviderStateMixin {
  String _activeFilter = 'Hiện tại';
  bool _isLoading = false;
  final List<Event> _events = [];
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _loadActivities();
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
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          title: Text(
            'Quản lý Hoạt động',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          backgroundColor: AppColors.surfaceColor,
          foregroundColor: AppColors.textPrimary,
          actions: [
            if (_selectionMode && _selectedIds.isNotEmpty)
              IconButton(
                tooltip: 'Xóa đã chọn',
                onPressed: _confirmBulkDelete,
                icon: const Icon(Icons.delete, color: AppColors.danger),
              ),
            const SizedBox(width: 8),
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
          child: AnimatedSwitcher(
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
            child: _isLoading
                ? _buildLoadingState(key: const ValueKey('loading'))
                : _buildLoadedState(key: const ValueKey('loaded')),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateEventDialog(context),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add),
          label: const Text('Tạo mới'),
        ),
      ),
    );
  }

  Widget _buildLoadedState({Key? key}) {
    final visibleEvents = _filteredEvents();
    return RefreshIndicator(
      key: key,
      onRefresh: _loadActivities,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(_events),
          const SizedBox(height: 12),
          _buildFilterRow(),
          const SizedBox(height: 16),
          if (visibleEvents.isEmpty)
            _buildEmptyFilterState()
          else
            ...visibleEvents
                .map((event) => _buildEventCard(context, event))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildLoadingState({Key? key}) {
    return ListView(
      key: key,
      padding: const EdgeInsets.all(16),
      children: [
        _buildSkeletonSummaryCard(),
        const SizedBox(height: 12),
        _buildSkeletonFilterRow(),
        const SizedBox(height: 16),
        _buildSkeletonEventCard(),
        const SizedBox(height: 12),
        _buildSkeletonEventCard(),
      ],
    );
  }

  // ================= SUMMARY =================
  Widget _buildSummaryCard(List<Event> events) {
    final now = DateTime.now();
    final upcomingCount = events.where((e) => e.dateTime.isAfter(now)).length;
    final ongoingCount = events.where((e) => e.isOngoing && !e.isClosed).length;
    final endedCount = events.where((e) => e.hasEnded || e.isClosed).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final maxWidth = constraints.maxWidth;
        final columns = maxWidth >= 520 ? 4 : 2;
        final childAspectRatio = columns == 4 ? 2.8 : 2.4;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                blurRadius: 10,
                offset: Offset(0, 4),
                color: Colors.black12,
              ),
            ],
          ),
          child: GridView.count(
            crossAxisCount: columns,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildSummaryItem(
                'Hoạt động',
                events.length.toString(),
                Icons.event,
              ),
              _buildSummaryItem(
                'Sắp tới',
                upcomingCount.toString(),
                Icons.schedule,
              ),
              _buildSummaryItem(
                'Đang diễn ra',
                ongoingCount.toString(),
                Icons.play_circle,
              ),
              _buildSummaryItem(
                'Đã kết thúc',
                endedCount.toString(),
                Icons.flag,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeletonSummaryCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final columns = constraints.maxWidth >= 520 ? 4 : 2;
        final childAspectRatio = columns == 4 ? 2.4 : 1.35;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                blurRadius: 10,
                offset: Offset(0, 4),
                color: Colors.black12,
              ),
            ],
          ),
          child: GridView.count(
            crossAxisCount: columns,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(4, (_) => _buildSkeletonSummaryItem()),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonSummaryItem() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSkeletonBox(width: 32, height: 32, radius: 10),
          const SizedBox(height: 8),
          _buildSkeletonBox(width: 30, height: 16, radius: 8),
          const SizedBox(height: 4),
          _buildSkeletonBox(width: 68, height: 12, radius: 8),
        ],
      ),
    );
  }

  Widget _buildSkeletonFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildSkeletonBox(width: 86, height: 34, radius: 999),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonEventCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
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
          _buildSkeletonBox(width: 160, height: 16, radius: 8),
          const SizedBox(height: 10),
          _buildSkeletonBox(width: double.infinity, height: 12, radius: 8),
          const SizedBox(height: 6),
          _buildSkeletonBox(width: 220, height: 12, radius: 8),
          const SizedBox(height: 12),
          _buildSkeletonBox(width: 140, height: 12, radius: 8),
          const SizedBox(height: 6),
          _buildSkeletonBox(width: 180, height: 12, radius: 8),
          const SizedBox(height: 12),
          _buildSkeletonBox(width: double.infinity, height: 36, radius: 10),
        ],
      ),
    );
  }

  Widget _buildSkeletonBox({
    double width = double.infinity,
    double height = 12,
    double radius = 8,
  }) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final base = const Color(0xFFE5E7EB);
        final highlight = const Color(0xFFF3F4F6);
        final color = Color.lerp(base, highlight, _pulseController.value)!;
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

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('Hiện tại', _activeFilter == 'Hiện tại'),
          _buildFilterChip('Sắp tới', _activeFilter == 'Sắp tới'),
          _buildFilterChip('Đã kết thúc', _activeFilter == 'Đã kết thúc'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _loadActivities(filter: label),
        backgroundColor: const Color(0xFFF1F5F9),
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'Chưa có hoạt động phù hợp',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
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

  // ================= EVENT CARD =================
  Widget _buildEventCard(
    BuildContext context,
    Event event,
  ) {
    final isSelected = _selectedIds.contains(event.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section with status badge
          _buildEventImage(context, event),

          // Details section: title, date, location, attendees
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  event.title ?? 'Hoạt động',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                // Date/Time
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${_formatDate(event.dateTime)} • ${event.dateTime.hour}:${event.dateTime.minute.toString().padLeft(2, '0')}',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Location
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event.location ?? 'Không xác định',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Attendees count
                Row(
                  children: [
                    Icon(
                      Icons.group,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${event.registeredCount ?? 0} người đăng ký',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                if (_selectionMode)
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(event.id),
                  ),
                // Primary button: View Details
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _viewEventDetails(context, event),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Xem chi tiết'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Secondary button: Edit
                OutlinedButton.icon(
                  onPressed: () => _showEditEventDialog(context, event),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Chỉnh sửa'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: AppColors.textSecondary.withOpacity(0.2),
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Delete icon button with rounded background
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    onPressed: () => _confirmDelete(context, event.id),
                    icon: const Icon(Icons.delete, color: AppColors.danger),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    iconSize: 20,
                    tooltip: 'Xóa',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= ACTIONS =================
  void _viewEventDetails(BuildContext context, Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(event: event),
      ),
    );
  }

  Future<void> _showCreateEventDialog(BuildContext context) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateEventDialog(),
        fullscreenDialog: true,
      ),
    );
    if (created == true && mounted) {
      setState(() {
        _activeFilter = 'Hiện tại';
      });
    }
    await _loadActivities();
  }

  Future<void> _showEditEventDialog(BuildContext context, Event event) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEventDialog(initialEvent: event),
        fullscreenDialog: true,
      ),
    );
    await _loadActivities();
  }

  void _confirmDelete(
    BuildContext context,
    String eventId,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa hoạt động này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final appState =
                  Provider.of<AppStateService>(context, listen: false);
              await appState.removeEvent(eventId);
              await _loadActivities();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa hoạt động')),
              );
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadActivities({String? filter}) async {
    final nextFilter = filter ?? _activeFilter;

    setState(() {
      _isLoading = true;
      _activeFilter = nextFilter;
    });

    final items = await ApiService.getAllActivities();

    if (!mounted) return;

    final loadedEvents = items.map((item) => Event.fromApi(item)).toList();

    setState(() {
      _events
        ..clear()
        ..addAll(loadedEvents);
      _isLoading = false;
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelection(String eventId) {
    setState(() {
      if (_selectedIds.contains(eventId)) {
        _selectedIds.remove(eventId);
      } else {
        _selectedIds.add(eventId);
      }
    });
  }

  List<Event> _filteredEvents() {
    switch (_activeFilter) {
      case 'Sắp tới':
        return _events
            .where((event) => event.isUpcoming && !event.isClosed)
            .toList();
      case 'Đã kết thúc':
        return _events
            .where((event) => event.hasEnded || event.isClosed)
            .toList();
      case 'Hiện tại':
      default:
        return _events
            .where((event) => !event.hasEnded && !event.isClosed)
            .toList();
    }
  }

  Future<void> _openQuickSelect() async {
    final items = await ApiService.getActivitySelect();
    if (!mounted) return;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có hoạt động để chọn nhanh')),
      );
      return;
    }

    final events = items.map((item) => Event.fromApi(item)).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          separatorBuilder: (_, __) => const Divider(height: 16),
          itemBuilder: (context, index) {
            final event = events[index];
            return ListTile(
              leading: const Icon(Icons.event),
              title: Text(event.title),
              subtitle: Text(event.code?.isNotEmpty == true
                  ? 'Mã: ${event.code}'
                  : _formatDateTime(event.dateTime)),
              onTap: () {
                Navigator.pop(context);
                _viewEventDetails(context, event);
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmBulkDelete() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa nhiều hoạt động'),
        content: Text(
          'Bạn có chắc muốn xóa ${_selectedIds.length} hoạt động đã chọn?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final appState = Provider.of<AppStateService>(context, listen: false);
    final result = await appState.deleteActivitiesBulk(_selectedIds.toList());
    if (!mounted) return;

    if (result['success'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Xóa thất bại'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() {
      _selectedIds.clear();
      _selectionMode = false;
    });
    await _loadActivities();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa hoạt động đã chọn')),
    );
  }

  Widget _buildEventImage(BuildContext context, Event event) {
    final source = _resolveEventImageSource(event.imageUrl);
    final placeholder = _buildImagePlaceholder();
    if (source == null) return placeholder;

    final imageWidget = source.isAsset
        ? Image.asset(
            source.value,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => placeholder,
          )
        : Image.network(
            source.value,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return placeholder;
            },
            errorBuilder: (_, __, ___) => placeholder,
          );

    return SizedBox(
      width: double.infinity,
      height: 180,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageWidget,
            // dark gradient overlay at bottom for title readability
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.55), Colors.transparent],
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            event.title ?? 'Hoạt động',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(event.dateTime),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(event),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder({bool isLoading = false}) {
    return Container(
      width: double.infinity,
      height: 170,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE2E8F0), Color(0xFFF1F5F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_outlined, size: 34, color: Colors.grey[500]),
                  const SizedBox(height: 6),
                  Text(
                    'Chưa có ảnh hoạt động',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
      ),
    );
  }

  _EventImageSource? _resolveEventImageSource(String? rawImageUrl) {
    if (rawImageUrl == null) return null;
    final trimmed = rawImageUrl.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('assets/')) {
      return _EventImageSource(trimmed, isAsset: true);
    }

    final isAbsolute =
        trimmed.startsWith('http://') || trimmed.startsWith('https://');
    final baseHost = ApiService.baseUrl.replaceFirst(RegExp(r'/v1/api/?$'), '');

    var resolved = trimmed;
    if (!isAbsolute) {
      if (trimmed.startsWith('/')) {
        resolved = '$baseHost$trimmed';
      } else if (trimmed.startsWith('uploads/')) {
        resolved = '$baseHost/$trimmed';
      } else {
        resolved = '$baseHost/uploads/$trimmed';
      }
    }

    resolved = _normalizeLocalhostForAndroid(resolved);
    return _EventImageSource(resolved, isAsset: false);
  }

  String _normalizeLocalhostForAndroid(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty || uri.host != 'localhost') {
      return url;
    }

    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    if (!isAndroid) return url;

    return uri.replace(host: '10.0.2.2').toString();
  }

  Widget _buildStatusChip(Event event) {
    final label = _statusLabel(event);
    final color = _statusColor(event);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _statusLabel(Event event) {
    if (event.isClosed || event.hasEnded) return 'Đã kết thúc';
    if (event.isOngoing) return 'Đang diễn ra';
    return 'Sắp tới';
  }

  Color _statusColor(Event event) {
    if (event.isClosed || event.hasEnded) return Colors.grey;
    if (event.isOngoing) return Colors.orange;
    return Colors.green;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return 'Không đặt';
    if (start != null && end == null) return _formatDateTime(start);
    if (start == null && end != null) return _formatDateTime(end);
    return '${_formatDateTime(start!)} - ${_formatDateTime(end!)}';
  }
}

class _EventImageSource {
  final String value;
  final bool isAsset;

  const _EventImageSource(this.value, {required this.isAsset});
}
