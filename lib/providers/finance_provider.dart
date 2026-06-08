import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

class FinanceProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final NotificationService _notifications = NotificationService();

  FinanceData _data = FinanceData();
  bool _carregando = true;
  int _ano = DateTime.now().year;
  int _mes = DateTime.now().month;

  // ---------- Estado geral ----------

  bool get carregando => _carregando;
  int get anoAtual => _ano;
  int get mesAtual => _mes;
  DateTime get dataMesAtual => DateTime(_ano, _mes);
  FinanceData get data => _data;
  TemplateData get template => _data.template;

  bool get ehMesPresente {
    final agora = DateTime.now();
    return _ano == agora.year && _mes == agora.month;
  }

  bool get podeIrProximoMes => !ehMesPresente;

  String get _chaveAtual => '$_ano-${_mes.toString().padLeft(2, '0')}';

  // Retorna o mês corrente somente para leitura (null = sem dados ainda).
  MonthData? get _mesR => _data.meses[_chaveAtual];

  // Retorna o mês corrente para escrita, criando-o a partir do template se
  // ainda não existir.
  MonthData get _mesW => _data.meses.putIfAbsent(
    _chaveAtual,
    () => _data.template.aplicarPara(_ano, _mes),
  );

  MonthData get mesAtualData => _mesW;

  List<String> get mesesComDados {
    final set = <String>{..._data.meses.keys, _chaveAtual};
    return set.toList()..sort();
  }

  // ---------- Navegação de meses ----------

  void mesAnterior() {
    final d = DateTime(_ano, _mes - 1);
    _ano = d.year;
    _mes = d.month;
    notifyListeners();
  }

  void proximoMes() {
    if (!podeIrProximoMes) return;
    final d = DateTime(_ano, _mes + 1);
    _ano = d.year;
    _mes = d.month;
    notifyListeners();
  }

  void irParaMes(int ano, int mes) {
    _ano = ano;
    _mes = mes;
    notifyListeners();
  }

  // ---------- Getters do mês atual ----------

  List<ExpenseEntry> get gastosGerais => _mesR?.gastosGerais ?? [];
  List<ExpenseEntry> get alimentacao {
    final lista = [...?_mesR?.alimentacao];
    lista.sort((a, b) => (a.data ?? DateTime(0)).compareTo(b.data ?? DateTime(0)));
    return lista;
  }

  List<ExpenseEntry> get gastosExtras {
    final lista = [...?_mesR?.gastosExtras];
    lista.sort((a, b) => (a.data ?? DateTime(0)).compareTo(b.data ?? DateTime(0)));
    return lista;
  }
  List<TransportEntry> get transporte => _mesR?.transporte ?? [];
  List<IncomeEntry> get entradas => _mesR?.entradas ?? [];
  List<AlertConfig> get alertas => _data.alertas;

  double get orcamentoAlimentacao => _mesR?.orcamentoAlimentacao ?? 0;
  double get orcamentoTransporte => _mesR?.orcamentoTransporte ?? 0;
  double get orcamentoGastosExtras => _mesR?.orcamentoGastosExtras ?? 0;

  // ---------- Totais ----------

  double get totalGastosGerais =>
      (_mesR?.gastosGerais ?? []).fold(0.0, (s, e) => s + e.valor);
  double get totalAlimentacao =>
      (_mesR?.alimentacao ?? []).fold(0.0, (s, e) => s + e.valor);
  double get totalGastosExtras =>
      (_mesR?.gastosExtras ?? []).fold(0.0, (s, e) => s + e.valor);
  double get totalTransporte =>
      (_mesR?.transporte ?? []).fold(0.0, (s, e) => s + e.total);
  double get totalSaidas =>
      totalGastosGerais + totalAlimentacao + totalGastosExtras + totalTransporte;
  double get totalEntradas =>
      (_mesR?.entradas ?? []).fold(0.0, (s, e) => s + e.valor);

  // Orçamentos definidos (alimentação + transporte + extras)
  double get totalOrcamentos =>
      orcamentoAlimentacao + orcamentoTransporte + orcamentoGastosExtras;

  // Comprometido = gastos fixos do mês + orçamentos das categorias variáveis.
  double get totalComprometido => totalGastosGerais + totalOrcamentos;

  // Disponível: o que sobra das entradas após comprometer tudo.
  double get totalDisponivel => totalEntradas - totalComprometido;

  double get percentualPago {
    final total = gastosGerais.length;
    if (total <= 0) return 0;
    final pago = gastosGerais.where((e) => e.pago).length;
    return (pago / total).clamp(0.0, 1.0);
  }

  // ---------- Inicialização ----------

  Future<void> inicializar() async {
    _data = await _storage.carregar();
    _carregando = false;
    notifyListeners();
    await _notifications.reagendarTodos(_data.alertas);
  }

  Future<void> _persistir() async {
    notifyListeners();
    await _storage.salvar(_data);
  }

  String _novoId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${gastosGerais.length + alimentacao.length + transporte.length}';

  // ---------- Orçamento das categorias variáveis ----------

  void definirOrcamento(Categoria cat, double valor) {
    switch (cat) {
      case Categoria.alimentacao:
        _mesW.orcamentoAlimentacao = valor;
      case Categoria.transporte:
        _mesW.orcamentoTransporte = valor;
      case Categoria.gastosExtras:
        _mesW.orcamentoGastosExtras = valor;
      case Categoria.gastosGerais:
        break;
    }
    _persistir();
  }

  // ---------- Helpers internos ----------

  List<ExpenseEntry> _listaDespesaLeitura(Categoria cat) {
    switch (cat) {
      case Categoria.gastosGerais:
        return _mesR?.gastosGerais ?? [];
      case Categoria.alimentacao:
        return _mesR?.alimentacao ?? [];
      case Categoria.gastosExtras:
        return _mesR?.gastosExtras ?? [];
      case Categoria.transporte:
        throw ArgumentError('Transporte usa TransportEntry');
    }
  }

  List<ExpenseEntry> _listaDespesaEscrita(Categoria cat) {
    switch (cat) {
      case Categoria.gastosGerais:
        return _mesW.gastosGerais;
      case Categoria.alimentacao:
        return _mesW.alimentacao;
      case Categoria.gastosExtras:
        return _mesW.gastosExtras;
      case Categoria.transporte:
        throw ArgumentError('Transporte usa TransportEntry');
    }
  }

  // ---------- CRUD despesas comuns ----------

  void adicionarDespesa(
    Categoria cat, {
    required String tipo,
    required double valor,
    DateTime? data,
    bool pago = false,
  }) {
    _listaDespesaEscrita(cat).add(
      ExpenseEntry(
        id: _novoId(),
        tipo: tipo,
        valor: valor,
        data: data,
        pago: pago,
      ),
    );
    _persistir();
  }

  void atualizarDespesa(
    Categoria cat,
    String id, {
    String? tipo,
    double? valor,
    DateTime? data,
    bool? pago,
  }) {
    final item = _listaDespesaLeitura(cat).firstWhere((e) => e.id == id);
    if (tipo != null) item.tipo = tipo;
    if (valor != null) item.valor = valor;
    if (data != null) item.data = data;
    if (pago != null) item.pago = pago;
    _persistir();
  }

  void alternarPago(Categoria cat, String id) {
    final item = _listaDespesaLeitura(cat).firstWhere((e) => e.id == id);
    item.pago = !item.pago;
    _persistir();
  }

  void removerDespesa(Categoria cat, String id) {
    _listaDespesaLeitura(cat).removeWhere((e) => e.id == id);
    _persistir();
  }

  // ---------- CRUD transporte ----------

  void adicionarTransporte({
    required String tipo,
    int quantidade = 1,
    required double valorUnitario,
    DateTime? data,
  }) {
    _mesW.transporte.add(
      TransportEntry(
        id: _novoId(),
        tipo: tipo,
        quantidade: quantidade,
        valorUnitario: valorUnitario,
        data: data,
      ),
    );
    _persistir();
  }

  void atualizarTransporte(
    String id, {
    String? tipo,
    int? quantidade,
    double? valorUnitario,
    DateTime? data,
  }) {
    final item =
        (_mesR?.transporte ?? []).firstWhere((e) => e.id == id);
    if (tipo != null) item.tipo = tipo;
    if (quantidade != null) item.quantidade = quantidade;
    if (valorUnitario != null) item.valorUnitario = valorUnitario;
    if (data != null) item.data = data;
    _persistir();
  }

  void incrementarQuantidade(String id) {
    final item =
        (_mesR?.transporte ?? []).firstWhere((e) => e.id == id);
    item.quantidade++;
    _persistir();
  }

  void decrementarQuantidade(String id) {
    final item =
        (_mesR?.transporte ?? []).firstWhere((e) => e.id == id);
    if (item.quantidade > 0) item.quantidade--;
    _persistir();
  }

  void removerTransporte(String id) {
    _mesR?.transporte.removeWhere((e) => e.id == id);
    _persistir();
  }

  // ---------- CRUD entradas ----------

  void adicionarEntrada({
    required String descricao,
    required double valor,
    DateTime? data,
  }) {
    _mesW.entradas.add(
      IncomeEntry(
        id: _novoId(),
        descricao: descricao,
        valor: valor,
        data: data ?? DateTime.now(),
      ),
    );
    _persistir();
  }

  void atualizarEntrada(
    String id, {
    String? descricao,
    double? valor,
    DateTime? data,
  }) {
    final item =
        (_mesR?.entradas ?? []).firstWhere((e) => e.id == id);
    if (descricao != null) item.descricao = descricao;
    if (valor != null) item.valor = valor;
    if (data != null) item.data = data;
    _persistir();
  }

  void removerEntrada(String id) {
    _mesR?.entradas.removeWhere((e) => e.id == id);
    _persistir();
  }

  // ---------- Alertas ----------

  Future<void> adicionarAlerta(AlertConfig alerta) async {
    _data.alertas.add(alerta);
    await _persistir();
    await _notifications.agendar(alerta);
  }

  Future<void> atualizarAlerta(AlertConfig alerta) async {
    final idx = _data.alertas.indexWhere((a) => a.id == alerta.id);
    if (idx >= 0) _data.alertas[idx] = alerta;
    await _persistir();
    await _notifications.cancelar(alerta);
    if (alerta.ativo) await _notifications.agendar(alerta);
  }

  Future<void> removerAlerta(int id) async {
    final alerta = _data.alertas.firstWhere((a) => a.id == id);
    _data.alertas.removeWhere((a) => a.id == id);
    await _persistir();
    await _notifications.cancelar(alerta);
  }

  // ---------- Template ----------

  void atualizarTemplate(TemplateData novo) {
    _data = FinanceData(
      meses: _data.meses,
      alertas: _data.alertas,
      template: novo,
    );
    _persistir();
  }

  // ---------- Importação ----------

  Future<void> importar(FinanceData novos) async {
    _data = novos;
    await _persistir();
    await _notifications.reagendarTodos(_data.alertas);
  }
}
