# 💻 Hướng Dẫn Code & Ví Dụ Thực Hành

## 📝 Các Ví Dụ Thực Hành & Code Snippets

### ✅ **Example 1: Thêm Ảnh Banner Mới**

**Bước 1**: Copy ảnh vào folder
```
assets/images/my_banner_1.jpg
assets/images/my_banner_2.jpg
```

**Bước 2**: Update code trong `lib/screens/member_home_screen.dart`
```dart
// Line ~32-40
final List<String> _bannerImages = [
  'assets/images/my_banner_1.jpg',    // ← Thay đổi
  'assets/images/my_banner_2.jpg',    // ← Thay đổi
  'assets/images/my_banner_3.jpg',    // ← Giữ như cũ hoặc thay
  'assets/images/my_banner_4.jpg',    // ← Giữ như cũ hoặc thay
];
```

**Bước 3**: Update `pubspec.yaml`
```yaml
flutter:
  assets:
    - assets/images/  # ← Hoặc list từng file
```

**Bước 4**: Run
```bash
flutter pub get
flutter run -d edge
```

---

### ✅ **Example 2: Thay Đổi Thời Gian Auto-Scroll Banner**

**Tìm dòng** (~292):
```dart
autoPlayInterval: const Duration(seconds: 4),
```

**Thay Đổi**:
```dart
// Scroll mỗi 2 giây
autoPlayInterval: const Duration(seconds: 2),

// Scroll mỗi 5 giây
autoPlayInterval: const Duration(seconds: 5),

// Scroll mỗi 10 giây
autoPlayInterval: const Duration(seconds: 10),
```

---

### ✅ **Example 3: Thay Đổi Số Lượng Tin Tức Hiển Thị**

**Tìm dòng** (~372):
```dart
final newsList = appState.news.take(10).toList();  // Hiện tại: 10 items
```

**Thay Đổi**:
```dart
// Hiển thị 15 tin tức
final newsList = appState.news.take(15).toList();

// Hiển thị 20 tin tức
final newsList = appState.news.take(20).toList();

// Hiển thị tất cả
final newsList = appState.news.toList();  // Không dùng .take()
```

---

### ✅ **Example 4: Thay Đổi Số Lượng Tin Tức Liên Quan**

**Tìm dòng** (~397):
```dart
final relatedNews = appState.news.skip(10).take(5).toList();
```

**Giải Thích**:
- `skip(10)` = Bỏ qua 10 tin tức đầu
- `take(5)` = Lấy 5 tin tức kế tiếp (11-15)

**Thay Đổi**:
```dart
// Hiển thị 8 tin tức liên quan (items 11-18)
final relatedNews = appState.news.skip(10).take(8).toList();

// Hiển thị 3 tin tức liên quan (items 11-13)
final relatedNews = appState.news.skip(10).take(3).toList();
```

---

### ✅ **Example 5: Thay Đổi Màu Banner Indicators**

**Tìm dòng** (~325):
```dart
color: _currentBannerIndex == index
    ? const Color(0xFF1E3A8A)        // ← Active (bright blue)
    : Colors.grey[300],              // ← Inactive (light gray)
```

**Thay Đổi Màu Active**:
```dart
// Màu đỏ
color: _currentBannerIndex == index
    ? const Color(0xFFDC2626)        // ← Red
    : Colors.grey[300],

// Màu xanh lá
color: _currentBannerIndex == index
    ? const Color(0xFF10B981)        // ← Green
    : Colors.grey[300],

// Màu tím
color: _currentBannerIndex == index
    ? const Color(0xFF8B5CF6)        // ← Purple
    : Colors.grey[300],
```

---

### ✅ **Example 6: Thay Đổi Kích Thước Card Tin Tức**

**Tìm dòng** (~2150):
```dart
Container(
  width: 120,      // ← Chiều rộng ảnh
  height: 120,     // ← Chiều cao card
  color: Colors.grey[100],
  // ...
)
```

**Thay Đổi Kích Thước**:
```dart
// Kích thước lớn hơn (150x150)
Container(
  width: 150,
  height: 150,
  // ...
)

// Kích thước nhỏ hơn (100x100)
Container(
  width: 100,
  height: 100,
  // ...
)

// Kích thước rất lớn (180x180)
Container(
  width: 180,
  height: 180,
  // ...
)
```

---

### ✅ **Example 7: Thay Đổi Font Size Tiêu Đề Tin Tức**

**Tìm dòng** (~2181):
```dart
Text(
  news.title,
  style: const TextStyle(
    fontSize: 14,        // ← Hiện tại
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  ),
)
```

**Thay Đổi**:
```dart
// Chữ lớn hơn
fontSize: 16,  // hoặc 18

// Chữ nhỏ hơn
fontSize: 12,  // hoặc 11

// Chữ bold hơn
fontWeight: FontWeight.bold,  // hoặc FontWeight.w700

// Chữ nhẹ hơn
fontWeight: FontWeight.w500,
```

---

### ✅ **Example 8: Thêm Icon Trước Tiêu Đề**

**Tìm dòng** (~2176):
```dart
// Title
Text(
  news.title,
  style: const TextStyle(...),
)
```

**Thêm Icon**:
```dart
// Row để chứa icon + text
Row(
  children: [
    const Icon(
      Icons.newspaper,  // ← Icon tin tức
      size: 14,
      color: Colors.grey[600],
    ),
    const SizedBox(width: 6),
    Expanded(
      child: Text(
        news.title,
        style: const TextStyle(...),
      ),
    ),
  ],
)
```

---

### ✅ **Example 9: Thay Đổi Border Radius**

**Tìm dòng** (~2143):
```dart
decoration: BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(12),  // ← Hiện tại
)
```

**Thay Đổi**:
```dart
// Góc bo tròn nhiều hơn
borderRadius: BorderRadius.circular(20),

// Góc bo tròn ít hơn
borderRadius: BorderRadius.circular(8),

// Góc vuông
borderRadius: BorderRadius.circular(0),

// Góc được tùy chỉnh (trái vs phải khác nhau)
borderRadius: const BorderRadius.only(
  topLeft: Radius.circular(16),
  bottomLeft: Radius.circular(8),
  topRight: Radius.circular(8),
  bottomRight: Radius.circular(16),
),
```

---

### ✅ **Example 10: Thêm Padding Thêm Vào Card**

**Tìm dòng** (~2148):
```dart
child: ClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: Row(...),
)
```

**Thêm Padding**:
```dart
child: ClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: Padding(
    padding: const EdgeInsets.all(8),  // ← Thêm padding
    child: Row(...),
  ),
)
```

---

### ✅ **Example 11: Thay Đổi Shadow Card**

**Tìm dòng** (~2144):
```dart
boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(0.08),    // ← Màu shadow
    blurRadius: 10,                            // ← Độ mờ
    offset: const Offset(0, 3),               // ← Vị trí
  ),
],
```

**Thay Đổi Shadow Mạnh Hơn**:
```dart
boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(0.15),  // ← Đậm hơn
    blurRadius: 15,                         // ← Mờ hơn
    offset: const Offset(0, 5),            // ← Cách xa hơn
  ),
],
```

**Thay Đổi Shadow Yếu Hơn**:
```dart
boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(0.04),  // ← Nhạt hơn
    blurRadius: 6,                          // ← Mờ ít hơn
    offset: const Offset(0, 2),            // ← Gần hơn
  ),
],
```

---

### ✅ **Example 12: Thay Đổi Màu Text**

**Tìm dòng** (~2181):
```dart
Text(
  news.title,
  style: const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.black87,  // ← Màu chữ
  ),
)
```

**Thay Đổi Màu**:
```dart
// Đen hoàn toàn
color: Colors.black,

// Xám sẫm
color: Colors.grey[700],

// Xám nhạt
color: Colors.grey[500],

// Màu custom (hex)
color: const Color(0xFF1E3A8A),  // Blue

// Màu đỏ
color: const Color(0xFFDC2626),

// Màu xanh lá
color: const Color(0xFF10B981),
```

---

### ✅ **Example 13: Disable Auto-Play Banner**

**Tìm dòng** (~291):
```dart
autoPlay: true,  // ← Hiện tại
```

**Thay Đổi**:
```dart
// Disable auto-play
autoPlay: false,

// Nhưng vẫn có thể click indicators để chuyển manual
```

---

### ✅ **Example 14: Thêm Event Listener Khi Click Card**

**Hiện tại** (line ~2135):
```dart
GestureDetector(
  onTap: () {
    Navigator.push(context, ...);
  },
)
```

**Thêm Long Press**:
```dart
GestureDetector(
  onTap: () {
    Navigator.push(context, ...);
  },
  onLongPress: () {
    // Thêm menu context, share, bookmark, etc.
    print('Long pressed: ${news.title}');
    // Hiển thị popup menu
    showMenu<String>(
      context: context,
      position: RelativeRect.fill,
      items: [
        const PopupMenuItem(value: 'share', child: Text('Chia sẻ')),
        const PopupMenuItem(value: 'save', child: Text('Lưu lại')),
      ],
    );
  },
)
```

---

### ✅ **Example 15: Conditionally Hide Related News**

**Nếu muốn ẩn phần "Related News" khi có ít tin tức**:

**Tìm dòng** (~385):
```dart
// Related News Section - Tin tức liên quan
Padding(...)
```

**Thêm Điều Kiện**:
```dart
if (appState.news.length > 10) ...[
  const SizedBox(height: 20),
  // Related News Section
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(...),
  ),
],
```

**Giải Thích**:
- Chỉ hiển thị phần "Related News" nếu có > 10 tin tức
- `...` là spread operator (thêm items vào list)
- `if (condition) [...]` hoặc `if (condition) ...[...]`

---

## 🔍 Tìm Kiếm Code Trong File

### **Tìm Banner Images**
```
Ctrl+F (hoặc Cmd+F trên Mac) → "_bannerImages"
```

### **Tìm Tin Tức Section**
```
Ctrl+F → "Tin Tức & Thông Báo"
```

### **Tìm Related News**
```
Ctrl+F → "Tin Tức Liên Quan"
```

### **Tìm News Card Widget**
```
Ctrl+F → "_buildNewsCardVertical"
```

---

## 🧪 Test Các Thay Đổi

```bash
# 1. Sau khi edit code
flutter pub get

# 2. Kiểm tra syntax
flutter analyze

# 3. Clean build
flutter clean

# 4. Run on web
flutter run -d edge

# 5. Hoặc build
flutter build web
```

---

## ⚠️ Common Mistakes & Fixes

### **Lỗi 1: Ảnh Banner Không Hiển Thị**
```
❌ Sai: 'assets/images/banner.jpg'
✅ Đúng: 'assets/images/banner.jpg'

Check:
- Đường dẫn đúng?
- File có tồn tại?
- pubspec.yaml có khai báo asset?
```

### **Lỗi 2: Hot Reload Không Cập Nhật**
```
❌ Sai: Chỉ reload (R)
✅ Đúng: Clean + Restart

flutter clean
flutter pub get
flutter run -d edge
```

### **Lỗi 3: Widget Error**
```
Nếu thấy "Flutter Error" screen:
1. Check console log lỗi
2. Verify import statements
3. Check widget parameters
4. Rebuild app
```

### **Lỗi 4: Data Not Loading**
```
Nếu tin tức không hiển thị:
1. Check API response
2. Verify news data model
3. Check Provider state
4. Look at console.log errors
```

---

## 📚 Tài Liệu Tham Khảo

- [Flutter Docs: Container](https://api.flutter.dev/flutter/widgets/Container-class.html)
- [Flutter Docs: BoxDecoration](https://api.flutter.dev/flutter/painting/BoxDecoration-class.html)
- [Flutter Docs: ListView](https://api.flutter.dev/flutter/widgets/ListView-class.html)
- [Flutter Docs: GestureDetector](https://api.flutter.dev/flutter/widgets/GestureDetector-class.html)

---

**Happy Coding!** 💻
