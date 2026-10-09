import 'package:intl/intl.dart';

class AppFormatters {
  /// Format currency (Indian Rupees)
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Format number with commas
  static String formatNumber(num number) {
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    return formatter.format(number);
  }

  /// Format large numbers (e.g., 1000 -> 1K)
  static String formatCompactNumber(num number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  /// Format date to readable format
  static String formatDate(DateTime date, [String format = 'dd MMM, yyyy']) {
    return DateFormat(format).format(date);
  }

  /// Format time
  static String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  /// Format date and time
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM, yyyy hh:mm a').format(dateTime);
  }

  /// Format relative time (e.g., "2 hours ago")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return formatDate(dateTime);
    }
  }

  /// Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Format phone number
  static String formatPhoneNumber(String phoneNumber) {
    final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
    }
    return phoneNumber;
  }

  /// Format product size with unit
  static String formatProductSize(String size) {
    return 'ShauryaTMT $size';
  }

  /// Format order ID
  static String formatOrderId(String id) {
    return 'ORD-${id.substring(0, 8).toUpperCase()}';
  }
}
