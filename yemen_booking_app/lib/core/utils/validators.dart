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
    final amountRegex = RegExp(r'^\d+(\.\d{1,2})?$'); // Allows integers or decimals with 1 or 2 places
    return amountRegex.hasMatch(amount);
  }
  
  // Add other validation methods as needed
}