import 'package:flutter/material.dart';

import '../models/fueling.dart';
import '../models/vehicle.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import 'dashboard_view.dart';
import 'fueling_form_screen.dart';
import 'vehicle_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  Future<bool> _confirm(String title, String message, String action) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _deleteVehicle(AppState state) async {
    final ok = await _confirm(
      'Excluir veículo',
      'O veículo e todos os abastecimentos associados serão removidos. Deseja continuar?',
      'Excluir',
    );
    if (ok) {
      await state.deleteVehicle();
      if (mounted) setState(() => _tab = 0);
    }
  }

  Future<void> _deleteFueling(AppState state, Fueling f) async {
    final ok = await _confirm(
      'Excluir abastecimento',
      'Remover o abastecimento de ${dateTimeFmt.format(f.dateTime)}?',
      'Excluir',
    );
    if (ok) await state.removeFueling(f.id);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final vehicle = state.vehicle;

    if (state.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Controle de Combustível')),
      body: vehicle == null
          ? _EmptyVehicle(
              onRegister: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VehicleFormScreen()),
              ),
            )
          : IndexedStack(
              index: _tab,
              children: [
                _FuelingsTab(
                  vehicle: vehicle,
                  metrics: state.metrics,
                  onDeleteVehicle: () => _deleteVehicle(state),
                  onDeleteFueling: (f) => _deleteFueling(state, f),
                ),
                DashboardView(metrics: state.metrics),
              ],
            ),
      floatingActionButton: vehicle != null && _tab == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FuelingFormScreen()),
              ),
              icon: const Icon(Icons.local_gas_station),
              label: const Text('Abastecer'),
            )
          : null,
      bottomNavigationBar: vehicle == null
          ? null
          : NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.list_alt),
                  label: 'Abastecimentos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.insights),
                  label: 'Dashboard',
                ),
              ],
            ),
    );
  }
}

class _EmptyVehicle extends StatelessWidget {
  const _EmptyVehicle({required this.onRegister});

  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_car,
                size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('Nenhum veículo cadastrado',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Cadastre seu veículo para registrar abastecimentos e acompanhar o consumo.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRegister,
              icon: const Icon(Icons.add),
              label: const Text('Cadastrar veículo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FuelingsTab extends StatelessWidget {
  const _FuelingsTab({
    required this.vehicle,
    required this.metrics,
    required this.onDeleteVehicle,
    required this.onDeleteFueling,
  });

  final Vehicle vehicle;
  final List<FuelingMetric> metrics;
  final VoidCallback onDeleteVehicle;
  final void Function(Fueling) onDeleteFueling;

  @override
  Widget build(BuildContext context) {
    final items = metrics.reversed.toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.directions_car, size: 32),
            title: Text('${vehicle.brand} ${vehicle.model}'),
            subtitle: Text(
                'Ano ${vehicle.year} • Motor ${num1.format(vehicle.engine)}L'),
            trailing: IconButton(
              tooltip: 'Excluir veículo',
              icon: const Icon(Icons.delete_outline),
              onPressed: onDeleteVehicle,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('Nenhum abastecimento registrado.')),
          ),
        for (final m in items) _FuelingTile(metric: m, onDelete: onDeleteFueling),
      ],
    );
  }
}

class _FuelingTile extends StatelessWidget {
  const _FuelingTile({required this.metric, required this.onDelete});

  final FuelingMetric metric;
  final void Function(Fueling) onDelete;

  @override
  Widget build(BuildContext context) {
    final f = metric.fueling;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${f.fuel.label} • ${brl.format(f.total)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Excluir abastecimento',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onDelete(f),
                ),
              ],
            ),
            Text(dateTimeFmt.format(f.dateTime)),
            Text(
              '${num2.format(f.liters)} L a ${brl.format(f.pricePerLiter)}/L • '
              '${num1.format(f.odometer)} km',
            ),
            const SizedBox(height: 8),
            if (metric.kmPerLiter != null)
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text('${num2.format(metric.kmPerLiter)} km/L')),
                  Chip(label: Text('${brl.format(metric.costPerKm)}/km')),
                  Chip(label: Text('${num1.format(metric.distance)} km rodados')),
                ],
              )
            else
              Text(
                'Sem indicadores (abastecimento de referência)',
                style: TextStyle(color: scheme.outline),
              ),
          ],
        ),
      ),
    );
  }
}
