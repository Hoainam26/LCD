# Hướng Dẫn Sử Dụng: Nhận Phản Hồi Liên Hệ từ Admin (Member)

## 📋 Tổng Quan
Tính năng **Nhận Phản Hồi Liên Hệ** cho phép các đoàn viên (member) xem các câu trả lời từ quản trị viên (admin) khi họ gửi liên hệ hỏi đáp.

## 🎯 Quy Trình Hoạt Động

### 1️⃣ Đoàn Viên Gửi Liên Hệ
- **Màn hình**: `ContactScreen` (Liên hệ & Hỗ trợ)
- **Các bước**:
  1. Nhập Họ và Tên
  2. Nhập Email
  3. Chọn Nội dung liên quan (Hoạt động Đoàn, Điểm rèn luyện, Tài khoản, Khác)
  4. Nhập Nội dung chi tiết
  5. Nhấn nút "Gửi tin nhắn"

**Kết quả**: Tin nhắn được lưu vào database với trạng thái `new`

### 2️⃣ Admin Xem & Phản Hồi
- **Màn hình**: `AdminContactInboxScreen` (Quản trị - Hộp thư liên hệ)
- **Các bước**:
  1. Xem danh sách tất cả tin nhắn liên hệ
  2. Lọc theo Danh mục (Hoạt động, Điểm rèn luyện, v.v.) hoặc Trạng thái (Mới, Đang xử lý, Đã phản hồi)
  3. Nhấn vào tin nhắn để xem chi tiết
  4. Chọn Trạng thái xử lý (Mới, Đang xử lý, Đã phản hồi)
  5. Nhập Phản hồi
  6. Nhấn "Gửi phản hồi"

**Kết quả**: 
- Tin nhắn được cập nhật với `status = 'resolved'` và `response = '<nội dung phản hồi>'`
- Email thông báo được gửi đến member

### 3️⃣ Đoàn Viên Nhận Phản Hồi
- **Màn hình**: `ContactScreen` (Liên hệ & Hỗ trợ) → Phần "Phản hồi từ quản trị"
- **Thông tin hiển thị**:
  - ✅ Chủ đề liên hệ
  - ✅ Trạng thái ("Đã phản hồi")
  - ✅ Nội dung phản hồi từ admin
  - ✅ Thời gian phản hồi (Ngày/Tháng/Năm Giờ:Phút)

## 🔧 Cấu Trúc Kỹ Thuật

### Database Schema (PostgreSQL)
```sql
CREATE TABLE contact_messages (
  id INTEGER PRIMARY KEY AUTO_INCREMENT,
  user_id INTEGER,
  full_name VARCHAR(150),
  email VARCHAR(150),
  topic VARCHAR(120),
  content TEXT,
  status ENUM('new', 'in_progress', 'resolved'),
  response TEXT,
  responded_by INTEGER,
  responded_at DATETIME,
  created_at DATETIME,
  updated_at DATETIME
);
```

### API Endpoints

#### 📤 Tạo tin nhắn liên hệ (Member)
```
POST /v1/api/contact/messages
Headers: Authorization: Bearer <token>
Body: {
  "full_name": "Nguyễn Văn A",
  "email": "user@dnu.edu.vn",
  "topic": "Hoạt động Đoàn",
  "content": "Tôi muốn biết thêm về hoạt động..."
}
Response: { code: 201, message: "...", data: {...} }
```

#### 📥 Lấy danh sách tin nhắn của member
```
GET /v1/api/contact/messages?limit=50
Headers: Authorization: Bearer <token>
Response: [
  {
    id: 1,
    full_name: "Nguyễn Văn A",
    email: "user@dnu.edu.vn",
    topic: "Hoạt động Đoàn",
    content: "...",
    status: "resolved",
    response: "Phản hồi từ admin...",
    responded_at: "2024-01-15T10:30:00",
    ...
  }
]
```

#### 📝 Admin gửi phản hồi
```
PUT /v1/api/contact/messages/:id/respond
Headers: Authorization: Bearer <token> (chỉ admin/staff)
Body: {
  "response": "Cảm ơn bạn đã liên hệ...",
  "status": "resolved"
}
Response: { code: 200, message: "...", data: {...} }
```

### Flutter Implementation

#### 1. File: lib/screens/contact_screen.dart
```dart
class ContactScreen extends StatefulWidget {
  // Gửi tin nhắn
  Future<void> _submitMessage() async { ... }
  
  // Load danh sách phản hồi từ admin
  Future<void> _loadMyResponseMessages() async {
    final messages = await ApiService.getContactMessages(limit: 50);
    final responded = messages.where((item) {
      final status = (item['status'] ?? '').toString().toLowerCase();
      final response = (item['response'] ?? '').toString().trim();
      return status == 'resolved' && response.isNotEmpty;
    }).toList();
    setState(() => _responseMessages = responded);
  }
  
  // Hiển thị phần phản hồi
  Widget _buildResponseSection() { ... }
}
```

#### 2. File: lib/screens/admin_contact_inbox_screen.dart
```dart
class AdminContactInboxScreen extends StatefulWidget {
  // Load tất cả tin nhắn (cho admin)
  Future<void> _loadData() async { ... }
  
  // Hiển thị form phản hồi
  void _showDetailSheet(_ContactMessageItem item) { ... }
  
  // Gửi phản hồi
  final result = await ApiService.respondToContactMessage(
    id: item.id.toString(),
    response: response,
    status: status,
  );
}
```

#### 3. File: lib/services/api_service.dart
```dart
static Future<List<dynamic>> getContactMessages({limit = 20}) {
  return getRequest('/contact/messages?limit=$limit');
}

static Future<Map<String, dynamic>> respondToContactMessage({
  required String id,
  required String response,
  required String status,
}) {
  return putRequest(
    '/contact/messages/$id/respond',
    {'response': response, 'status': status},
  );
}
```

### Backend (Node.js) Implementation

#### File: src/services/contact.service.js
- `create()` - Tạo tin nhắn mới
- `getList()` - Lấy danh sách (filter theo user nếu member)
- `getById()` - Lấy chi tiết tin nhắn
- `respond()` - Admin gửi phản hồi + gửi email

#### File: src/routes/contact/index.js
- `POST /contact/messages` - Tạo
- `GET /contact/messages` - Danh sách
- `GET /contact/messages/:id` - Chi tiết
- `PUT /contact/messages/:id/respond` - Phản hồi

## 🐛 Khắc Phục Sự Cố

### Vấn đề: Member không thấy phần "Phản hồi từ quản trị"

**Nguyên nhân có thể**:
1. Admin chưa phản hồi tin nhắn
2. Tin nhắn chưa được đánh dấu là `resolved`
3. Trường `response` trống

**Giải pháp**:
1. Kiểm tra admin đã phản hồi chưa:
   - Vào `AdminContactInboxScreen` → Tìm tin nhắn
   - Kiểm tra trạng thái là "Đã phản hồi" không
2. Kiểm tra database:
   ```sql
   SELECT * FROM contact_messages WHERE user_id = ? AND status = 'resolved';
   ```
3. Làm mới danh sách: Kéo xuống để refresh

### Vấn đề: Phản hồi không được gửi qua email

**Cần kiểm tra**:
- `.env` file có cấu hình SMTP không:
  ```env
  SMTP_HOST=...
  SMTP_PORT=...
  SMTP_USER=...
  SMTP_PASS=...
  SUPPORT_EMAIL=...
  ```

## 📱 Giao Diện Member (Contact Screen)

### Layout
```
┌─────────────────────────────────┐
│    Liên hệ & Hỗ trợ            │  (App Bar)
├─────────────────────────────────┤
│  🔶 Gửi tin nhắn                │  (Contact Form)
│  ├─ Họ và tên: [          ]     │
│  ├─ Email: [               ]    │
│  ├─ Nội dung: [          ]      │
│  └─ [Gửi tin nhắn]              │
├─────────────────────────────────┤
│  📨 Phản hồi từ quản trị         │  (Response Section)
│  ├─ Hoạt động Đoàn  [Đã phản hồi]│
│  │  Phản hồi: "Cảm ơn bạn..."   │
│  │  15/1/2024 10:30             │
│  │                               │
│  └─ Tài khoản  [Đã phản hồi]    │
│     Phản hồi: "Chúng tôi..."    │
│     10/1/2024 14:20             │
└─────────────────────────────────┘
```

## 🔐 Quyền Truy Cập

| Chức năng | Member | Staff | Admin |
|-----------|--------|-------|-------|
| Xem form liên hệ | ✅ | ✅ | ✅ |
| Gửi tin nhắn | ✅ | ✅ | ✅ |
| Xem phản hồi của mình | ✅ | ✅ | ✅ |
| Xem tất cả tin nhắn | ❌ | ✅ | ✅ |
| Gửi phản hồi | ❌ | ✅ | ✅ |

## 📝 Ghi Chú

1. **Tự động gửi email**: Khi admin phản hồi, hệ thống tự động gửi email thông báo đến member
2. **Trạng thái tin nhắn**: 
   - `new` - Mới nhận
   - `in_progress` - Đang xử lý
   - `resolved` - Đã phản hồi
3. **Thời gian phản hồi**: Lưu lại `responded_at` để tracking
4. **Refresh dữ liệu**: Member có thể kéo xuống để làm mới danh sách phản hồi

---
**Phiên bản**: 1.0 | **Cập nhật**: 2024-01-15 | **Trạng thái**: ✅ Hoạt động
