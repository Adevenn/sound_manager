extension StringExtension on String {
  ///Upper case the first character
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}