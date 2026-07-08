# 🎨 Hướng Dẫn Thiết Lập Giao Diện Tin Tức - News Feed Setup Guide

## ✨ Các Tính Năng Mới (New Features)

### 1. **Banner Carousel** (Băng quảng cáo)
- Tự động cuộn ảnh mỗi 4 giây
- Hiển thị dấu chỉ (indicators) dưới banner
- Bạn có thể thêm/thay đổi ảnh dễ dàng

### 2. **Tin Tức & Thông Báo** (News Feed)
- Hiển thị lên đến **10 tin tức** với layout ma trận (image + text)
- Mỗi tin tức hiển thị: Ảnh, Tiêu đề, Mô tả, Ngày đăng
- **Khi bấm vào** → Hiển thị bài báo đầy đủ chi tiết
- Cuộn (scroll) xuống để xem thêm tin tức

### 3. **Tin Tức Liên Quan** (Related News)
- Hiển thị 5 tin tức liên quan dưới phần chính
- Cùng format với phần tin tức main

---

## 📁 Cách Thêm Ảnh Banner

### **Bước 1**: Chuẩn Bị Ảnh
- Kích thước tối ưu: **800x400px** (hoặc tỷ lệ 2:1)
- Định dạng: `.jpg`, `.png`
- File size: < 500KB mỗi ảnh

### **Bước 2**: Thêm Ảnh Vào Thư Mục
```
assets/
  └── images/
      ├── banner1.jpg    ✅ (hiện tại)
      ├── banner2.jpg    ✅ (hiện tại)
      ├── banner3.jpg    ← Thêm ảnh của bạn ở đây
      └── banner4.jpg    ← Thêm ảnh của bạn ở đây
```

### **Bước 3**: Khai Báo Ảnh Trong Code
Mở file: `lib/screens/member_home_screen.dart`

Tìm dòng:
```dart
final List<String> _bannerImages = [
  'assets/images/banner1.jpg',
  'assets/images/banner2.jpg',
  'assets/images/banner3.jpg',
  'assets/images/banner4.jpg',
];
```

**Thay đổi đường dẫn để khớp với ảnh của bạn:**
```dart
final List<String> _bannerImages = [
  'assets/images/your_banner1.jpg',  // ← Thay tên ảnh
  'assets/images/your_banner2.jpg',
  'assets/images/your_banner3.jpg',
  'assets/images/your_banner4.jpg',
];
```

### **Bước 4**: Cập Nhật `pubspec.yaml`
Mở file: `pubspec.yaml`

Tìm và cập nhật section `assets`:
```yaml
flutter:
  assets:
    - assets/images/
    # Hoặc liệt kê cụ thể từng ảnh:
    - assets/images/banner1.jpg
    - assets/images/banner2.jpg
    - assets/images/your_banner3.jpg
    - assets/images/your_banner4.jpg
```

### **Bước 5**: Thử Nghiệm
```bash
# Chạy ứng dụng để kiểm tra
flutter run -d edge
```

---

## 📰 Cách Tin Tức Được Hiển Thị

### **Layout Tin Tức**
```
┌─────────────────────────────────────┐
│ ┌─────────┐  Tiêu đề tin tức        │
│ │         │  Mô tả ngắn...          │
│ │  Image  │  📅 20/03/2026          │
│ │ (120px) │                         │
│ └─────────┘                         │
└─────────────────────────────────────┘
```

### **Dữ Liệu Tin Tức Đến Từ**
- API từ server của bạn
- Tự động cập nhật khi refresh (kéo xuống)
- Lấy từ `appState.news` trong AppStateService

### **Thứ Tự Hiển Thị**
1. **Phần "Tin Tức & Thông Báo"** → 10 tin tức đầu tiên
2. **Phần "Tin Tức Liên Quan"** → 5 tin tức kế tiếp (từ vị trí 11-15)

---

## 🔧 Tùy Chỉnh Nâng Cao

### **Thay Đổi Số Lượng Tin Tức**
Tìm dòng trong `member_home_screen.dart`:
```dart
final newsList = appState.news.take(10).toList();  // ← Thay 10 thành số khác
```

### **Thay Đổi Màu Sắc**
Tìm trong hàm `_buildNewsCardVertical()`:
```dart
// Màu chủ đạo
color: const Color(0xFF1E3A8A),  // ← Blue
```

### **Thay Đổi Thời Gian Tự Động Cuộn Banner**
Tìm:
```dart
autoPlayInterval: const Duration(seconds: 4),  // ← Thay 4 thành giây khác
```

---

## 📊 Cấu Trúc Tin Tức (News Item Structure)

Mỗi tin tức có thông tin:
- `title` - Tiêu đề (bắt buộc)
- `date` - Ngày đăng (định dạng: DD/MM/YYYY)
- `image` - Đường dẫn ảnh
- `description` - Mô tả ngắn (120 ký tự)
- `content` - Nội dung đầy đủ (hiển thị khi click)
- `category` - Thể loại tin

---

## 🎯 Features Được Hỗ Trợ

✅ **Hiển thị ảnh từ URL (network)**
✅ **Hiển thị ảnh từ assets (local)**
✅ **Automatic error handling** - Thay thế bằng icon nếu ảnh lỗi
✅ **Click thumto view detail** - Mở full article view
✅ **Loading indicator** - Hiển thị loading khi đang tải
✅ **Responsive design** - Tự động adjust cho desktop/tablet/mobile
✅ **Smooth animations** - Transition mượt mà

---

## 🐛 Gỡ Lỗi

### **Ảnh Banner Không Hiển Thị**
1. Kiểm tra đường dẫn ảnh trong code
2. Kiểm tra công bố asset trong `pubspec.yaml`
3. Chạy `flutter pub get` để cập nhật
4. Clean build: `flutter clean && flutter pub get`

### **Tin Tức Không Load**
1. Kiểm tra kết nối API
2. Kiểm tra mô hình dữ liệu tin tức
3. Xem console log lỗi

### **UI Lỡm Lỗm (Rendering Issues)**
1. Full rebuild: `flutter clean`
2. Xóa cache: `flutter pub cache clean`
3. Reinstall: `flutter pub get`

---

## 📝 Lưu Ý Quan Trọng

⚠️ **Chất lượng ảnh**: Dùng ảnh **định dạng tối ưu** để tránh lag
⚠️ **Kích thước file**: Giữ < 500KB mỗi ảnh banner
⚠️ **Số lượng ảnh**: Tối đa 4-6 ảnh banner để tránh chậm
⚠️ **API dữ liệu**: Đảm bảo API trả về dữ liệu tin tức đầy đủ

---

## 📱 Responsive Design

| Device | Layout |
|--------|--------|
| **Mobile** | Tin tức xếp thành cột (column) |
| **Tablet** | Tin tức với padding tối ưu |
| **Desktop** | Full width với padding 20px |

---

**Chúc bạn tạo một giao diện tin tức tuyệt vời! 🎉**
