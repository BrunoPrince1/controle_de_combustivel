import 'package:flutter/widgets.dart';

import '../models/fueling.dart';
import '../models/vehicle.dart';
import '../services/storage_service.dart';
import '../utils/format.dart';

class AppState extends ChangeNotifier {
  AppState(this._storage);

  final StorageService _storage;

  bool loading = true;
  Vehicle? vehicle;
  List<Fueling> _fuelings = [];

  List<Fueling> get fuelings => List.unmodifiable(_fuelings);
  List<FuelingMetric> get metrics => computeMetrics(_fuelings);

  Future<void> load() async {
    final (v, f) = await _storage.load();
    vehicle = v;
    _fuelings = f..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    loading = false;
    notifyListeners();
  }

  Future<void> saveVehicle(Vehicle v) async {
    vehicle = v;
    await _storage.saveVehicle(v);
    notifyListeners();
  }

  Future<void> deleteVehicle() async {
    vehicle = null;
    _fuelings = [];
    await _storage.clear();
    notifyListeners();
  }

  Future<void> addFueling(Fueling f) async {
    _fuelings = [..._fuelings, f]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    await _storage.saveFuelings(_fuelings);
    notifyListeners();
  }

  Future<void> removeFueling(String id) async {
    _fuelings = _fuelings.where((f) => f.id != id).toList();
    await _storage.saveFuelings(_fuelings);
    notifyListeners();
  }

  /// A quilometragem deve crescer junto com a data dos abastecimentos.
  String? validateOdometer(double km, DateTime date) {
    Fueling? previous;
    Fueling? next;
    for (final f in _fuelings) {
      if (!f.dateTime.isAfter(date)) {
        previous = f;
      } else {
        next ??= f;
      }
    }
    if (previous != null && km <= previous.odometer) {
      return 'Deve ser maior que ${num1.format(previous.odometer)} km (abastecimento anterior)';
    }
    if (next != null && km >= next.odometer) {
      return 'Deve ser menor que ${num1.format(next.odometer)} km (abastecimento seguinte)';
    }
    return null;
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
  }
}
