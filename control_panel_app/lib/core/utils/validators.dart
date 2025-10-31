class Validators {
  Validators._();

  static bool isValidEmail(String email) {
    // Simple email regex pattern
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  static bool isValidPassword(String password, {int minLength = 8}) {
    if (password.length < minLength) {
      return false;
    }
    // Add more password complexity rules if needed (e.g., uppercase, number, special char)
    // final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');
    // return passwordRegex.hasMatch(password);
    return true;
  }

  static bool isValidPhoneNumber(String phoneNumber) {
    // Example: YEMEN phone number format (967XXXXXXXXX)
    final phoneRegex = RegExp(r'^\+?967[0-9]{9}$');
    return phoneRegex.hasMatch(phoneNumber);
  }

  static bool isValidName(String name) {
    // Allows letters, spaces, and Arabic characters
    final nameRegex = RegExp(r'^[a-zA-Z\u0600-\u06FF\s]+$');
    return nameRegex.hasMatch(name);
  }

  static bool isNotEmpty(String? value) {
    return value != null && value.isNotEmpty;
  }

  static bool isAmountValid(String amount) {
    final amountRegex = RegExp(
        r'^\d+(\.\d{1,2})?$'); // Allows integers or decimals with 1 or 2 places
    return amountRegex.hasMatch(amount);
  }

  // Add other validation methods as needed

  // Form field validators (to be used directly as TextFormField.validator)
  static String? Function(String?) get validateName => (String? value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) {
          return 'مطلوب';
        }
        if (!isValidName(trimmed)) {
          return 'اسم غير صحيح';
        }
        return null;
      };

  static String? Function(String?) get validateEmail => (String? value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) {
          return 'مطلوب';
        }
        if (!isValidEmail(trimmed)) {
          return 'بريد غير صحيح';
        }
        return null;
      };

  static String? Function(String?) get validatePassword => (String? value) {
        final raw = value ?? '';
        if (raw.isEmpty) {
          return 'مطلوب';
        }
        if (!isValidPassword(raw, minLength: 8)) {
          return '8 أحرف على الأقل';
        }
        return null;
      };

  static String? Function(String?) get validatePhone => (String? value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) {
          return 'مطلوب';
        }
        // Accept both with and without leading '+'. Normalize before validating.
        final normalized = trimmed.startsWith('+') ? trimmed : '+$trimmed';
        if (!isValidPhoneNumber(normalized)) {
          return 'رقم غير صحيح';
        }
        return null;
      };
}
