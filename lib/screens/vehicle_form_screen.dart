import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../services/fipe_service.dart';
import '../state/app_state.dart';
import '../utils/format.dart';

class VehicleFormScreen extends StatefulWidget {
  const VehicleFormScreen({super.key});

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = FipeService();
  final _yearC = TextEditingController();
  final _engineC = TextEditingController();

  List<FipeItem> _brands = [];
  List<String> _models = [];
  FipeItem? _brand;
  String? _model;

  bool _loadingBrands = true;
  bool _loadingModels = false;
  String? _apiError;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  @override
  void dispose() {
    _yearC.dispose();
    _engineC.dispose();
    super.dispose();
  }

  Future<void> _loadBrands() async {
    setState(() {
      _loadingBrands = true;
      _apiError = null;
    });
    try {
      final brands = await _service.brands();
      if (!mounted) return;
      setState(() => _brands = brands);
    } catch (_) {
      if (!mounted) return;
      setState(() => _apiError = 'Não foi possível carregar as marcas.');
    } finally {
      if (mounted) setState(() => _loadingBrands = false);
    }
  }

  Future<void> _onBrandSelected(FipeItem? brand) async {
    if (brand == null) return;
    setState(() {
      _brand = brand;
      _model = null;
      _models = [];
      _loadingModels = true;
      _apiError = null;
    });
    try {
      final models = await _service.models(brand.code);
      if (!mounted || _brand != brand) return;
      setState(() => _models = models);
    } catch (_) {
      if (!mounted) return;
      setState(() => _apiError = 'Não foi possível carregar os modelos.');
    } finally {
      if (mounted) setState(() => _loadingModels = false);
    }
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    final valid = _formKey.currentState!.validate();
    if (!valid || _brand == null || _model == null) return;

    final vehicle = Vehicle(
      brand: _brand!.name,
      model: _model!,
      year: int.parse(_yearC.text.trim()),
      engine: parseNum(_engineC.text)!,
    );
    await AppScope.of(context).saveVehicle(vehicle);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;

    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar veículo')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_apiError != null)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: ListTile(
                  leading: const Icon(Icons.error_outline),
                  title: Text(_apiError!),
                  trailing: TextButton(
                    onPressed:
                        _brand == null ? _loadBrands : () => _onBrandSelected(_brand),
                    child: const Text('Tentar de novo'),
                  ),
                ),
              ),
            if (_loadingBrands) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            DropdownMenu<FipeItem>(
              width: MediaQuery.of(context).size.width - 32,
              label: const Text('Marca'),
              enabled: !_loadingBrands && _brands.isNotEmpty,
              enableFilter: true,
              requestFocusOnTap: true,
              menuHeight: 300,
              errorText:
                  _submitted && _brand == null ? 'Selecione a marca' : null,
              dropdownMenuEntries: [
                for (final b in _brands)
                  DropdownMenuEntry(value: b, label: b.name),
              ],
              onSelected: _onBrandSelected,
            ),
            const SizedBox(height: 16),
            if (_loadingModels) const LinearProgressIndicator(),
            DropdownMenu<String>(
              key: ValueKey(_brand?.code),
              width: MediaQuery.of(context).size.width - 32,
              label: const Text('Modelo'),
              enabled: !_loadingModels && _models.isNotEmpty,
              enableFilter: true,
              requestFocusOnTap: true,
              menuHeight: 300,
              errorText:
                  _submitted && _model == null ? 'Selecione o modelo' : null,
              dropdownMenuEntries: [
                for (final m in _models) DropdownMenuEntry(value: m, label: m),
              ],
              onSelected: (m) => setState(() => _model = m),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _yearC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ano',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final year = int.tryParse((v ?? '').trim());
                if (year == null || year < 1950 || year > currentYear + 1) {
                  return 'Informe um ano entre 1950 e ${currentYear + 1}';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _engineC,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Cilindrada do motor (L)',
                hintText: 'Ex.: 1.0',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final n = parseNum(v);
                if (n == null || n < 0.5 || n > 12) {
                  return 'Informe a cilindrada em litros (ex.: 1.6)';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Salvar veículo'),
            ),
          ],
        ),
      ),
    );
  }
}
