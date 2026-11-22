import 'package:controle_combustivel/models/fueling.dart';
import 'package:flutter_test/flutter_test.dart';

Fueling _f(String id, double km, double liters, double price, int day) => Fueling(
      id: id,
      fuel: FuelType.gasolina,
      pricePerLiter: price,
      odometer: km,
      liters: liters,
      dateTime: DateTime(2026, 1, day),
    );

void main() {
  test('primeiro abastecimento não tem indicadores', () {
    final m = computeMetrics([_f('1', 1000, 40, 6, 1)]);
    expect(m.single.kmPerLiter, isNull);
    expect(m.single.costPerKm, isNull);
  });

  test('calcula km/L e R\$/km a partir do segundo abastecimento', () {
    final m = computeMetrics([
      _f('1', 1000, 40, 6, 1),
      _f('2', 1400, 40, 6, 10),
    ]);
    expect(m[1].distance, 400);
    expect(m[1].kmPerLiter, 10);
    expect(m[1].costPerKm, closeTo(0.6, 1e-9));
    expect(m[1].fueling.total, 240);
  });
}
