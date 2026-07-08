# Hướng dẫn Kết nối API

## API Base URL
```
https://dtn-api.aiotlab.edu.vn/api
```

## Các Endpoint Chính

### 1. Đăng Ký (Sign Up)
**Endpoint:** `POST /access/signup`
```dart
await ApiService.signup(
  email: 'user@example.com',
  password: 'password123',
  fullName: 'Tên đầy đủ',
);
```

### 2. Đăng Nhập (Sign In)
**Endpoint:** `POST /access/signin`
```dart
await ApiService.signin(
  email: 'user@example.com',
  password: 'password123',
);
```
**Response:** Trả về `accessToken` và `refreshToken` (tự động lưu vào SharedPreferences)

### 3. Đăng Xuất (Sign Out)
**Endpoint:** `POST /access/signout`
```dart
await ApiService.signout();
```

### 4. Làm mới Token (Refresh Token)
**Endpoint:** `POST /access/refresh`
```dart
await ApiService.refreshToken();
```

### 5. GET Request Chung
**Sử dụng cho bất kỳ endpoint nào:**
```dart
await ApiService.getRequest('/activity/get-all');
```

## Cách Sử Dụng trong Widget

### Ví dụ 1: Đăng Nhập
```dart
import '../services/api_service.dart';

// Gọi API
final result = await ApiService.signin(
  email: emailController.text,
  password: passwordController.text,
);

// Kiểm tra kết quả
if (result['accessToken'] != null) {
  // Đăng nhập thành công
  print('Token: ${result['accessToken']}');
} else {
  // Đăng nhập thất bại
  print('Lỗi: ${result['message']}');
}
```

### Ví dụ 2: Lấy dữ liệu (với authentication)
```dart
final result = await ApiService.getRequest('/activity/get-all');
if (result['success'] != false) {
  // Lấy dữ liệu thành công
  print(result);
} else {
  print('Lỗi: ${result['message']}');
}
```

## Quản Lý Token

### Lấy Access Token hiện tại
```dart
final token = await ApiService.getAccessToken();
if (token != null) {
  print('Token hiện có: $token');
}
```

### Token tự động được lưu vào SharedPreferences
- `accessToken` - Token để xác thực requests
- `refreshToken` - Token để làm mới accessToken

## Xử Lý Lỗi

```dart
final result = await ApiService.signin(
  email: email,
  password: password,
);

if (result['accessToken'] != null) {
  // Thành công
} else if (result['success'] == false) {
  // Có lỗi từ API
  print(result['message']); // Tin nhắn lỗi
  print(result['error']);   // Chi tiết lỗi
}
```

## Các Headers Mặc Định

- `Content-Type: application/json`
- `Authorization: Bearer <accessToken>` (tự động thêm cho các request GET)

## Lưu ý quan trọng

1. **Token** được tự động lưu sau khi đăng nhập thành công
2. **API Service** sẽ tự động thêm Authorization header cho các requests
3. Sử dụng `mounted` check trước khi `setState` hoặc navigation
4. Bất cứ khi nào gặp lỗi, hãy check log để xem chi tiết

## Cập nhật Endpoints khác

Khi cần gọi các endpoint khác từ Swagger, thêm method vào `ApiService`:

```dart
static Future<Map<String, dynamic>> customEndpoint({
  required String param1,
  required String param2,
}) async {
  try {
    final token = await getAccessToken();
    final response = await http.post(
      Uri.parse('$baseUrl/endpoint-path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'param1': param1,
        'param2': param2,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {'success': false, 'message': 'Lỗi: ${response.statusCode}'};
    }
  } catch (e) {
    return {'success': false, 'message': 'Lỗi kết nối: $e'};
  }
}
```

## Bước tiếp theo

1. Chạy `flutter pub get` để cài đặt packages
2. Update các login screens khác (officer_login_screen.dart, admin_login_screen.dart)
3. Tạo screens cho hiển thị dữ liệu activities
4. Thêm xử lý token refresh nếu cần
