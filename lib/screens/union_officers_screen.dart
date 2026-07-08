import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../models/user_item.dart';
import '../services/app_state_service.dart';
import '../services/api_service.dart';
import 'union_officer_detail_screen.dart';

class UnionOfficersScreen extends StatefulWidget {
  const UnionOfficersScreen({super.key});

  @override
  State<UnionOfficersScreen> createState() => _UnionOfficersScreenState();
}

class _UnionOfficersScreenState extends State<UnionOfficersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedUnit = 'Tất cả';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<AppStateService>(context, listen: false).refreshOfficers();
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
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Consumer<AppStateService>(
          builder: (context, appState, _) {
            final boardMembers = _buildBoardMembers(appState.officers);
            final chairman = boardMembers.isNotEmpty ? boardMembers.first : null;
            final viceMembers = boardMembers.length > 1
                ? boardMembers.sublist(1, boardMembers.length.clamp(1, 4))
                : <_BoardMember>[];
            final committeeMembers = boardMembers.length > 4
                ? boardMembers.sublist(4)
                : <_BoardMember>[];

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'BAN CHẤP HÀNH LIÊN CHI ĐOÀN KHOA CÔNG NGHỆ THÔNG TIN',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 36,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (chairman != null)
                    _buildBoardMemberCard(chairman, size: 90),
                  const SizedBox(height: 26),
                  _buildBoardGrid(viceMembers, size: 72),
                  const SizedBox(height: 20),
                  _buildBoardGrid(committeeMembers, size: 72),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<_BoardMember> _buildBoardMembers(List<UserItem> officers) {
    const order = [
      _BoardOrder(name: 'Lê Văn Phong', role: 'Bí thư'),
      _BoardOrder(name: 'Lê Tuấn Anh', role: 'Phó bí thư'),
      _BoardOrder(name: 'Nguyễn Thái Khánh', role: 'Phó bí thư'),
      _BoardOrder(name: 'Trần Thị Thanh Nhàn', role: 'Phó bí thư'),
      _BoardOrder(name: 'Nguyễn Thị Phương', role: 'Ủy viên'),
      _BoardOrder(name: 'Lê Thị Vân Anh', role: 'Ủy viên'),
      _BoardOrder(name: 'Nguyễn Thị Kim Hoa', role: 'Ủy viên'),
    ];

    // Default local avatar files to use when the API doesn't provide one.
    const defaultAvatars = [
      'uploads/avatars/id-18.JPG',
      'uploads/avatars/id-19.JPG',
      'uploads/avatars/id-20.JPG',
      'uploads/avatars/id-21.JPG',
      'uploads/avatars/id-22.jpg',
      'uploads/avatars/id-23.jpg',
      'uploads/avatars/id-24.jpg',
    ];

    const fallbackContacts = {
      'Lê Văn Phong': ('phong.lv@hcmut.edu.vn', '090 123 4567'),
      'Lê Tuấn Anh': ('anh.lt@hcmut.edu.vn', '090 234 5678'),
      'Nguyễn Thái Khánh': ('khanh.nt@hcmut.edu.vn', '090 345 6789'),
      'Trần Thị Thanh Nhàn': ('nhan.ttt@hcmut.edu.vn', '090 456 7890'),
      'Nguyễn Thị Phương': ('phuong.nt@hcmut.edu.vn', '090 567 8901'),
      'Lê Thị Vân Anh': ('anh.ltv@hcmut.edu.vn', '090 678 9012'),
      'Nguyễn Thị Kim Hoa': ('hoa.ntk@hcmut.edu.vn', '090 789 0123'),
    };

    return order.asMap().entries.map((e) {
      final idx = e.key;
      final entry = e.value;
      final user = _findOfficerByName(officers, entry.name);
      final contact = fallbackContacts[entry.name];
      final avatar = user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
          ? user.avatarUrl
          : (idx < defaultAvatars.length ? defaultAvatars[idx] : null);

      return _BoardMember(
        name: entry.name,
        role: entry.role,
        avatarUrl: avatar,
        slogan: _sloganFor(entry.name, entry.role),
        officer: user,
        fallbackEmail: contact?.$1,
        fallbackPhone: contact?.$2,
      );
    }).toList();
  }

  String _sloganFor(String name, String role) {
    const slogans = {
      'Lê Văn Phong': 'Dẫn dắt bằng trách nhiệm, hành động bằng sự tử tế.',
      'Lê Tuấn Anh': 'Làm việc kỷ luật, hỗ trợ hết mình.',
      'Nguyễn Thái Khánh': 'Lắng nghe nhiều hơn, hoàn thiện mỗi ngày.',
      'Trần Thị Thanh Nhàn': 'Kiên trì, chỉn chu và luôn giữ tinh thần tích cực.',
      'Nguyễn Thị Phương': 'Kết nối đoàn viên bằng tinh thần chủ động.',
      'Lê Thị Vân Anh': 'Tận tâm từ những điều nhỏ nhất.',
      'Nguyễn Thị Kim Hoa': 'Lan tỏa năng lượng tốt, làm việc hiệu quả.',
    };

    return slogans[name] ?? 'Gắn kết đoàn viên, phụng sự tập thể.';
  }

  UserItem? _findOfficerByName(List<UserItem> officers, String name) {
    final target = _normalizeName(name);
    for (final officer in officers) {
      final candidate = _normalizeName(officer.fullName);
      if (candidate == target) return officer;
    }
    for (final officer in officers) {
      final candidate = _normalizeName(officer.fullName);
      if (candidate.contains(target) || target.contains(candidate)) {
        return officer;
      }
    }
    return null;
  }

  String _normalizeName(String value) {
    final cleaned = value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return _stripDiacritics(cleaned);
  }

  String _stripDiacritics(String value) {
    var normalized = value;
    normalized = normalized.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
    normalized = normalized.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
    normalized = normalized.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
    normalized = normalized.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
    normalized = normalized.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
    normalized = normalized.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
    normalized = normalized.replaceAll(RegExp(r'đ'), 'd');
    return normalized;
  }

  Widget _buildBoardGrid(List<_BoardMember> members, {double size = 72}) {
    if (members.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 3;
        const spacing = 16.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                crossAxisCount;
        final itemHeight = size + 62;
        final ratio = itemWidth / itemHeight;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: ratio,
          ),
          itemCount: members.length,
          itemBuilder: (context, index) =>
              _buildBoardMemberCard(members[index], size: size),
        );
      },
    );
  }

  Widget _buildBoardMemberCard(_BoardMember member, {double size = 72}) {
    final avatar = ApiService.resolveAvatarUrl(member.avatarUrl) ?? '';
    final hasAvatar = avatar.isNotEmpty;
    Widget image;
    if (hasAvatar) {
      final isNetwork = avatar.startsWith('http');
      image = isNetwork
          ? Image.network(
              avatar,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildBoardAvatarFallback(member),
            )
          : Image.asset(
              avatar,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildBoardAvatarFallback(member),
            );
    } else {
      image = _buildBoardAvatarFallback(member);
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UnionOfficerDetailScreen(
              officer: member.officer,
              fallbackName: member.name,
              fallbackRole: member.role,
              fallbackSlogan: member.slogan,
              fallbackAvatarUrl: member.avatarUrl,
              fallbackEmail: member.fallbackEmail,
              fallbackPhone: member.fallbackPhone,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(child: image),
          ),
          const SizedBox(height: 8),
          Text(
            member.role,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            member.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardAvatarFallback(_BoardMember member) {
    final initial = member.name.isNotEmpty ? member.name.substring(0, 1) : '?';
    return Container(
      color: const Color(0xFFEFF3F8),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  List<String> _buildUnitList(List<UserItem> officers) {
    final units = officers
        .map((e) => _unitName(e))
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    units.sort();
    return ['Tất cả', ...units];
  }

  List<UserItem> _filterOfficers(
    List<UserItem> officers,
    String selectedUnit,
  ) {
    return officers.where((officer) {
      final unitName = _unitName(officer);
      final matchesUnit =
          selectedUnit == 'Tất cả' || unitName == selectedUnit;
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          officer.fullName.toLowerCase().contains(query) ||
          officer.email.toLowerCase().contains(query) ||
          officer.phone.contains(query) ||
          unitName.toLowerCase().contains(query) ||
          officer.id.toString().contains(query);
      return matchesUnit && matchesSearch;
    }).toList();
  }

  String _unitName(UserItem officer) {
    final name = officer.unitName ?? '';
    return name.isEmpty ? 'Chưa phân công' : name;
  }

  Widget _buildOfficerCard(UserItem officer) {
    final roleColor = _getRoleColor(officer.role);
    final unitName = _unitName(officer);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UnionOfficerDetailScreen(
                  officer: officer,
                  fallbackName: officer.fullName,
                  fallbackRole: _roleLabel(officer.role),
                  fallbackSlogan: _sloganFor(officer.fullName, officer.position ?? officer.role),
                  fallbackAvatarUrl: officer.avatarUrl,
                  fallbackEmail: officer.email,
                  fallbackPhone: officer.phone,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: roleColor,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: _buildAvatar(officer),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: roleColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          _getRoleIcon(officer.role),
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        officer.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _roleLabel(officer.role),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: roleColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.school,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              unitName,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.badge,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'ID: ${officer.id}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(UserItem officer) {
    final avatar = ApiService.resolveAvatarUrl(officer.avatarUrl);
    if (avatar != null && avatar.isNotEmpty) {
      final isNetwork = avatar.startsWith('http');
      final image = isNetwork
          ? Image.network(
              avatar,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildAvatarFallback(officer),
            )
          : Image.asset(
              avatar,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildAvatarFallback(officer),
            );
      return image;
    }

    return _buildAvatarFallback(officer);
  }

  Widget _buildAvatarFallback(UserItem officer) {
    final initial = officer.fullName.isNotEmpty
      ? officer.fullName.substring(0, 1)
      : '?';
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return const Color(0xFFB45309);
      case 'staff':
        return const Color(0xFF2563EB);
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.workspace_premium;
      case 'staff':
        return Icons.star;
      default:
        return Icons.person;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Quản trị';
      case 'staff':
        return 'Cán bộ';
      default:
        return 'Đoàn viên';
    }
  }

  void _showBoardMemberDetail(_BoardMember member) {
    final officer = member.officer ?? UserItem(
      id: 0,
      fullName: member.name,
      email: '',
      phone: '',
      role: 'staff',
      status: 'active',
      position: member.role,
      avatarUrl: member.avatarUrl,
    );
    final roleColor = _getRoleColor(officer.role);
    final unitName = _unitName(officer);

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
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: roleColor, width: 3),
              ),
              child: ClipOval(child: _buildAvatar(officer)),
            ),
            const SizedBox(height: 16),
            Text(
              officer.fullName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _roleLabel(officer.role),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: roleColor,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDDE5FF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Slogan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    member.slogan,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoRow(Icons.school, 'Đơn vị', unitName),
            _buildInfoRow(Icons.badge, 'ID', officer.id.toString()),
            _buildInfoRow(Icons.email, 'Email', _valueOrDash(officer.email)),
            _buildInfoRow(Icons.phone, 'SĐT', _valueOrDash(officer.phone)),
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
                      side: const BorderSide(color: Color(0xFF1E3A8A)),
                      foregroundColor: const Color(0xFF1E3A8A),
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

  void _showOfficerDetail(UserItem officer) {
    _showBoardMemberDetail(
      _BoardMember(
        name: officer.fullName,
        role: _roleLabel(officer.role),
        avatarUrl: officer.avatarUrl,
        slogan: _sloganFor(officer.fullName, officer.position ?? officer.role),
        officer: officer,
        fallbackEmail: officer.email,
        fallbackPhone: officer.phone,
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
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
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

  String _valueOrDash(String value) {
    return value.isEmpty ? '-' : value;
  }
}

class _BoardMember {
  final String name;
  final String role;
  final String? avatarUrl;
  final String slogan;
  final UserItem? officer;
  final String? fallbackEmail;
  final String? fallbackPhone;

  const _BoardMember({
    required this.name,
    required this.role,
    required this.avatarUrl,
    required this.slogan,
    required this.officer,
    required this.fallbackEmail,
    required this.fallbackPhone,
  });
}

class _BoardOrder {
  final String name;
  final String role;

  const _BoardOrder({
    required this.name,
    required this.role,
  });
}
