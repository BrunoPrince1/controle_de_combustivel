import 'dart:convert';

import 'package:http/http.dart' as http;

class FipeItem {
  final String code;
  final String name;
  const FipeItem({required this.code, required this.name});
}

/// Consulta marcas e modelos de carros na BrasilAPI (tabela FIPE).
class FipeService {
  static const _base = 'https://brasilapi.com.br/api/fipe';

  final http.Client _client;
  FipeService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<FipeItem>> brands() async {
    final data = await _get('$_base/marcas/v1/carros');
    final items = data
        .whereType<Map<String, dynamic>>()
        .map((m) => FipeItem(code: '${m['valor']}', name: '${m['nome']}'))
        .toList();
    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }

  Future<List<String>> models(String brandCode) async {
    final data = await _get('$_base/veiculos/v1/carros/$brandCode');
    final names = <String>{};
    for (final m in data.whereType<Map<String, dynamic>>()) {
      final name = m['modelo'] ?? m['nome'] ?? m['name'];
      if (name != null) names.add('$name');
    }
    final list = names.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  Future<List<dynamic>> _get(String url) async {
    final response =
        await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Erro ${response.statusCode} ao consultar a API');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
  }
}
