import 'package:flutter/material.dart';

import '../models/fueling.dart';
import '../state/app_state.dart';
import '../utils/format.dart';

class FuelingFormScreen extends StatefulWidget {
  const FuelingFormScreen({super.key});

  @override
  State<FuelingFormScreen> createState() => _FuelingFormScreenState();
}

class _FuelingFormScreenState extends State<FuelingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceC = TextEditingController();
  final _odometerC = TextEditingController();
  final _litersC = TextEditingController();

  FuelType _fuel = FuelType.gasolina;
  DateTime _dateTime = DateTime.now();

  @override
  void dispose() {
    _priceC.dispose();
    _odometerC.dispose();
    _litersC.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (time == null) return;
    setState(() {
      _dateTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  String? _positive(String? v, String label) {
    final n = parseNum(v);
    if (n == null || n <= 0) return 'Informe $label válido';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final state = AppScope.of(context);
    await state.addFueling(Fueling(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      fuel: _fuel,
      pricePerLiter: parseNum(_priceC.text)!,
      odometer: parseNum(_odometerC.text)!,
      liters: parseNum(_litersC.text)!,
      dateTime: _dateTime,
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    const decimal = TextInputType.numberWithOptions(decimal: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Novo abastecimento')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<FuelType>(
              segments: [
                for (final t in FuelType.values)
                  ButtonSegment(value: t, label: Text(t.label)),
              ],
              selected: {_fuel},
              onSelectionChanged: (s) => setState(() => _fuel = s.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceC,
              keyboardType: decimal,
              decoration: const InputDecoration(
                labelText: 'Preço por litro (R\$)',
                border: OutlineInputBorder(),
              ),
              validator: (v) => _positive(v, 'um preço'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _litersC,
              keyboardType: decimal,
              decoration: const InputDecoration(
                labelText: 'Litros abastecidos',
                border: OutlineInputBorder(),
              ),
              validator: (v) => _positive(v, 'a quantidade de litros'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _odometerC,
              keyboardType: decimal,
              decoration: const InputDecoration(
                labelText: 'Quilometragem atual (km)',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final error = _positive(v, 'a quilometragem');
                if (error != null) return error;
                return state.validateOdometer(parseNum(v)!, _dateTime);
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickDateTime,
              icon: const Icon(Icons.event),
              label: Text(dateTimeFmt.format(_dateTime)),
            ),
            const SizedBox(height: 16),
            ListenableBuilder(
              listenable: Listenable.merge([_priceC, _litersC]),
              builder: (context, _) {
                final price = parseNum(_priceC.text);
                final liters = parseNum(_litersC.text);
                final total =
                    (price != null && liters != null) ? price * liters : null;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.payments_outlined),
                    title: const Text('Valor total'),
                    trailing: Text(
                      total == null ? '—' : brl.format(total),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Salvar abastecimento'),
            ),
          ],
        ),
      ),
    );
  }
}
