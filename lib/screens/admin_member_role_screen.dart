import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';
import '../models/user_item.dart';
import '../services/api_service.dart';

class AdminMemberRoleScreen extends StatefulWidget {
  const AdminMemberRoleScreen({super.key});

  @override
  State<AdminMemberRoleScreen> createState() => _AdminMemberRoleScreenState();
}

class _AdminMemberRoleScreenState extends State<AdminMemberRoleScreen> {
  static const String _allUnits = 'Tất cả chi đoàn';

  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String _selectedUnit = _allUnits;

  final Map<int, String> _unitNameById = {};
  final Map<int, String> _unitLevelById = {};
  List<String> _unitOptions = [_allUnits];

  List<UserItem> _members = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final units = await ApiService.getUnits();
    _unitNameById.clear();
    _unitLevelById.clear();

    for (final item in units) {
      if (item is! Map<String, dynamic>) continue;
      final id = item['id'];
      if (id is! int) continue;
      _unitNameById[id] = item['name']?.toString() ?? item['code']?.toString() ?? '';
      _unitLevelById[id] = item['level']?.toString() ?? '';
    }

    final unitNames = <String>{};
    for (final entry in _unitNameById.entries) {
      final level = _unitLevelById[entry.key]?.toLowerCase() ?? '';
      if (level == 'branch') {
        if (entry.value.trim().isNotEmpty) {
          unitNames.add(entry.value.trim());
        }
      }
    }

    final sortedUnits = unitNames.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final users = await ApiService.getUsers(role: 'member', limit: 500);
    _members = users
        .map((item) => UserItem.fromApi(item, unitMap: _unitNameById))
        .where((m) => m.role == 'member')
        .toList();

    if (!mounted) return;
    setState(() {
      _unitOptions = [_allUnits, ...sortedUnits];
      if (!_unitOptions.contains(_selectedUnit)) {
        _selectedUnit = _allUnits;
      }
      _isLoading = false;
    });
  }

  List<UserItem> get _filteredMembers {
    final query = _searchController.text.trim().toLowerCase();
    return _members.where((member) {
      final unitName = (member.unitName ?? '').trim();
      if (unitName.isEmpty) {
        return false;
      }
      final matchesUnit = _selectedUnit == _allUnits || unitName == _selectedUnit;
      final matchesQuery = query.isEmpty ||
          member.fullName.toLowerCase().contains(query) ||
          member.email.toLowerCase().contains(query) ||
          unitName.toLowerCase().contains(query);
      return matchesUnit && matchesQuery;
    }).toList();
  }

  Future<void> _updatePosition(UserItem member, String position) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final payload = position == _positions.first ? null : position;
    final result = await ApiService.updateUser(
      userId: member.id.toString(),
      position: payload,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result['success'] == false) {
      _showMessage(result['message']?.toString() ?? 'Cập nhật thất bại');
      return;
    }

    _showMessage('Đã cập nhật chức vụ', success: true);
    await _loadData();
  }

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.success : AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Quản lý đoàn viên'),
        backgroundColor: AppColors.surfaceColor,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  _buildFilters(),
                  const SizedBox(height: 16),
                  if (_filteredMembers.isEmpty)
                    _buildEmpty()
                  else
                    ..._buildGroupedSections(),
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
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Danh sách đoàn viên',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Chọn chi đoàn và gán chức vụ (Bí thư, Phó bí thư, Đoàn viên).',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên, email, chi đoàn',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
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
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: IconButton(
                onPressed: _showUnitSelector,
                icon: const Icon(Icons.filter_list, color: Colors.white),
                tooltip: 'Bộ lọc',
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showUnitSelector() {
    final unitOptions = _unitOptions.where((unit) => unit != _allUnits).toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Danh sách chi đoàn',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedUnit = _allUnits;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Hiển thị tất cả'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              SizedBox(
                height: 320,
                child: ListView.separated(
                  itemCount: unitOptions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final unit = unitOptions[index];
                    final selected = _selectedUnit == unit;
                    return ListTile(
                      title: Text(unit),
                      trailing: selected ? const Icon(Icons.check, color: AppColors.primary) : null,
                      onTap: () {
                        setState(() {
                          _selectedUnit = unit;
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

  Widget _buildMemberCard(UserItem member) {
    final unitName = member.unitName ?? '-';
    final position = _resolvePosition(member.position);
    return InkWell(
      onTap: () => _showMemberDetail(member),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildInitialAvatar(member.fullName),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            unitName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildPositionBadge(position),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showMemberDetail(member),
                  icon: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  tooltip: 'Xem chi tiết',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.badge_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: position,
                      icon: const SizedBox.shrink(),
                      items: _positions
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: _isSaving
                          ? null
                          : (value) {
                              if (value == null) return;
                              _updatePosition(member, value);
                            },
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

  void _showMemberDetail(UserItem member) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    gradient: LinearGradient(
                      colors: [Color(0xFF2747A8), Color(0xFF1F3D91)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 8,
                        left: 8,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                      const Positioned(
                        top: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            'Thông tin đoàn viên',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Transform.translate(
                          offset: const Offset(0, 36),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              _buildDetailAvatar(member),
                              Positioned(
                                right: 4,
                                bottom: 4,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    border: Border.all(color: Colors.white, width: 2),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    children: [
                      Text(
                        member.fullName,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        children: [
                          Text(
                            member.studentCode?.isNotEmpty == true ? member.studentCode! : 'Chưa có MSSV',
                            style: const TextStyle(
                              color: Color(0xFF3B82F6),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text('•', style: TextStyle(color: AppColors.textSecondary)),
                          Text(
                            member.status == 'active' ? 'Đang hoạt động' : member.displayStatus,
                            style: const TextStyle(
                              color: AppColors.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildDetailSectionTitle('THÔNG TIN CƠ BẢN'),
                      const SizedBox(height: 10),
                      _buildDetailRow(
                        icon: Icons.email_outlined,
                        iconColor: const Color(0xFF3B82F6),
                        label: 'Email',
                        value: member.email.isNotEmpty ? member.email : 'Chưa cập nhật',
                      ),
                      _buildDivider(),
                      _buildDetailRow(
                        icon: Icons.phone_outlined,
                        iconColor: const Color(0xFFF59E0B),
                        label: 'Số điện thoại',
                        value: member.phone.isNotEmpty ? member.phone : 'Chưa cập nhật',
                      ),
                      _buildDivider(),
                      _buildDetailRow(
                        icon: Icons.badge_outlined,
                        iconColor: const Color(0xFFA855F7),
                        label: 'Mã sinh viên',
                        value: member.studentCode?.isNotEmpty == true ? member.studentCode! : 'Chưa cập nhật',
                      ),
                      const SizedBox(height: 18),
                      _buildDetailSectionTitle('THÔNG TIN ĐOÀN'),
                      const SizedBox(height: 10),
                      _buildDetailRow(
                        icon: Icons.account_tree_outlined,
                        iconColor: const Color(0xFF3B82F6),
                        label: 'Chi đoàn',
                        value: member.unitName ?? 'Chưa có',
                      ),
                      _buildDivider(),
                      _buildDetailRow(
                        icon: Icons.workspace_premium_outlined,
                        iconColor: const Color(0xFFDC2626),
                        label: 'Chức vụ',
                        valueWidget: _buildPositionBadge(
                          member.position ?? 'Đoàn viên',
                          fontSize: 12,
                          horizontalPadding: 10,
                          verticalPadding: 5,
                        ),
                      ),
                      _buildDivider(),
                      _buildDetailRow(
                        icon: Icons.calendar_month_outlined,
                        iconColor: const Color(0xFF10B981),
                        label: 'Trạng thái',
                        value: member.displayStatus,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  // open the edit dialog in the next microtask to avoid
                                  // overlapping navigator operations that can cause
                                  // framework assertion errors about active dependents
                                  Future.microtask(() => _openEditMemberDialog(member));
                                },
                              icon: const Icon(Icons.edit, color: Colors.white),
                              label: const Text('Chỉnh sửa thông tin'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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

  Future<void> _openEditMemberDialog(UserItem member) async {
    final fullNameController = TextEditingController(text: member.fullName);
    final emailController = TextEditingController(text: member.email);
    final phoneController = TextEditingController(text: member.phone);
    final studentCodeController = TextEditingController(text: member.studentCode ?? '');

    final availableUnits = _unitNameById.entries
        .where((entry) => _unitLevelById[entry.key]?.toLowerCase() == 'branch')
        .toList()
      ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));

    int? selectedUnitId = member.unitId;
    if (selectedUnitId == null && member.unitName != null) {
      for (final entry in availableUnits) {
        if (entry.value.trim().toLowerCase() == member.unitName!.trim().toLowerCase()) {
          selectedUnitId = entry.key;
          break;
        }
      }
    }
    String selectedPosition = _resolvePosition(member.position);
    bool saving = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setStateDialog) {
          final avatarUrl = member.avatarUrl;
          final initial = member.fullName.isNotEmpty ? member.fullName.substring(0, 1).toUpperCase() : '?';
          void closeDialog([bool value = false]) {
            if (Navigator.of(dialogContext).canPop()) {
              Navigator.of(dialogContext).pop(value);
            }
          }
          
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            contentPadding: EdgeInsets.zero,
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with back and menu
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(onTap: () => closeDialog(false), child: const Icon(Icons.arrow_back, color: Colors.white)),
                        const Text('Chỉnh sửa thông tin', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                        const Icon(Icons.more_vert, color: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Avatar, name, subtitle
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E90FF),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF101215), width: 3),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: avatarUrl != null
                              ? Image.network(avatarUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800))))
                              : Center(child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800))),
                        ),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(color: const Color(0xFF10B981), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(member.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  Text(member.unitName ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                  
                  // Form fields
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Full name
                        TextField(
                          controller: fullNameController,
                          decoration: InputDecoration(
                            labelText: 'Họ và tên',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Email
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Phone and Student code side by side
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: 'Số điện thoại',
                                  prefixIcon: const Icon(Icons.phone),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: studentCodeController,
                                decoration: InputDecoration(
                                  labelText: 'Mã sinh viên',
                                  prefixIcon: const Icon(Icons.badge_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Unit selector
                        DropdownButtonFormField<int?>(
                          value: selectedUnitId,
                          icon: const Icon(Icons.expand_more),
                          decoration: InputDecoration(
                            labelText: 'Chi đoàn',
                            prefixIcon: const Icon(Icons.account_tree_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('Chưa chọn')),
                            ...availableUnits.map((entry) => DropdownMenuItem<int?>(value: entry.key, child: Text(entry.value))),
                          ],
                          onChanged: (value) => setStateDialog(() => selectedUnitId = value),
                        ),
                        const SizedBox(height: 12),
                        
                        // Position selector
                        DropdownButtonFormField<String>(
                          value: selectedPosition,
                          icon: const Icon(Icons.expand_more),
                          decoration: InputDecoration(
                            labelText: 'Chức vụ',
                            prefixIcon: const Icon(Icons.workspace_premium_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: _positions.map((item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
                          onChanged: (v) { if (v == null) return; setStateDialog(() => selectedPosition = v); },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: saving
                                ? null
                                : () async {
                                    setStateDialog(() => saving = true);
                                    try {
                                      final result = await ApiService.updateUser(
                                        userId: member.id.toString(),
                                        fullName: fullNameController.text.trim(),
                                        email: emailController.text.trim(),
                                        phone: phoneController.text.trim(),
                                        studentCode: studentCodeController.text.trim(),
                                        unitId: selectedUnitId,
                                        position: selectedPosition,
                                      );
                                      if (!mounted) return;
                                      if (result['success'] == false) {
                                        if (mounted) setStateDialog(() => saving = false);
                                        _showMessage(result['message']?.toString() ?? 'Cập nhật thất bại');
                                        return;
                                      }
                                      closeDialog(true);
                                    } catch (e) {
                                      if (mounted) {
                                        setStateDialog(() => saving = false);
                                        _showMessage('Lỗi: ${e.toString()}');
                                      }
                                    }
                                  },
                            child: Text(saving ? 'Đang lưu...' : 'Lưu thay đổi'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: saving ? null : () => closeDialog(false),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Hủy bỏ', style: TextStyle(color: AppColors.textSecondary)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );

    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    studentCodeController.dispose();

    if (result == true) {
      _showMessage('Đã cập nhật thông tin', success: true);
      await _loadData();
    }
  }

  Widget _buildDetailAvatar(UserItem member) {
    final avatarUrl = member.avatarUrl;
    final initial = member.fullName.isNotEmpty ? member.fullName.substring(0, 1).toUpperCase() : '?';

    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: const Color(0xFF1E90FF),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF101215), width: 4),
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl != null
          ? Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
    );
  }

  Widget _buildDetailSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF9A7B4F),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    String? value,
    Widget? valueWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                if (valueWidget != null)
                  valueWidget
                else
                  Text(
                    value ?? '',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(color: Color(0xFFE5E7EB), height: 1);
  }

  Widget _buildPositionBadge(
    String position, {
    double fontSize = 11,
    double horizontalPadding = 8,
    double verticalPadding = 4,
  }) {
    final normalized = position.trim().toLowerCase();
    final color = _positionColor(normalized);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Text(
        position,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _positionColor(String normalized) {
    if (normalized.contains('bí thư') && !normalized.contains('phó')) {
      return const Color(0xFFDC2626);
    }
    if (normalized.contains('phó bí thư')) {
      return const Color(0xFFF59E0B);
    }
    return const Color(0xFF2563EB);
  }

  Widget _buildInitialAvatar(String name) {
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    final bg = _pickPastelColor(initial);
    final fg = Colors.white;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(initial, style: TextStyle(color: fg, fontWeight: FontWeight.w800)),
    );
  }

  Color _pickPastelColor(String key) {
    const colors = [
      Color(0xFFDBEAFE), // blue
      Color(0xFFFEE2E2), // red/pink
      Color(0xFFFDE68A), // yellow
      Color(0xFFD1FAE5), // green
      Color(0xFFFCE7F3), // pink
      Color(0xFFE9D5FF), // purple
    ];
    final idx = key.codeUnitAt(0) % colors.length;
    return colors[idx];
  }

  List<Widget> _buildGroupedSections() {
    final grouped = <String, List<UserItem>>{};
    for (final member in _filteredMembers) {
      final unitName = (member.unitName ?? '').trim();
      if (unitName.isEmpty) {
        continue;
      }
      grouped.putIfAbsent(unitName, () => []).add(member);
    }

    final keys = grouped.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final widgets = <Widget>[];
    for (final key in keys) {
      final members = grouped[key]!..sort(
          (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
        );
      widgets.add(_buildClassHeader(key, members.length));
      widgets.add(const SizedBox(height: 8));
      widgets.addAll(members.map(_buildMemberCard));
      widgets.add(const SizedBox(height: 6));
    }

    return widgets;
  }

  Widget _buildClassHeader(String name, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          Text(
            '$count đoàn viên',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.group_off, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'Không có đoàn viên phù hợp',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _resolvePosition(String? raw) {
    if (raw == null || raw.trim().isEmpty) return _positions.first;
    final normalized = raw.trim().toLowerCase();
    if (normalized == 'đoàn viên' || normalized == 'doan vien' || normalized == 'ủy viên' || normalized == 'uy vien') {
      return _positions.first;
    }
    for (final item in _positions) {
      if (item.toLowerCase() == normalized) return item;
    }
    return _positions.first;
  }
}

const List<String> _positions = [
  'Đoàn viên',
  'Bí thư chi đoàn',
  'Phó bí thư chi đoàn',
];
