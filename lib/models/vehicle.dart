class Vehicle {
  final String brand;
  final String model;
  final int year;
  final double engine;

  const Vehicle({
    required this.brand,
    required this.model,
    required this.year,
    required this.engine,
  });

  Map<String, dynamic> toJson() => {
        'brand': brand,
        'model': model,
        'year': year,
        'engine': engine,
      };

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        brand: json['brand'] as String,
        model: json['model'] as String,
        year: json['year'] as int,
        engine: (json['engine'] as num).toDouble(),
      );
}
