import 'package:intl/intl.dart';

final brl = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
final dateTimeFmt = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
final shortDateFmt = DateFormat('dd/MM', 'pt_BR');
final num2 = NumberFormat('#,##0.00', 'pt_BR');
final num1 = NumberFormat('#,##0.0', 'pt_BR');

double? parseNum(String? s) {
  if (s == null) return null;
  return double.tryParse(s.trim().replaceAll(',', '.'));
}
