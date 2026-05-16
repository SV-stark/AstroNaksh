import 'package:intl/intl.dart';

class AppFormatters {
  /// Format date as DD/MM/YYYY
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format time as hh:mm AM/PM
  static String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  /// Format date and time as DD/MM/YYYY, hh:mm AM/PM
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy, hh:mm a').format(dateTime);
  }

  /// Format time with seconds as hh:mm:ss AM/PM
  static String formatTimeWithSeconds(DateTime dateTime) {
    return DateFormat('hh:mm:ss a').format(dateTime);
  }

  /// Format date with day name as EEEE, dd/MM/YYYY
  static String formatDateWithDay(DateTime date) {
    return DateFormat('EEEE, dd/MM/yyyy').format(date);
  }

  /// Format day name only (e.g., Monday)
  static String formatDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }
}
