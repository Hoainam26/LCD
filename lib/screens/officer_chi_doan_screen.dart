import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';

class OfficerChiDoanScreen extends StatefulWidget {
  const OfficerChiDoanScreen({
    super.key,
    this.readOnly = false,
    this.title = 'Quản lý Chi đoàn',
  });

  final bool readOnly;
  final String title;

  @override
  State<OfficerChiDoanScreen> createState() => _OfficerChiDoanScreenState();
}

class _OfficerChiDoanScreenState extends State<OfficerChiDoanScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _query = '';
  bool _isLoading = true;
  String? _error;
  List<_ChiDoanItem> _items = [];
  bool _isEditing = false;
  int? _defaultParentId;
  int? _selectedFacultyId;
  int? _formParentId;
  final Map<int, String> _facultyNameById = {};
  List<_FacultyOption> _facultyOptions = const [];

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
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final units = await ApiService.getUnits();
      _buildFacultyOptions(units);
      final users = await ApiService.getUsers(limit: 500);
      final items = _buildChiDoanItems(units, users);
      final computedDefault = _defaultParentId ?? _normalizeFacultyId(_findDefaultParentId(units));
      final computedSelected = _normalizeFacultyId(_selectedFacultyId) ?? computedDefault;
      final computedFormParent = _normalizeFacultyId(_formParentId) ?? computedDefault;
      setState(() {
        _facultyOptions = _facultyOptions;
        _items = items;
        _defaultParentId = computedDefault;
        _selectedFacultyId = computedSelected;
        _formParentId = computedFormParent;
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

  List<_ChiDoanItem> _buildChiDoanItems(
    List<dynamic> units,
    List<dynamic> users,
  ) {
    final items = <_ChiDoanItem>[];
    final userByUnit = <int, List<Map<String, dynamic>>>{};

    for (final user in users) {
      final unitId = user['unit_id'];
      if (unitId is! int) continue;
      userByUnit.putIfAbsent(unitId, () => []).add(
            Map<String, dynamic>.from(user as Map),
          );
    }

    for (final unit in units) {
      final unitId = unit['id'];
      if (unitId is! int) continue;
      final code = unit['code']?.toString() ?? '';
      final name = unit['name']?.toString() ?? code;
      final level = unit['level']?.toString() ?? '';
      final isChiDoan = level == 'branch' || code.toUpperCase().startsWith('CNTT');
      if (!isChiDoan) continue;
      if (code.isEmpty && name.isEmpty) continue;

      final members = userByUnit[unitId] ?? [];
      final secretary = _findSecretary(members);
      final createdAt = _parseDate(unit['createdAt']);
      final description = unit['description']?.toString();
      final parentId = unit['parent_id'] is int ? unit['parent_id'] as int : null;
      final parentName = parentId != null ? _facultyNameById[parentId] : null;

      items.add(
        _ChiDoanItem(
          id: unitId,
          code: code,
          name: name,
          secretary: secretary,
          memberCount: members.length,
          isActive: members.isNotEmpty,
          createdAt: createdAt,
          parentId: parentId,
          parentName: parentName,
          description: description,
        ),
      );
    }

    items.sort((a, b) => a.code.compareTo(b.code));
    return items;
  }

  String _findSecretary(List<Map<String, dynamic>> members) {
    for (final member in members) {
      final position = member['position']?.toString().toLowerCase() ?? '';
      if (position.contains('bí thư') || position.contains('bi thu')) {
        return member['full_name']?.toString() ?? 'Chưa có';
      }
    }
    return 'Chưa có';
  }

  int? _findDefaultParentId(List<dynamic> units) {
    for (final unit in units) {
      final parentId = unit['parent_id'];
      if (parentId is int) {
        return parentId;
      }
    }
    return null;
  }

  int? _normalizeFacultyId(int? value) {
    if (value == null) return null;
    return _facultyNameById.containsKey(value) ? value : null;
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  List<_ChiDoanItem> get _filteredItems {
    final filteredByFaculty = _selectedFacultyId == null
        ? _items
        : _items.where((item) => item.parentId == _selectedFacultyId).toList();
    if (_query.isEmpty) return filteredByFaculty;
    final needle = _query.toLowerCase();
    return filteredByFaculty.where((item) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
              _buildEmptyCard('Không có chi đoàn phù hợp')
            else ...[
              ..._filteredItems.map(_buildChiDoanCard),
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
            'Danh sách Chi đoàn',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tổng số: ${_filteredItems.length} chi đoàn',
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
              hintText: 'Tìm kiếm theo mã hoặc tên chi đoàn',
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
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFacultySelector,
            tooltip: 'Chọn chi đoàn',
          ),
        ),
      ],
    );
  }

  void _showFacultySelector() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        final options = _facultyOptions.where((o) => o.id != null).toList();
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Expanded(child: Text('Chọn khoa/chi đoàn', style: TextStyle(fontWeight: FontWeight.w700))),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedFacultyId = null;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Bỏ chọn'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, idx) {
                    final opt = options[idx];
                    final selected = _selectedFacultyId == opt.id;
                    return ListTile(
                      title: Text(opt.name),
                      trailing: selected ? const Icon(Icons.check, color: AppColors.primary) : null,
                      onTap: () {
                        setState(() {
                          _selectedFacultyId = opt.id;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFacultyDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _normalizeFacultyId(_selectedFacultyId),
          hint: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_list, color: AppColors.primary),
            ],
          ),
          // removed default dropdown arrow to hide the small triangle indicator
          items: _facultyOptions
              .map(
                (option) => DropdownMenuItem<int?>(
                  value: option.id,
                  child: Text(option.name),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedFacultyId = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return const SizedBox.shrink();
        }

        final cells = <Widget>[
          const SizedBox(width: 36, child: Text('STT', style: _headerStyle)),
          const Expanded(flex: 2, child: Text('Mã chi đoàn', style: _headerStyle)),
          const Expanded(flex: 3, child: Text('Tên chi đoàn', style: _headerStyle)),
          const Expanded(flex: 2, child: Text('Khoa', style: _headerStyle)),
          const Expanded(flex: 2, child: Text('Bí thư', style: _headerStyle)),
          const Expanded(flex: 2, child: Text('Số đoàn viên', style: _headerStyle)),
          const Expanded(flex: 2, child: Text('Trạng thái', style: _headerStyle)),
        ];
        if (!widget.readOnly) {
          cells.add(
            const SizedBox(width: 98, child: Text('Thao tác', style: _headerStyle)),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Row(children: cells),
        );
      },
    );
  }

  Widget _buildChiDoanCard(_ChiDoanItem item) {
    final statusColor = item.isActive ? AppColors.success : AppColors.danger;
    final statusText = item.isActive ? 'Đang hoạt động' : 'Ngừng hoạt động';
    final index = _filteredItems.indexOf(item) + 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: Column(
        children: [
          // top row: index + status badge
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(_formatDate(item.createdAt), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // middle info row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Bí thư: ${item.secretary}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.group, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text('${item.memberCount} thành viên', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(color: AppColors.borderColor, height: 1),

          // footer actions
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _showDetails(item),
                    icon: const Icon(Icons.remove_red_eye_outlined, color: Colors.white, size: 16),
                    label: const Text('Chi tiết', style: TextStyle(color: Colors.white)),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF0B63D6),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _openEditDialog(item),
                  icon: const Icon(Icons.edit, color: AppColors.primary, size: 16),
                  label: const Text('Chỉnh sửa', style: TextStyle(color: AppColors.primary)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.borderColor),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.transparent,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECEC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    onPressed: () => _confirmDelete(item),
                    icon: const Icon(Icons.delete, color: Color(0xFFDC2626)),
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

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
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

  Widget _buildActionRow(_ChiDoanItem item) {
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

  void _showDetails(_ChiDoanItem item) {
    showDialog(
      context: context,
      builder: (context) => _buildChiDoanDetailDialog(item),
    );
  }

  Future<void> _openCreateDialog() async {
    _codeController.clear();
    _nameController.clear();
    _descController.clear();
    _formParentId = _selectedFacultyId ?? _defaultParentId;
    _isEditing = false;
    await _openFormDialog(title: 'Thêm chi đoàn mới');
  }

  Future<void> _openEditDialog(_ChiDoanItem item) async {
    _codeController.text = item.code;
    _nameController.text = item.name;
    _descController.text = item.description ?? '';
    _formParentId = item.parentId ?? _selectedFacultyId ?? _defaultParentId;
    _isEditing = true;
    await _openFormDialog(title: 'Chỉnh sửa chi đoàn', item: item);
  }

  Future<void> _openFormDialog({
    required String title,
    _ChiDoanItem? item,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _buildChiDoanFormDialog(title: title),
    );

    if (result != true) return;

    final code = _codeController.text.trim();
    final name = _nameController.text.trim();
    if (code.isEmpty || name.isEmpty) {
      _showMessage('Vui lòng nhập đầy đủ mã và tên chi đoàn.');
      return;
    }

    final description = _descController.text.trim();

    if (item == null) {
      await ApiService.createUnit(
        code: code,
        name: name,
        level: 'branch',
        parentId: _formParentId ?? _defaultParentId,
        description: description.isEmpty ? null : description,
      );
    } else {
      await ApiService.updateUnit(
        id: item.id,
        code: code,
        name: name,
        level: 'branch',
        parentId: _formParentId ?? item.parentId ?? _defaultParentId,
        description: description.isEmpty ? null : description,
      );
    }

    await _loadData();
  }

  Future<void> _confirmDelete(_ChiDoanItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa chi đoàn'),
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
    await ApiService.deleteUnit(item.id);
    await _loadData();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildChiDoanDetailDialog(_ChiDoanItem item) {
    final statusLabel = item.isActive ? 'Đang hoạt động' : 'Ngừng hoạt động';
    final statusColor = item.isActive ? AppColors.success : AppColors.danger;
    final description = item.description?.trim().isNotEmpty == true
        ? item.description!.trim()
        : 'Chưa có mô tả';

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
                      'Chi tiết chi đoàn',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
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
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildChip(
                          item.code,
                          Colors.white.withOpacity(0.18),
                          Colors.white,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people, size: 14, color: Colors.white70),
                            const SizedBox(width: 6),
                            Text(
                              '${item.memberCount} đoàn viên',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailCard(
                title: 'Thông tin chi tiết',
                items: [
                  _DetailRow('Mã chi đoàn', item.code),
                  _DetailRow('Tên chi đoàn', item.name),
                  _DetailRow('Bí thư', item.secretary),
                  _DetailRow('Số đoàn viên', '${item.memberCount} đoàn viên'),
                  _DetailRow('Trạng thái', statusLabel),
                  _DetailRow('Mô tả', description),
                  _DetailRow('Ngày tạo', _formatDate(item.createdAt)),
                ],
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

  Widget _buildChiDoanFormDialog({required String title}) {
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
                  label: 'Mã chi đoàn',
                  controller: _codeController,
                  readOnly: _isEditing,
                ),
                const SizedBox(height: 12),
                _buildFormField(
                  label: 'Tên chi đoàn',
                  controller: _nameController,
                  readOnly: _isEditing,
                ),
                const SizedBox(height: 12),
                _buildFacultyFormField(),
                const SizedBox(height: 12),
                _buildFormField(
                  label: 'Mô tả',
                  controller: _descController,
                  maxLines: 3,
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
                        if (code.isEmpty || name.isEmpty) {
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
    int maxLines = 1,
    bool readOnly = false,
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
            children: label == 'Mô tả'
                ? const []
                : const [
                    TextSpan(
                        text: ' *',
                        style: TextStyle(color: AppColors.danger)),
                  ],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
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

  Widget _buildFacultyFormField() {
    final selectedValue = _normalizeFacultyId(_formParentId ?? _defaultParentId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Khoa',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<int?>(
          value: selectedValue,
          icon: const SizedBox.shrink(),
          items: _facultyOptions
              .where((option) => option.id != null)
              .map(
                (option) => DropdownMenuItem<int?>(
                  value: option.id,
                  child: Text(option.name),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _formParentId = value;
            });
          },
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

  void _buildFacultyOptions(List<dynamic> units) {
    _facultyNameById.clear();
    final options = <_FacultyOption>[const _FacultyOption(null, 'Tất cả khoa')];

    for (final unit in units) {
      if (unit is! Map<String, dynamic>) continue;
      final id = unit['id'];
      if (id is! int) continue;
      final level = (unit['level']?.toString() ?? '').toLowerCase();
      if (level != 'faculty' && level != 'khoa') continue;
      final name = unit['name']?.toString().trim();
      if (name == null || name.isEmpty) continue;
      _facultyNameById[id] = name;
    }

    final sorted = _facultyNameById.entries.toList()
      ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));

    for (final entry in sorted) {
      options.add(_FacultyOption(entry.key, entry.value));
    }

    // If there's a CNTT faculty, prefer it as default parent for new chi đoàn
    int? cnttId;
    for (final entry in sorted) {
      final name = entry.value.toLowerCase();
      if (name.contains('cntt') || name.contains('khoa cntt')) {
        cnttId = entry.key;
        break;
      }
    }
    if (cnttId != null) {
      _defaultParentId = cnttId;
    }

    _facultyOptions = options;
  }
}

const TextStyle _headerStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w700,
  color: AppColors.textSecondary,
);

class _ChiDoanItem {
  final int id;
  final String code;
  final String name;
  final String secretary;
  final int memberCount;
  final bool isActive;
  final DateTime? createdAt;
  final int? parentId;
  final String? parentName;
  final String? description;

  _ChiDoanItem({
    required this.id,
    required this.code,
    required this.name,
    required this.secretary,
    required this.memberCount,
    required this.isActive,
    required this.createdAt,
    required this.parentId,
    required this.parentName,
    required this.description,
  });
}

class _FacultyOption {
  final int? id;
  final String name;

  const _FacultyOption(this.id, this.name);
}

class _DetailRow {
  final String label;
  final String value;

  _DetailRow(this.label, this.value);
}
