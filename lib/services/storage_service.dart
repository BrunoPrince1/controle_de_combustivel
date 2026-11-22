import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/fueling.dart';
import '../models/vehicle.dart';

class StorageService {
  static const _vehicleKey = 'vehicle';
  static const _fuelingsKey = 'fuelings';

  Future<(Vehicle?, List<Fueling>)> load() async {
    final prefs = await SharedPreferences.getInstance();

    Vehicle? vehicle;
    final vehicleRaw = prefs.getString(_vehicleKey);
    if (vehicleRaw != null) {
      vehicle = Vehicle.fromJson(jsonDecode(vehicleRaw) as Map<String, dynamic>);
    }

    final fuelings = <Fueling>[];
    final fuelingsRaw = prefs.getString(_fuelingsKey);
    if (fuelingsRaw != null) {
      for (final item in jsonDecode(fuelingsRaw) as List<dynamic>) {
        fuelings.add(Fueling.fromJson(item as Map<String, dynamic>));
      }
    }
    return (vehicle, fuelings);
  }

  Future<void> saveVehicle(Vehicle vehicle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_vehicleKey, jsonEncode(vehicle.toJson()));
  }

  Future<void> saveFuelings(List<Fueling> fuelings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _fuelingsKey,
      jsonEncode(fuelings.map((f) => f.toJson()).toList()),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_vehicleKey);
    await prefs.remove(_fuelingsKey);
  }
}
