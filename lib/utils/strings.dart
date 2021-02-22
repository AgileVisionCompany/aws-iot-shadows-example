

extension StringUtils on String {
  String capitalizeFirstLetter() {
    if (isEmpty) return "";
    return substring(0, 1).toUpperCase() + substring(1);
  }
}