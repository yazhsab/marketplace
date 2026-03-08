import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension StringExtensions on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  String get toPrice {
    final number = double.tryParse(this);
    if (number == null) return this;
    return NumberFormat.currency(
            locale: 'en_IN', symbol: '\u20B9', decimalDigits: 2)
        .format(number);
  }

  String get toSlug {
    return toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'[\s]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }

  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  bool get isValidPhone {
    return RegExp(r'^[6-9]\d{9}$').hasMatch(this);
  }

  bool get isValidGst {
    return RegExp(
            r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$')
        .hasMatch(this);
  }

  bool get isValidPan {
    return RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(this);
  }
}

extension DoubleExtensions on double {
  String get toPrice {
    return NumberFormat.currency(
            locale: 'en_IN', symbol: '\u20B9', decimalDigits: 2)
        .format(this);
  }

  String get toCompactPrice {
    return NumberFormat.compactCurrency(
            locale: 'en_IN', symbol: '\u20B9', decimalDigits: 0)
        .format(this);
  }
}

extension NumExtensions on num {
  String get currencyFormat => NumberFormat.currency(
        locale: 'en_IN',
        symbol: '\u20B9',
        decimalDigits: 2,
      ).format(this);

  String get compactCurrency => NumberFormat.compactCurrency(
        locale: 'en_IN',
        symbol: '\u20B9',
        decimalDigits: 0,
      ).format(this);
}

extension DateTimeExtensions on DateTime {
  String get toFormattedDate {
    return DateFormat('dd MMM yyyy').format(this);
  }

  String get toFormattedDateTime {
    return DateFormat('dd MMM yyyy, hh:mm a').format(this);
  }

  String get toFormattedTime {
    return DateFormat('hh:mm a').format(this);
  }

  String get toApiDate {
    return DateFormat('yyyy-MM-dd').format(this);
  }

  String get toApiFormat {
    return toIso8601String();
  }

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  String get toTimeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}

extension TimeOfDayExtensions on TimeOfDay {
  String get formatted {
    final h = hourOfPeriod == 0 ? 12 : hourOfPeriod;
    final m = minute.toString().padLeft(2, '0');
    final p = period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  bool isAfterTime(TimeOfDay other) {
    return hour > other.hour ||
        (hour == other.hour && minute > other.minute);
  }
}

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? colorScheme.error : colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
