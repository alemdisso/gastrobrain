class QuantityFormatter {
  static String format(double quantity) {
    if (quantity == quantity.toInt()) {
      return quantity.toInt().toString();
    } else {
      return quantity.toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
    }
  }
}