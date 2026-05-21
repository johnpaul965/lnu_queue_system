// lib/core/utils/validators.dart

class LNUValidators {
  // Student ID: exactly 7 digits
  static String? studentId(String? v) {
    if (v == null || v.isEmpty) return 'Student ID is required';
    final re = RegExp(r'^\d{7}$');
    if (!re.hasMatch(v)) return 'Student ID must be exactly 7 digits';
    return null;
  }

  // Password: min 8, must have uppercase, lowercase, number, special char
  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'At least 8 characters';
    if (v.length > 64) return 'Maximum 64 characters';
    if (!v.contains(RegExp(r'[A-Z]'))) return 'At least one uppercase letter';
    if (!v.contains(RegExp(r'[a-z]'))) return 'At least one lowercase letter';
    if (!v.contains(RegExp(r'[0-9]'))) return 'At least one number';
    if (!v.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) return 'At least one special character';
    return null;
  }

  // Full name: letters and spaces only, 2–100 chars
  static String? fullName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Full name is required';
    if (v.trim().length < 2) return 'At least 2 characters';
    if (v.length > 100) return 'Maximum 100 characters';
    if (!RegExp(r"^[a-zA-Z\s\.\-'ÑñÁáÉéÍíÓóÚú]+$").hasMatch(v.trim()))
      return 'Letters and spaces only';
    return null;
  }

  // Email: must be valid
  static String? email(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    final re = RegExp(r'^[\w.+\-]+@[\w\-]+\.[\w.]{2,}$', caseSensitive: false);
    if (!re.hasMatch(v)) return 'Enter a valid email address';
    if (v.length > 254) return 'Email too long';
    return null;
  }

  // Receipt number: 6–20 alphanumeric characters
  static String? receiptNumber(String? v) {
    if (v == null || v.isEmpty) return 'Receipt number is required';
    if (!RegExp(r'^[A-Za-z0-9\-]{6,20}$').hasMatch(v))
      return '6–20 alphanumeric characters only';
    return null;
  }

  // Purpose: optional but limited
  static String? purpose(String? v) {
    if (v != null && v.length > 500) return 'Maximum 500 characters';
    return null;
  }
}