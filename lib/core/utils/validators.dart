// ------------------------------
// lib/core/utils/validators.dart

class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'E-posta adresi gereklidir';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Geçerli bir e-posta adresi girin';
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gereklidir';
    }

    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalıdır';
    }

    return null;
  }

  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Bu alan'} gereklidir';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Telefon zorunlu değil
    }

    final phoneRegex = RegExp(r'^[0-9]{10,}$');
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');

    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Geçerli bir telefon numarası girin';
    }

    return null;
  }
}
