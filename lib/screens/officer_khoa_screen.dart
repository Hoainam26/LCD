import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';

class OfficerKhoaScreen extends StatefulWidget {
  const OfficerKhoaScreen({super.key});

  @override
  State<OfficerKhoaScreen> createState() => _OfficerKhoaScreenState();
}

class _OfficerKhoaScreenState extends State<OfficerKhoaScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _startYearController = TextEditingController();
  final TextEditingController _endYearController = TextEditingController();
  String _query = '';
  bool _isLoading = true;
  String? _error;
  List<_KhoaItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _startYearController.dispose();
    _endYearController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final units = await ApiService.getUnits();
      final users = await ApiService.getUsers(limit: 500);
      final items = _buildKhoaItems(units, users);
      setState(() {
        _items = items;
      });
    } catch (e) {
      setState(() {
          _error = 'Không tải được dữ liệu';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<_KhoaItem> _buildKhoaItems(List<dynamic> units, List<dynamic> users) {
    final years = <int>{};
    final items = <_KhoaItem>[];
    final knownYears = <int>{};

    for (final user in users) {
      final code = user['student_code']?.toString();
      final year = _yearFromStudentCode(code);
      if (year != null) {
        years.add(year);
      }
    }

    for (final unit in units) {
      final code = unit['code']?.toString() ?? '';
      final name = unit['name']?.toString() ?? '';
      final level = unit['level']?.toString() ?? '';
      final isKhoa = level == 'khoa' ||
          code.toUpperCase().startsWith('K') ||
          name.toLowerCase().contains('khóa');
      if (!isKhoa) continue;

      final year = _yearFromKhoaLabel(code, name);
      if (year != null) {
        knownYears.add(year);
      }

      items.add(
        _KhoaItem(
          id: unit['id'] as int?,
          code: code,
          name: name.isNotEmpty ? name : 'Khóa ${year ?? ''}',
          startYear: year ?? 0,
          endYear: year == null ? 0 : year + 4,
          createdAt: _parseDate(unit['createdAt']),
        ),
      );
    }

    if (years.isEmpty && items.isEmpty) {
      for (final unit in units) {
        final code = unit['code']?.toString() ?? '';
        final year = _yearFromUnitCode(code);
        if (year != null) {
          years.add(year);
        }
      }
    }

    for (final year in years) {
      if (knownYears.contains(year)) continue;
      items.add(
        _KhoaItem(
          id: null,
          code: 'K${year % 100}',
          name: 'Khóa $year',
          startYear: year,
          endYear: year + 4,
          createdAt: _findKhoaCreatedAt(units, year),
        ),
      );
    }

    items.sort((a, b) => a.startYear.compareTo(b.startYear));
    return items;
  }

  int? _yearFromStudentCode(String? code) {
    if (code == null || code.trim().length < 2) return null;
    final prefix = int.tryParse(code.trim().substring(0, 2));
    if (prefix == 16) return 2024;
    if (prefix == 17) return 2025;
    return null;
  }

  int? _yearFromUnitCode(String code) {
    final match = RegExp(r'(\d{2})').firstMatch(code);
    if (match == null) return null;
    final prefix = int.tryParse(match.group(1) ?? '');
    if (prefix == 16) return 2024;
    if (prefix == 17) return 2025;
    return null;
  }

  int? _yearFromKhoaLabel(String code, String name) {
    final yearMatch = RegExp(r'(20\d{2})').firstMatch(name);
    if (yearMatch != null) {
      return int.tryParse(yearMatch.group(1) ?? '');
    }
    if (code.toUpperCase().startsWith('K')) {
      final suffix = code.substring(1);
      final num = int.tryParse(suffix);
      if (num != null) {
        return 2000 + num;
      }
    }
    return null;
  }

  DateTime? _findKhoaCreatedAt(List<dynamic> units, int year) {
    final prefix = year == 2024 ? '16' : '17';
    DateTime? earliest;
    for (final unit in units) {
      final code = unit['code']?.toString() ?? '';
      if (!code.contains(prefix)) continue;
      final createdRaw = unit['createdAt']?.toString();
      final created = createdRaw == null ? null : DateTime.tryParse(createdRaw);
      if (created == null) continue;
      if (earliest == null || created.isBefore(earliest)) {
        earliest = created;
      }
    }
    return earliest;
  }

  List<_KhoaItem> get _filteredItems {
    if (_query.isEmpty) return _items;
    final needle = _query.toLowerCase();
    return _items.where((item) {
      return item.code.toLowerCase().contains(needle) ||
          item.name.toLowerCase().contains(needle);
    }).toList();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Khóa'),
        backgroundColor: AppColors.surfaceColor,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildToolbar(),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              _buildErrorCard(_error!)
            else if (_filteredItems.isEmpty)
              _buildEmptyCard('Không có khóa phù hợp')
            else ...[
              _buildTableHeader(),
              const SizedBox(height: 8),
              ..._filteredItems.map(_buildKhoaCard),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 4),
            color: Colors.black12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Danh sách Khóa',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tổng số: ${_items.length} khóa',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _query = value.trim();
              });
            },
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo mã hoặc tên khóa',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: _openCreateDialog,
          icon: const Icon(Icons.add),
          label: const Text('Thêm mới'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: const [
          SizedBox(width: 36, child: Text('STT', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Mã khóa', style: _headerStyle)),
          Expanded(flex: 3, child: Text('Tên khóa', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Năm bắt đầu', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Năm kết thúc', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Ngày tạo', style: _headerStyle)),
          SizedBox(width: 98, child: Text('Thao tác', style: _headerStyle)),
        ],
      ),
    );
  }

  Widget _buildKhoaCard(_KhoaItem item) {
    final index = _filteredItems.indexOf(item) + 1;
    final startYear = item.startYear == 0 ? '-' : item.startYear.toString();
    final endYear = item.endYear == 0 ? '-' : item.endYear.toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  index.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                flex: 2,
                child: _buildChip(
                  item.code,
                  const Color(0xFFE0ECFF),
                  AppColors.primary,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildInfoBlock(
                  'Năm bắt đầu',
                  startYear,
                ),
              ),
              Expanded(
                child: _buildInfoBlock(
                  'Năm kết thúc',
                  endYear,
                ),
              ),
              Expanded(
                child: _buildInfoBlock(
                  'Ngày tạo',
                  _formatDate(item.createdAt),
                ),
              ),
              _buildActionRow(item),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildChip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  Widget _buildActionRow(_KhoaItem item) {
    return Row(
      children: [
        _buildActionIcon(
          icon: Icons.visibility,
          bg: const Color(0xFFDBEAFE),
          fg: const Color(0xFF2563EB),
          onTap: () => _showDetails(item),
        ),
        const SizedBox(width: 6),
        _buildActionIcon(
          icon: Icons.edit,
          bg: const Color(0xFFFFEDD5),
          fg: const Color(0xFFEA580C),
          onTap: () => _openEditDialog(item),
        ),
        const SizedBox(width: 6),
        _buildActionIcon(
          icon: Icons.delete,
          bg: const Color(0xFFFEE2E2),
          fg: const Color(0xFFDC2626),
          onTap: () => _confirmDelete(item),
        ),
      ],
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: fg),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.danger)),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message, style: const TextStyle(color: Colors.grey)),
    );
  }

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label đang phát triển')),
    );
  }

  void _showDetails(_KhoaItem item) {
    showDialog(
      context: context,
      builder: (context) => _buildKhoaDetailDialog(item),
    );
  }

  Future<void> _openCreateDialog() async {
    _codeController.clear();
    _nameController.clear();
    _startYearController.clear();
    _endYearController.clear();
    await _openFormDialog(title: 'Thêm khóa mới');
  }

  Future<void> _openEditDialog(_KhoaItem item) async {
    _codeController.text = item.code;
    _nameController.text = item.name;
    _startYearController.text = item.startYear == 0 ? '' : '${item.startYear}';
    _endYearController.text = item.endYear == 0 ? '' : '${item.endYear}';
    await _openFormDialog(title: 'Chỉnh sửa khóa', item: item);
  }

  Future<void> _openFormDialog({
    required String title,
    _KhoaItem? item,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _buildKhoaFormDialog(title: title),
    );

    if (result != true) return;

    final code = _codeController.text.trim();
    final name = _nameController.text.trim();
    final startYear = int.tryParse(_startYearController.text.trim());
    final endYear = int.tryParse(_endYearController.text.trim());
    final resolvedName = startYear != null ? 'Khóa $startYear' : name;
    final resolvedCode = startYear != null ? 'K${startYear % 100}' : code;

    if (resolvedCode.isEmpty || resolvedName.isEmpty) {
      _showMessage('Vui lòng nhập đầy đủ mã và tên khóa.');
      return;
    }

    if (item == null) {
      await ApiService.createUnit(
        code: resolvedCode,
        name: resolvedName,
        level: 'khoa',
        description: endYear == null ? null : 'Kết thúc $endYear',
      );
    } else if (item.id != null) {
      await ApiService.updateUnit(
        id: item.id!,
        code: resolvedCode,
        name: resolvedName,
        level: 'khoa',
        description: endYear == null ? null : 'Kết thúc $endYear',
      );
    } else {
      await ApiService.createUnit(
        code: resolvedCode,
        name: resolvedName,
        level: 'khoa',
        description: endYear == null ? null : 'Kết thúc $endYear',
      );
    }

    await _loadData();
  }

  Future<void> _confirmDelete(_KhoaItem item) async {
    if (item.id == null) {
      _showMessage('Khóa này chưa được lưu trong hệ thống.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa khóa'),
        content: Text('Bạn chắc chắn muốn xóa ${item.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ApiService.deleteUnit(item.id!);
    await _loadData();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildKhoaDetailDialog(_KhoaItem item) {
    final startYear = item.startYear == 0 ? null : item.startYear;
    final endYear = item.endYear == 0 ? null : item.endYear;
    final duration = (startYear != null && endYear != null)
        ? endYear - startYear
        : null;
    final currentYear = DateTime.now().year;
    final isFinished = endYear != null && endYear <= currentYear;
    final statusLabel = isFinished ? 'Đã kết thúc' : 'Đang đào tạo';
    final statusColor = isFinished ? const Color(0xFFEF4444) : AppColors.success;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Chi tiết khóa học',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.confirmation_number,
                                  size: 14, color: Colors.white70),
                              const SizedBox(width: 6),
                              Text(
                                item.code,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.schedule,
                                  size: 14, color: Colors.white70),
                              const SizedBox(width: 6),
                              Text(
                                duration == null ? '-' : '$duration năm',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailCard(
                      title: 'Thông tin cơ bản',
                      items: [
                        _DetailRow('Mã khóa', item.code),
                        _DetailRow('Tên khóa', item.name),
                        _DetailRow(
                          'Năm bắt đầu',
                          startYear == null ? '-' : startYear.toString(),
                        ),
                        _DetailRow(
                          'Năm kết thúc',
                          endYear == null ? '-' : endYear.toString(),
                        ),
                        _DetailRow(
                          'Thời gian đào tạo',
                          duration == null ? '-' : '$duration năm',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailCard(
                      title: 'Thông tin hệ thống',
                      items: [
                        _DetailRow('ID', item.id?.toString() ?? '-'),
                        _DetailRow('Ngày tạo', _formatDate(item.createdAt)),
                        _DetailRow('Cập nhật', _formatDate(item.createdAt)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Timeline khóa học',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildTimelineCircle(
                          label: startYear?.toString() ?? '-',
                          color: const Color(0xFF2563EB),
                          footer: 'Bắt đầu',
                        ),
                        Expanded(
                          child: Container(
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF2563EB),
                                  Color(0xFFEF4444)
                                ],
                              ),
                            ),
                          ),
                        ),
                        _buildTimelineCircle(
                          label: endYear?.toString() ?? '-',
                          color: const Color(0xFFEF4444),
                          footer: 'Kết thúc',
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

  Widget _buildDetailCard({
    required String title,
    required List<_DetailRow> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          for (final row in items) ...[
            _buildDetailRow(row),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(_DetailRow row) {
    return Row(
      children: [
        Expanded(
          child: Text(
            row.label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ),
        Text(
          row.value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildTimelineCircle({
    required String label,
    required Color color,
    required String footer,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          footer,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildKhoaFormDialog({required String title}) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.86,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildFormField(
                  label: 'Mã khóa',
                  controller: _codeController,
                ),
                const SizedBox(height: 12),
                _buildFormField(
                  label: 'Tên khóa học',
                  controller: _nameController,
                ),
                const SizedBox(height: 12),
                _buildFormField(
                  label: 'Năm bắt đầu',
                  controller: _startYearController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _buildFormField(
                  label: 'Năm kết thúc',
                  controller: _endYearController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final code = _codeController.text.trim();
                        final name = _nameController.text.trim();
                        final start = _startYearController.text.trim();
                        final end = _endYearController.text.trim();
                        if (code.isEmpty || name.isEmpty || start.isEmpty || end.isEmpty) {
                          _showMessage('Vui lòng nhập đầy đủ thông tin bắt buộc.');
                          return;
                        }
                        Navigator.pop(context, true);
                      },
                      child: const Text('Cập nhật'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            children: const [
              TextSpan(text: ' *', style: TextStyle(color: AppColors.danger)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}

const TextStyle _headerStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w700,
  color: AppColors.textSecondary,
);

class _KhoaItem {
  final int? id;
  final String code;
  final String name;
  final int startYear;
  final int endYear;
  final DateTime? createdAt;

  _KhoaItem({
    required this.id,
    required this.code,
    required this.name,
    required this.startYear,
    required this.endYear,
    required this.createdAt,
  });
}

class _DetailRow {
  final String label;
  final String value;

  _DetailRow(this.label, this.value);
}
