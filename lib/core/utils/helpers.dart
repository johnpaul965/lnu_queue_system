// lib/core/utils/helpers.dart
import 'package:intl/intl.dart';

class AppHelpers {
  static String formatDate(String? isoDate) {
    if (isoDate == null) return '—';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('MMM d, yyyy h:mm a').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  static String formatShortDate(String? isoDate) {
    if (isoDate == null) return '—';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  static String formatCurrency(num? amount) {
    if (amount == null) return '₱0.00';
    return '₱${amount.toStringAsFixed(2)}';
  }

  static String statusLabel(String status) => switch (status) {
    'SUBMITTED'        => 'Submitted',
    'UNDER_REVIEW'     => 'Under Review',
    'INCOMPLETE'       => 'Incomplete',
    'FOR_PAYMENT'      => 'For Payment',
    'PAYMENT_VERIFIED' => 'Payment Verified',
    'PROCESSING'       => 'Processing',
    'FOR_CLAIMING'     => 'Ready for Pickup',
    'COMPLETED'        => 'Completed',
    'REJECTED'         => 'Rejected',
    _ => status,
  };
}
