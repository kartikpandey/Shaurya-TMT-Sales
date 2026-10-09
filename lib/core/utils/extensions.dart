import 'package:flutter/material.dart';

extension StringExtensions on String {
  /// Capitalize first letter
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Check if valid email
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Check if valid phone number
  bool get isValidPhoneNumber {
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    return phoneRegex.hasMatch(replaceAll(RegExp(r'\D'), ''));
  }

  /// Remove all non-digit characters
  String get onlyDigits => replaceAll(RegExp(r'\D'), '');

  /// Truncate string with ellipsis
  String truncate(int length) {
    if (this.length <= length) return this;
    return '${substring(0, length)}...';
  }
}

extension NumExtensions on num {
  /// Convert to percentage string
  String toPercentage([int decimals = 1]) {
    return '${toStringAsFixed(decimals)}%';
  }

  /// Convert to compact format (1000 -> 1K)
  String toCompact() {
    if (this >= 1000000) {
      return '${(this / 1000000).toStringAsFixed(1)}M';
    } else if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(1)}K';
    }
    return toString();
  }
}

extension DateTimeExtensions on DateTime {
  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Check if date is within last 7 days
  bool get isWithinLastWeek {
    final lastWeek = DateTime.now().subtract(const Duration(days: 7));
    return isAfter(lastWeek);
  }

  /// Get day name
  String get dayName {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  /// Get month name
  String get monthName {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}

extension ContextExtensions on BuildContext {
  /// Get screen size
  Size get screenSize => MediaQuery.of(this).size;

  /// Get screen width
  double get screenWidth => screenSize.width;

  /// Get screen height
  double get screenHeight => screenSize.height;

  /// Check if screen is in portrait mode
  bool get isPortrait => screenSize.width < screenSize.height;

  /// Check if screen is in landscape mode
  bool get isLandscape => screenSize.width > screenSize.height;

  /// Check if device is mobile
  bool get isMobile => screenWidth < 600;

  /// Check if device is tablet
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;

  /// Get theme
  ThemeData get theme => Theme.of(this);

  /// Get text theme
  TextTheme get textTheme => theme.textTheme;

  /// Get color scheme
  ColorScheme get colorScheme => theme.colorScheme;

  /// Push to new screen
  Future<T?> pushTo<T>(Widget screen) {
    return Navigator.push<T>(this, MaterialPageRoute(builder: (_) => screen));
  }

  /// Push and replace
  Future<T?> pushReplaceTo<T>(Widget screen) {
    return Navigator.pushReplacement<T, T>(
      this,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  /// Pop current screen
  void pop<T>([T? result]) {
    Navigator.pop(this, result);
  }
}

extension WidgetExtensions on Widget {
  /// Add padding to widget
  Padding withPadding(EdgeInsets padding) =>
      Padding(padding: padding, child: this);

  /// Add box shadow
  DecoratedBox withShadow({
    Color color = const Color(0x1F000000),
    double blurRadius = 4,
    Offset offset = const Offset(0, 2),
  }) => DecoratedBox(
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(color: color, blurRadius: blurRadius, offset: offset),
      ],
    ),
    child: this,
  );
}
