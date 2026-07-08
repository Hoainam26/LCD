import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../models/event_model.dart';
import '../services/app_state_service.dart';

class CreateEventDialog extends StatefulWidget {
  final Event? initialEvent;

  const CreateEventDialog({super.key, this.initialEvent});

  @override
  State<CreateEventDialog> createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends State<CreateEventDialog> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  bool _isSubmitting = false;
  bool _isRequired = false;

  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  late DateTime selectedEndDate;
  late TimeOfDay selectedEndTime;

  late DateTime selectedRegisterStartDate;
  late TimeOfDay selectedRegisterStartTime;
  late DateTime selectedRegisterEndDate;
  late TimeOfDay selectedRegisterEndTime;
  XFile? _pickedImage;

  bool get _isEditing => widget.initialEvent != null;

  @override
  void initState() {
    super.initState();

    // Use one consistent current-time baseline to avoid conflicting default ranges.
    final now = DateTime.now();
    final registerStart = now;
    final registerEnd = now.add(const Duration(hours: 1));
    final activityStart = now.add(const Duration(hours: 2));
    final activityEnd = now.add(const Duration(hours: 4));

    selectedRegisterStartDate = registerStart;
    selectedRegisterStartTime = TimeOfDay.fromDateTime(registerStart);
    selectedRegisterEndDate = registerEnd;
    selectedRegisterEndTime = TimeOfDay.fromDateTime(registerEnd);
    selectedDate = activityStart;
    selectedTime = TimeOfDay.fromDateTime(activityStart);
    selectedEndDate = activityEnd;
    selectedEndTime = TimeOfDay.fromDateTime(activityEnd);

    final initial = widget.initialEvent;
    if (initial != null) {
      titleController.text = initial.title;
      descriptionController.text = initial.description;
      locationController.text = initial.location;
      _isRequired = initial.isRequired;
      selectedDate = initial.dateTime;
      selectedTime = TimeOfDay.fromDateTime(initial.dateTime);
      final endDateTime =
          initial.endDateTime ?? initial.dateTime.add(const Duration(hours: 2));
      selectedEndDate = endDateTime;
      selectedEndTime = TimeOfDay.fromDateTime(endDateTime);
      final initialRegisterStart =
          initial.registerStartTime ?? initial.dateTime;
      selectedRegisterStartDate = initialRegisterStart;
      selectedRegisterStartTime = TimeOfDay.fromDateTime(initialRegisterStart);
      final initialRegisterEnd = initial.registerEndTime ?? initial.dateTime;
      selectedRegisterEndDate = initialRegisterEnd;
      selectedRegisterEndTime = TimeOfDay.fromDateTime(initialRegisterEnd);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.primaryDark,
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Text(
          _isEditing ? 'Cập nhật hoạt động' : 'Tạo hoạt động mới',
          style: GoogleFonts.manrope(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            color: AppColors.primaryDark,
            onPressed: () => Navigator.pop(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.borderColor),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFAF8FF), Color(0xFFFDFEFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildMobileSectionTitle(
                        'Thông tin cơ bản', AppColors.primaryDark),
                    const SizedBox(height: 14),
                    _buildUploadCard(),
                    const SizedBox(height: 16),
                    _buildLabel('Tên hoạt động'),
                    const SizedBox(height: 8),
                    _buildMobileTextField(
                      controller: titleController,
                      hint: 'Ví dụ: Hội trại truyền thông 2026',
                      icon: Icons.title_rounded,
                    ),
                    const SizedBox(height: 14),
                    _buildLabel('Địa điểm tổ chức'),
                    const SizedBox(height: 8),
                    _buildMobileTextField(
                      controller: locationController,
                      hint: 'Ví dụ: Hội trường A, Tầng 3',
                      icon: Icons.my_location_outlined,
                    ),
                    const SizedBox(height: 14),
                    _buildLabel('Mô tả chi tiết'),
                    const SizedBox(height: 8),
                    _buildMobileTextField(
                      controller: descriptionController,
                      hint:
                          'Nhập mục đích, nội dung và các thông tin quan trọng khác của hoạt động...',
                      icon: Icons.description_outlined,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 22),
                    _buildMobileSectionTitle(
                        'Thiết lập thời gian', AppColors.primaryDark),
                    const SizedBox(height: 14),
                    _buildScheduleCard(),
                    const SizedBox(height: 12),
                    _buildEventDateCard(),
                    const SizedBox(height: 22),
                    _buildMobileSectionTitle(
                        'Tính năng nâng cao', AppColors.primaryDark),
                    const SizedBox(height: 14),
                    _buildAdvancedCard(),
                    const SizedBox(height: 20),
                    _buildActionRow(),
                    const SizedBox(height: 12),
                    _buildPrimaryAction(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSectionTitle(String title, Color accentColor) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Row(
      children: [
        Icon(Icons.label_outline,
            size: 18, color: AppColors.textSecondary.withOpacity(0.7)),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.manrope(
        fontSize: 14,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.manrope(
          fontSize: 14,
          color: AppColors.textSecondary.withOpacity(0.8),
        ),
        prefixIcon: Icon(icon, color: AppColors.primaryDark),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.primaryDark, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildUploadCard() {
    final pickedImage = _pickedImage;
    final existingImageUrl = widget.initialEvent?.imageUrl;
    final hasExistingImage =
        existingImageUrl != null && existingImageUrl.trim().isNotEmpty;

    Widget preview;
    if (pickedImage != null) {
      preview = kIsWeb
          ? Image.network(pickedImage.path, fit: BoxFit.cover)
          : Image.file(File(pickedImage.path), fit: BoxFit.cover);
    } else if (hasExistingImage) {
      preview = Image.network(
        existingImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildUploadPlaceholder(),
      );
    } else {
      preview = _buildUploadPlaceholder();
    }

    return Container(
      height: 206,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: const Color(0xFFCBD5E1),
            width: 1.2,
            style: BorderStyle.solid),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned.fill(child: preview),
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFCBD5E1),
                      width: 1.4,
                      style: BorderStyle.solid,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_photo_alternate_outlined,
                              size: 30, color: AppColors.primaryDark),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tải lên ảnh bìa (16:9)',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Dung lượng tối đa 5MB',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (pickedImage != null || hasExistingImage)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Text(
                    'Đã chọn ảnh',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return Container(
      color: const Color(0xFFF3F4F8),
      alignment: Alignment.center,
    );
  }

  Widget _buildScheduleCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_outlined,
                  color: AppColors.primaryDark, size: 18),
              const SizedBox(width: 8),
              Text(
                'Thời hạn đăng ký',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMiniRangeColumn(
                  label: 'Từ',
                  date: selectedRegisterStartDate,
                  time: selectedRegisterStartTime,
                  onPickDate: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedRegisterStartDate,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => selectedRegisterStartDate = date);
                    }
                  },
                  onPickTime: () async {
                    final time = await _pickTime(selectedRegisterStartTime);
                    if (time != null) {
                      setState(() => selectedRegisterStartTime = time);
                    }
                  },
                ),
              ),
              Container(
                width: 1,
                height: 44,
                color: AppColors.borderColor,
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),
              Expanded(
                child: _buildMiniRangeColumn(
                  label: 'Đến',
                  date: selectedRegisterEndDate,
                  time: selectedRegisterEndTime,
                  onPickDate: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedRegisterEndDate,
                      firstDate: selectedRegisterStartDate,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => selectedRegisterEndDate = date);
                    }
                  },
                  onPickTime: () async {
                    final time = await _pickTime(selectedRegisterEndTime);
                    if (time != null) {
                      setState(() => selectedRegisterEndTime = time);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniRangeColumn({
    required String label,
    required DateTime date,
    required TimeOfDay time,
    required VoidCallback onPickDate,
    required VoidCallback onPickTime,
  }) {
    final dateText =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final timeText = time.format(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onPickDate,
          child: Text(
            dateText,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 2),
        GestureDetector(
          onTap: onPickTime,
          child: Text(
            timeText,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventDateCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Event start date/time
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.event_note_outlined,
                    color: AppColors.primaryDark, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bắt đầu sự kiện',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() => selectedDate = date);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () async {
                              final time = await _pickTime(selectedTime);
                              if (time != null) {
                                setState(() => selectedTime = time);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
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
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.borderColor),
          const SizedBox(height: 12),
          // Event end date/time
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.event_available_outlined,
                    color: AppColors.primaryDark, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kết thúc sự kiện',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedEndDate,
                                firstDate: selectedDate,
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() => selectedEndDate = date);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                '${selectedEndDate.day.toString().padLeft(2, '0')}/${selectedEndDate.month.toString().padLeft(2, '0')}/${selectedEndDate.year}',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () async {
                              final time = await _pickTime(selectedEndTime);
                              if (time != null) {
                                setState(() => selectedEndTime = time);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                '${selectedEndTime.hour.toString().padLeft(2, '0')}:${selectedEndTime.minute.toString().padLeft(2, '0')}',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
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
          ),
        ],
      ),
    );
  }


  Widget _buildAdvancedCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Hoạt động bắt buộc',
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Bật nếu yêu cầu tất cả đoàn viên và cán bộ đoàn đăng ký',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            value: _isRequired,
            onChanged: (value) => setState(() => _isRequired = value),
          ),
          const SizedBox(height: 8),
          Text(
            'ĐỐI TƯỢNG NHẬN THÔNG TIN',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildAudienceChip('Khoa CNTT', true),
              _buildAudienceChip('Khóa 2022', true),
              _buildAudienceChip('Khóa 2023', true),
              _buildAudienceChip('+', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceChip(String label, bool filled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: filled ? const Color(0xFFF5F8FF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: filled
              ? AppColors.primaryLight.withOpacity(0.28)
              : AppColors.borderColor,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(color: AppColors.borderColor, width: 1.2),
              backgroundColor: Colors.white,
            ),
            child: Text(
              'Hủy',
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryAction() {
    return _buildGradientButton(
      label: _isEditing ? 'Cập nhật hoạt động' : 'Hoàn tất thiết lập',
      icon: Icons.done_all_rounded,
      isLoading: _isSubmitting,
      onPressed: _isSubmitting ? null : () => _createEvent(),
    );
  }

  Widget _buildHeroPanel() {
    final pickedImage = _pickedImage;
    final hasPickedImage = pickedImage != null;
    final existingImageUrl = widget.initialEvent?.imageUrl;
    final hasExistingImage =
        existingImageUrl != null && existingImageUrl.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.secondary
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.18),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -10,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 90,
            left: -28,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildHeroChip('ADMIN', Icons.admin_panel_settings_outlined),
                  _buildHeroChip(
                    _isEditing ? 'EDIT MODE' : 'NEW EVENT',
                    Icons.auto_awesome,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                _isEditing ? 'Chỉnh sửa hoạt động' : 'Tạo sự kiện hoạt động',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Thiết kế theo kiểu bảng quản trị: nổi bật banner, rõ thông tin chính và dễ thao tác trên desktop lẫn mobile.',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  height: 1.55,
                  color: Colors.white.withOpacity(0.88),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildHeroStat('Ảnh bìa', hasPickedImage || hasExistingImage),
                  _buildHeroStat('Đăng ký', true),
                  _buildHeroStat('Lịch trình', true),
                  _buildHeroStat('Xuất bản', true),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.14)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: hasPickedImage
                      ? (kIsWeb
                          ? Image.network(
                              pickedImage!.path,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(pickedImage!.path),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ))
                      : hasExistingImage
                          ? Image.network(
                              existingImageUrl!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildHeroPoster(),
                            )
                          : _buildHeroPoster(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String label, bool enabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 15,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPoster() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1D4ED8), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -10,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -35,
            left: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.event_available,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Ảnh bìa sự kiện',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tải ảnh hoạt động lên để banner trong admin nổi bật hơn và dễ nhận diện.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.white.withOpacity(0.88),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Giao diện admin',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: Colors.white,
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

  Widget _buildFormSurface() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.fact_check_outlined,
                      color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin hoạt động',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Điền thông tin cơ bản, đăng ký và lịch trình chính',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                final bool twoColumns = width >= 760;
                if (twoColumns) {
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildSectionCard(
                              title: 'Thông tin cơ bản',
                              subtitle: 'Tiêu đề, mô tả và hình ảnh hiển thị',
                              icon: Icons.fact_check_outlined,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildImagePicker(),
                                  const SizedBox(height: 18),
                                  _buildTextField(
                                    controller: titleController,
                                    label: 'Tên hoạt động *',
                                    icon: Icons.title,
                                    hint: 'Ví dụ: Đại hội liên chi đoàn',
                                  ),
                                  const SizedBox(height: 14),
                                  _buildTextField(
                                    controller: descriptionController,
                                    label: 'Mô tả',
                                    icon: Icons.description,
                                    hint:
                                        'Nội dung chi tiết, mục tiêu, đối tượng...',
                                    maxLines: 4,
                                  ),
                                  const SizedBox(height: 14),
                                  _buildTextField(
                                    controller: locationController,
                                    label: 'Địa điểm *',
                                    icon: Icons.location_on,
                                    hint: 'Ví dụ: Hội trường GD2',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: _buildSectionCard(
                              title: 'Yêu cầu tham gia',
                              subtitle: 'Thiết lập bắt buộc tham dự',
                              icon: Icons.verified,
                              child: SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  'Hoạt động bắt buộc',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  'Bật nếu yêu cầu đoàn viên tham gia',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                value: _isRequired,
                                onChanged: (value) {
                                  setState(() => _isRequired = value);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        title: 'Thời hạn đăng ký',
                        subtitle:
                            'Khoảng thời gian đoàn viên có thể đăng ký tham gia',
                        icon: Icons.how_to_reg,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDateTimeCard(
                                    'Ngày bắt đầu đăng ký',
                                    '${selectedRegisterStartDate.day}/${selectedRegisterStartDate.month}/${selectedRegisterStartDate.year}',
                                    Icons.calendar_today,
                                    () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: selectedRegisterStartDate,
                                        firstDate: DateTime.now().subtract(
                                            const Duration(days: 365)),
                                        lastDate: DateTime.now()
                                            .add(const Duration(days: 365)),
                                      );
                                      if (date != null) {
                                        setState(() =>
                                            selectedRegisterStartDate = date);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDateTimeCard(
                                    'Giờ bắt đầu đăng ký',
                                    '${selectedRegisterStartTime.hour}:${selectedRegisterStartTime.minute.toString().padLeft(2, '0')}',
                                    Icons.access_time,
                                    () async {
                                      final time = await _pickTime(
                                        selectedRegisterStartTime,
                                      );
                                      if (time != null) {
                                        setState(() =>
                                            selectedRegisterStartTime = time);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDateTimeCard(
                                    'Ngày kết thúc đăng ký',
                                    '${selectedRegisterEndDate.day}/${selectedRegisterEndDate.month}/${selectedRegisterEndDate.year}',
                                    Icons.event_available,
                                    () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: selectedRegisterEndDate,
                                        firstDate: selectedRegisterStartDate,
                                        lastDate: DateTime.now()
                                            .add(const Duration(days: 365)),
                                      );
                                      if (date != null) {
                                        setState(() =>
                                            selectedRegisterEndDate = date);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDateTimeCard(
                                    'Giờ kết thúc đăng ký',
                                    '${selectedRegisterEndTime.hour}:${selectedRegisterEndTime.minute.toString().padLeft(2, '0')}',
                                    Icons.schedule,
                                    () async {
                                      final time = await _pickTime(
                                        selectedRegisterEndTime,
                                      );
                                      if (time != null) {
                                        setState(() =>
                                            selectedRegisterEndTime = time);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        title: 'Thời gian hoạt động',
                        subtitle: 'Lịch trình chính của hoạt động',
                        icon: Icons.schedule,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDateTimeCard(
                                    'Ngày bắt đầu',
                                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                    Icons.calendar_today,
                                    () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: selectedDate,
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now()
                                            .add(const Duration(days: 365)),
                                      );
                                      if (date != null) {
                                        setState(() => selectedDate = date);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDateTimeCard(
                                    'Giờ bắt đầu',
                                    '${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}',
                                    Icons.access_time,
                                    () async {
                                      final time = await _pickTime(
                                        selectedTime,
                                      );
                                      if (time != null) {
                                        setState(() => selectedTime = time);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDateTimeCard(
                                    'Ngày kết thúc',
                                    '${selectedEndDate.day}/${selectedEndDate.month}/${selectedEndDate.year}',
                                    Icons.event_available,
                                    () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: selectedEndDate,
                                        firstDate: selectedDate,
                                        lastDate: DateTime.now()
                                            .add(const Duration(days: 365)),
                                      );
                                      if (date != null) {
                                        setState(() => selectedEndDate = date);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDateTimeCard(
                                    'Giờ kết thúc',
                                    '${selectedEndTime.hour}:${selectedEndTime.minute.toString().padLeft(2, '0')}',
                                    Icons.schedule,
                                    () async {
                                      final time = await _pickTime(
                                        selectedEndTime,
                                      );
                                      if (time != null) {
                                        setState(() => selectedEndTime = time);
                                      }
                                    },
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

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionCard(
                      title: 'Thông tin cơ bản',
                      subtitle: 'Tiêu đề, mô tả và hình ảnh hiển thị',
                      icon: Icons.fact_check_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildImagePicker(),
                          const SizedBox(height: 18),
                          _buildTextField(
                            controller: titleController,
                            label: 'Tên hoạt động *',
                            icon: Icons.title,
                            hint: 'Ví dụ: Đại hội liên chi đoàn',
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            controller: descriptionController,
                            label: 'Mô tả',
                            icon: Icons.description,
                            hint: 'Nội dung chi tiết, mục tiêu, đối tượng...',
                            maxLines: 4,
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            controller: locationController,
                            label: 'Địa điểm *',
                            icon: Icons.location_on,
                            hint: 'Ví dụ: Hội trường GD2',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Yêu cầu tham gia',
                      subtitle: 'Thiết lập bắt buộc tham dự',
                      icon: Icons.verified,
                      child: SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Hoạt động bắt buộc',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Bật nếu yêu cầu đoàn viên tham gia',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        value: _isRequired,
                        onChanged: (value) {
                          setState(() => _isRequired = value);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Thời hạn đăng ký',
                      subtitle:
                          'Khoảng thời gian đoàn viên có thể đăng ký tham gia',
                      icon: Icons.how_to_reg,
                      child: Column(
                        children: [
                          _buildDateTimeCard(
                            'Ngày bắt đầu đăng ký',
                            '${selectedRegisterStartDate.day}/${selectedRegisterStartDate.month}/${selectedRegisterStartDate.year}',
                            Icons.calendar_today,
                            () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedRegisterStartDate,
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 365)),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(
                                    () => selectedRegisterStartDate = date);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildDateTimeCard(
                            'Giờ bắt đầu đăng ký',
                            '${selectedRegisterStartTime.hour}:${selectedRegisterStartTime.minute.toString().padLeft(2, '0')}',
                            Icons.access_time,
                            () async {
                              final time = await _pickTime(
                                selectedRegisterStartTime,
                              );
                              if (time != null) {
                                setState(
                                    () => selectedRegisterStartTime = time);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildDateTimeCard(
                            'Ngày kết thúc đăng ký',
                            '${selectedRegisterEndDate.day}/${selectedRegisterEndDate.month}/${selectedRegisterEndDate.year}',
                            Icons.event_available,
                            () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedRegisterEndDate,
                                firstDate: selectedRegisterStartDate,
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() => selectedRegisterEndDate = date);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildDateTimeCard(
                            'Giờ kết thúc đăng ký',
                            '${selectedRegisterEndTime.hour}:${selectedRegisterEndTime.minute.toString().padLeft(2, '0')}',
                            Icons.schedule,
                            () async {
                              final time = await _pickTime(
                                selectedRegisterEndTime,
                              );
                              if (time != null) {
                                setState(() => selectedRegisterEndTime = time);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Thời gian hoạt động',
                      subtitle: 'Lịch trình chính của hoạt động',
                      icon: Icons.schedule,
                      child: Column(
                        children: [
                          _buildDateTimeCard(
                            'Ngày bắt đầu',
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                            Icons.calendar_today,
                            () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() => selectedDate = date);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildDateTimeCard(
                            'Giờ bắt đầu',
                            '${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}',
                            Icons.access_time,
                            () async {
                              final time = await _pickTime(
                                selectedTime,
                              );
                              if (time != null) {
                                setState(() => selectedTime = time);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildDateTimeCard(
                            'Ngày kết thúc',
                            '${selectedEndDate.day}/${selectedEndDate.month}/${selectedEndDate.year}',
                            Icons.event_available,
                            () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedEndDate,
                                firstDate: selectedDate,
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() => selectedEndDate = date);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildDateTimeCard(
                            'Giờ kết thúc',
                            '${selectedEndTime.hour}:${selectedEndTime.minute.toString().padLeft(2, '0')}',
                            Icons.schedule,
                            () async {
                              final time = await _pickTime(
                                selectedEndTime,
                              );
                              if (time != null) {
                                setState(() => selectedEndTime = time);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeCard(
      String label, String value, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF1F5FF), Color(0xFFEFF6FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
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
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: Icon(icon, size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
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
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (!mounted) return;
    if (file != null) {
      setState(() => _pickedImage = file);
    }
  }

  Widget _buildImagePicker() {
    final pickedImage = _pickedImage;
    final hasPickedImage = pickedImage != null;
    final existingImageUrl = widget.initialEvent?.imageUrl;
    final hasExistingImage =
        existingImageUrl != null && existingImageUrl.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hình ảnh hoạt động',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Stack(
          children: [
            Container(
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderColor, width: 1.5),
                color: const Color(0xFFF8FAFC),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: hasPickedImage
                    ? (kIsWeb
                        ? Image.network(
                            pickedImage.path,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(pickedImage.path),
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ))
                    : hasExistingImage
                        ? Image.network(
                            existingImageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildEmptyImage(),
                          )
                        : _buildEmptyImage(),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  hasPickedImage || hasExistingImage ? 'Ảnh bìa' : 'Chưa chọn',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload),
                label: const Text('Tải ảnh từ thiết bị'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (hasPickedImage) ...[
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => setState(() => _pickedImage = null),
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                tooltip: 'Xóa ảnh',
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyImage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text(
            'Tải ảnh hoạt động từ thiết bị',
            style: GoogleFonts.manrope(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.manrope(
        fontSize: 14,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: _inputDecoration(
        label: label,
        icon: icon,
        hint: hint,
      ).copyWith(alignLabelWithHint: maxLines > 1),
    );
  }

  Widget _buildGradientButton({
    required String label,
    required VoidCallback? onPressed,
    required bool isLoading,
    IconData? icon,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryLight, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else if (icon != null)
              Icon(icon, size: 20, color: Colors.white),
            if (icon != null || isLoading) const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.manrope(
        fontSize: 13,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      hintText: hint,
      hintStyle: GoogleFonts.manrope(
        fontSize: 13,
        color: AppColors.textSecondary.withOpacity(0.7),
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon),
      prefixIconColor: AppColors.primary,
      floatingLabelStyle: GoogleFonts.manrope(
        fontSize: 12,
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay initialTime) {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      // Allow exact minute input (including odd minutes) via keyboard mode.
      initialEntryMode: TimePickerEntryMode.input,
    );
  }

  Future<void> _createEvent({String status = 'open'}) async {
    if (_isSubmitting) return;
    if (titleController.text.isEmpty || locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ thông tin bắt buộc!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final dateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    final endDateTime = DateTime(
      selectedEndDate.year,
      selectedEndDate.month,
      selectedEndDate.day,
      selectedEndTime.hour,
      selectedEndTime.minute,
    );
    final registerStartTime = DateTime(
      selectedRegisterStartDate.year,
      selectedRegisterStartDate.month,
      selectedRegisterStartDate.day,
      selectedRegisterStartTime.hour,
      selectedRegisterStartTime.minute,
    );
    final registerEndTime = DateTime(
      selectedRegisterEndDate.year,
      selectedRegisterEndDate.month,
      selectedRegisterEndDate.day,
      selectedRegisterEndTime.hour,
      selectedRegisterEndTime.minute,
    );
    final now = DateTime.now();

    // Check: Event start time must be in future (both new and edit)
    if (dateTime.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Thời gian bắt đầu hoạt động phải từ thời điểm hiện tại trở đi.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    // Check: Event end must be AFTER start (not equal)
    // Minimum 1 minute duration
    if (!endDateTime.isAfter(dateTime.add(const Duration(minutes: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hoạt động phải kéo dài ít nhất 1 phút.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    // Check: Registration end must be AFTER registration start (not equal)
    // Minimum 1 minute registration window
    if (!registerEndTime.isAfter(registerStartTime.add(const Duration(minutes: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cửa sổ đăng ký phải ít nhất 1 phút.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (!registerStartTime.isBefore(dateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Thời gian bắt đầu đăng ký phải trước khi hoạt động bắt đầu.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (!registerEndTime.isBefore(dateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kết thúc đăng ký phải trước khi hoạt động bắt đầu.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final appState = Provider.of<AppStateService>(context, listen: false);
    final String? code = null;
    String? coverImageUrl = widget.initialEvent?.imageUrl;

    if (_pickedImage != null) {
      final imageBytes = await _pickedImage!.readAsBytes();
      final uploadResult = await appState.uploadEventImage(
        bytes: imageBytes,
        filename: _pickedImage!.name.isNotEmpty
            ? _pickedImage!.name
            : 'event_cover.jpg',
      );

      if (!mounted) return;

      if (uploadResult['success'] != true) {
        setState(() => _isSubmitting = false);
        final message = uploadResult['message']?.toString() ??
            'Tải ảnh hoạt động thất bại. Vui lòng thử lại.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }

      final data = uploadResult['data'];
      if (data is Map) {
        final uploadedUrl = data['url']?.toString();
        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          coverImageUrl = uploadedUrl;
        }
      }
    }

    final result = _isEditing
        ? await appState.updateEventRemote(
            eventId: widget.initialEvent!.id,
            code: code,
            title: titleController.text,
            description: descriptionController.text,
            startTime: dateTime,
            endTime: endDateTime,
            registerStartTime: registerStartTime,
            registerEndTime: registerEndTime,
            location: locationController.text,
            isRequired: _isRequired,
            coverImageUrl: coverImageUrl,
          )
        : await appState.createEvent(
            code: code,
            title: titleController.text,
            description: descriptionController.text,
            startTime: dateTime,
            endTime: endDateTime,
            registerStartTime: registerStartTime,
            registerEndTime: registerEndTime,
            location: locationController.text,
            plan: null,
            isRequired: _isRequired,
            coverImageUrl: coverImageUrl,
            status: status,
          );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == false) {
      final message = result['message']?.toString() ??
          (_isEditing
              ? 'Cập nhật hoạt động thất bại. Vui lòng thử lại.'
              : 'Tạo hoạt động thất bại. Vui lòng thử lại.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing
              ? 'Cập nhật hoạt động thành công!'
              : 'Tạo hoạt động thành công!',
        ),
        backgroundColor: const Color(0xFF0F766E),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
