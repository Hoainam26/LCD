import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';

class NotificationDetailScreen extends StatelessWidget {
  final String title;
  final String date;
  final String time;
  final String author;
  final String content;

  const NotificationDetailScreen({
    Key? key,
    this.title = 'Thông báo về việc tổ chức Hội thao Sinh viên Khoa CNTT năm 2025',
    this.date = '24/10/2024',
    this.time = '14:30',
    this.author = 'BCH Đoàn Khoa',
    this.content = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FC),
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Chi tiết thông báo',
          style: GoogleFonts.manrope(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        leading: const BackButton(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBE2DE),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.campaign, color: Color(0xFFB91C1C), size: 15),
                      const SizedBox(width: 6),
                      Text(
                        'Hoạt động',
                        style: GoogleFonts.manrope(
                          color: const Color(0xFFB91C1C),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Title
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: 14),

                // Meta row
                Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  children: [
                    _metaItem(Icons.calendar_today, date),
                    _metaItem(Icons.access_time, time),
                    _metaItem(Icons.person, author),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(color: Color(0xFFE5E7EB)),
                const SizedBox(height: 16),

                // Important note box
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7F8FB),
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    border: Border(left: BorderSide(color: AppColors.primary, width: 4)),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF0FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Lưu ý quan trọng\nSinh viên cần đăng ký tham gia trước ngày 30/10/2024. Danh sách chính thức sẽ được công bố vào ngày 02/11/2024.',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            height: 1.45,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Body content (sample paragraphs)
                Text(
                  'Kính gửi toàn thể sinh viên Khoa Công nghệ Thông tin,',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    height: 1.55,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Nhằm đẩy mạnh phong trào rèn luyện thân thể, tạo sân chơi lành mạnh, bổ ích và tăng cường sự giao lưu, đoàn kết giữa sinh viên các khóa, Ban Chấp hành Đoàn Khoa thông báo tổ chức Hội thao Sinh viên năm 2025.',
                  style: GoogleFonts.manrope(fontSize: 14.5, height: 1.7, color: AppColors.textSecondary),
                ),

                const SizedBox(height: 18),
                Text('1. Thời gian và Địa điểm', style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                _bulletRow('Thời gian: Từ ngày 10/11/2024 đến ngày 25/11/2024.'),
                const SizedBox(height: 6),
                _bulletRow('Địa điểm: Sân vận động trường và Nhà thi đấu đa năng.'),

                const SizedBox(height: 14),
                Text('2. Các môn thi đấu', style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                _bulletRow('Bóng đá nam (sân 5 người)'),
                _bulletRow('Bóng chuyền nam, nữ'),
                _bulletRow('Cầu lông (đơn nam, đơn nữ, đôi nam nữ)'),
                _bulletRow('Kéo co'),

                const SizedBox(height: 18),
                Text(
                  'Chi tiết về điều lệ giải và thể thức thi đấu, sinh viên vui lòng xem trong file đính kèm bên dưới. Các Bí thư chi đoàn chịu trách nhiệm tổng hợp danh sách và gửi về Văn phòng Đoàn Khoa đúng hạn.',
                  style: GoogleFonts.manrope(fontSize: 14.5, height: 1.7, color: AppColors.textSecondary),
                ),

                const SizedBox(height: 22),

                Text(
                  'Tài liệu đính kèm',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Attachment card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD3D9EA)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCECEC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.picture_as_pdf, color: Color(0xFFD11F1F), size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dieu le_Hoi_thao_2025.pdf', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            const SizedBox(height: 6),
                            Text('2.4 MB • PDF Document', style: GoogleFonts.manrope(color: AppColors.textSecondary, fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.download_outlined, color: Color(0xFF26418F)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 88),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.bookmark_border),
                  label: Text('Lưu thông báo', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFF0F2F8),
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share),
                  label: Text('Chia sẻ', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF4B5563)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF4B5563))),
      ],
    );
  }

  Widget _bulletRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: GoogleFonts.manrope(fontSize: 18, color: AppColors.textPrimary)),
          Expanded(child: Text(text, style: GoogleFonts.manrope(fontSize: 14, color: AppColors.textSecondary, height: 1.6))),
        ],
      ),
    );
  }
}
