class Validators {
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  static bool isValidPhone(String phone) {
    final p = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    return RegExp(r'^\+?[0-9]{7,15}$').hasMatch(p);
  }

  static bool isNotEmpty(String value) {
    return value.trim().isNotEmpty;
  }
}
