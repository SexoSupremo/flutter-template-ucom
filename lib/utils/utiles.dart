import 'package:intl/intl.dart';

class UtilesApp {
  /// Retorna la fecha en formato dd-MM-yyyy
  static String formatearFechaDdMMAaaa(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anho = fecha.year.toString();
    return '$dia-$mes-$anho';
  }

  static String formatearGuaranies(num monto) {
    final formatter = NumberFormat.currency(
      locale: 'es_PY',
      symbol: '₲',
      decimalDigits: 0,
    );
    return formatter.format(monto);
  }
}
