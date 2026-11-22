enum FuelType {
  etanol('Etanol'),
  gasolina('Gasolina'),
  diesel('Diesel');

  final String label;
  const FuelType(this.label);
}

class Fueling {
  final String id;
  final FuelType fuel;
  final double pricePerLiter;
  final double odometer;
  final double liters;
  final DateTime dateTime;

  const Fueling({
    required this.id,
    required this.fuel,
    required this.pricePerLiter,
    required this.odometer,
    required this.liters,
    required this.dateTime,
  });

  double get total => pricePerLiter * liters;

  Map<String, dynamic> toJson() => {
        'id': id,
        'fuel': fuel.name,
        'pricePerLiter': pricePerLiter,
        'odometer': odometer,
        'liters': liters,
        'dateTime': dateTime.toIso8601String(),
      };

  factory Fueling.fromJson(Map<String, dynamic> json) => Fueling(
        id: json['id'] as String,
        fuel: FuelType.values.byName(json['fuel'] as String),
        pricePerLiter: (json['pricePerLiter'] as num).toDouble(),
        odometer: (json['odometer'] as num).toDouble(),
        liters: (json['liters'] as num).toDouble(),
        dateTime: DateTime.parse(json['dateTime'] as String),
      );
}

class FuelingMetric {
  final Fueling fueling;
  final double? distance;
  final double? kmPerLiter;
  final double? costPerKm;

  const FuelingMetric({
    required this.fueling,
    this.distance,
    this.kmPerLiter,
    this.costPerKm,
  });
}

/// [sorted] deve estar em ordem cronológica crescente.
List<FuelingMetric> computeMetrics(List<Fueling> sorted) {
  final result = <FuelingMetric>[];
  for (var i = 0; i < sorted.length; i++) {
    final cur = sorted[i];
    if (i == 0) {
      result.add(FuelingMetric(fueling: cur));
      continue;
    }
    final distance = cur.odometer - sorted[i - 1].odometer;
    if (distance <= 0 || cur.liters <= 0) {
      result.add(FuelingMetric(fueling: cur));
      continue;
    }
    result.add(FuelingMetric(
      fueling: cur,
      distance: distance,
      kmPerLiter: distance / cur.liters,
      costPerKm: cur.total / distance,
    ));
  }
  return result;
}
