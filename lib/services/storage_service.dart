import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Responsável por gravar e ler os dados no armazenamento local do aparelho.
///
/// Usa [SharedPreferences], que persiste em disco — os dados continuam
/// salvos mesmo que o usuário feche o app ou reinicie o celular.
class StorageService {
  static const String _chave = 'finance_data_v1';

  Future<FinanceData> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_chave);
    if (raw == null || raw.isEmpty) {
      // Primeira execução: começa com os dados de exemplo da planilha.
      final inicial = FinanceData.exemplo();
      await salvar(inicial);
      return inicial;
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return FinanceData.fromJson(map);
    } catch (_) {
      return FinanceData();
    }
  }

  Future<void> salvar(FinanceData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chave, jsonEncode(data.toJson()));
  }

  Future<void> limpar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chave);
  }
}
