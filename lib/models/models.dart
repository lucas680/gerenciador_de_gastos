library;

enum Categoria { gastosGerais, alimentacao, gastosExtras, transporte }

extension CategoriaInfo on Categoria {
  String get titulo {
    switch (this) {
      case Categoria.gastosGerais:
        return 'Gastos gerais';
      case Categoria.alimentacao:
        return 'Alimentação';
      case Categoria.gastosExtras:
        return 'Gastos extras';
      case Categoria.transporte:
        return 'Transporte';
    }
  }
}

class ExpenseEntry {
  String id;
  String tipo;
  DateTime? data;
  double valor;
  bool pago;

  ExpenseEntry({
    required this.id,
    required this.tipo,
    this.data,
    this.valor = 0,
    this.pago = false,
  });

  ExpenseEntry copyWith({String? id, bool resetPago = false}) => ExpenseEntry(
    id: id ?? this.id,
    tipo: tipo,
    data: data,
    valor: valor,
    pago: resetPago ? false : pago,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tipo': tipo,
    'data': data?.toIso8601String(),
    'valor': valor,
    'pago': pago,
  };

  factory ExpenseEntry.fromJson(Map<String, dynamic> json) => ExpenseEntry(
    id: json['id'] as String,
    tipo: json['tipo'] as String? ?? '',
    data: (json['data'] as String?) != null
        ? DateTime.tryParse(json['data'] as String)
        : null,
    valor: (json['valor'] as num?)?.toDouble() ?? 0,
    pago: json['pago'] as bool? ?? false,
  );
}

class TransportEntry {
  String id;
  String tipo;
  int quantidade;
  double valorUnitario;
  DateTime? data;

  TransportEntry({
    required this.id,
    required this.tipo,
    this.quantidade = 1,
    this.valorUnitario = 0,
    this.data,
  });

  double get total => quantidade * valorUnitario;

  Map<String, dynamic> toJson() => {
    'id': id,
    'tipo': tipo,
    'quantidade': quantidade,
    'valorUnitario': valorUnitario,
    'data': data?.toIso8601String(),
  };

  factory TransportEntry.fromJson(Map<String, dynamic> json) => TransportEntry(
    id: json['id'] as String,
    tipo: json['tipo'] as String? ?? '',
    quantidade: (json['quantidade'] as num?)?.toInt() ?? 1,
    valorUnitario: (json['valorUnitario'] as num?)?.toDouble() ?? 0,
    data: (json['data'] as String?) != null
        ? DateTime.tryParse(json['data'] as String)
        : null,
  );
}

class IncomeEntry {
  String id;
  String descricao;
  double valor;
  DateTime data;

  IncomeEntry({
    required this.id,
    required this.descricao,
    this.valor = 0,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'descricao': descricao,
    'valor': valor,
    'data': data.toIso8601String(),
  };

  factory IncomeEntry.fromJson(Map<String, dynamic> json) => IncomeEntry(
    id: json['id'] as String,
    descricao: json['descricao'] as String? ?? '',
    valor: (json['valor'] as num?)?.toDouble() ?? 0,
    data: DateTime.tryParse(json['data'] as String? ?? '') ?? DateTime.now(),
  );
}

class AlertConfig {
  int id;
  String mensagem;
  int hora;
  int minuto;
  List<int> diasSemana;
  bool ativo;

  AlertConfig({
    required this.id,
    required this.mensagem,
    required this.hora,
    required this.minuto,
    required this.diasSemana,
    this.ativo = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'mensagem': mensagem,
    'hora': hora,
    'minuto': minuto,
    'diasSemana': diasSemana,
    'ativo': ativo,
  };

  factory AlertConfig.fromJson(Map<String, dynamic> json) => AlertConfig(
    id: (json['id'] as num).toInt(),
    mensagem: json['mensagem'] as String? ?? '',
    hora: (json['hora'] as num?)?.toInt() ?? 8,
    minuto: (json['minuto'] as num?)?.toInt() ?? 0,
    diasSemana:
        (json['diasSemana'] as List?)?.map((e) => (e as num).toInt()).toList() ??
        const [1, 2, 3, 4, 5],
    ativo: json['ativo'] as bool? ?? true,
  );

  String get horarioFormatado =>
      '${hora.toString().padLeft(2, '0')}:${minuto.toString().padLeft(2, '0')}';

  static const List<String> nomesDias = [
    'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom',
  ];

  String get diasFormatados {
    if (diasSemana.length == 7) return 'Todos os dias';
    final set = diasSemana.toSet();
    if (set.containsAll({1, 2, 3, 4, 5}) && set.length == 5) return 'Seg a Sex';
    final ordenados = [...diasSemana]..sort();
    return ordenados.map((d) => nomesDias[d - 1]).join(', ');
  }
}

/// Template padrão aplicado automaticamente ao abrir um mês novo.
/// O usuário pode editar o template na tela de configurações.
class TemplateData {
  List<ExpenseEntry> gastosGerais;
  List<IncomeEntry> entradas;
  double orcamentoAlimentacao;
  double orcamentoTransporte;
  double orcamentoGastosExtras;

  TemplateData({
    List<ExpenseEntry>? gastosGerais,
    List<IncomeEntry>? entradas,
    this.orcamentoAlimentacao = 0,
    this.orcamentoTransporte = 0,
    this.orcamentoGastosExtras = 0,
  })  : gastosGerais = gastosGerais ?? [],
        entradas = entradas ?? [];

  Map<String, dynamic> toJson() => {
    'gastosGerais': gastosGerais.map((e) => e.toJson()).toList(),
    'entradas': entradas.map((e) => e.toJson()).toList(),
    'orcamentoAlimentacao': orcamentoAlimentacao,
    'orcamentoTransporte': orcamentoTransporte,
    'orcamentoGastosExtras': orcamentoGastosExtras,
  };

  factory TemplateData.fromJson(Map<String, dynamic> json) => TemplateData(
    gastosGerais: ((json['gastosGerais'] as List?) ?? [])
        .map((e) => ExpenseEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    entradas: ((json['entradas'] as List?) ?? [])
        .map((e) => IncomeEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    orcamentoAlimentacao:
        (json['orcamentoAlimentacao'] as num?)?.toDouble() ?? 0,
    orcamentoTransporte: (json['orcamentoTransporte'] as num?)?.toDouble() ?? 0,
    orcamentoGastosExtras:
        (json['orcamentoGastosExtras'] as num?)?.toDouble() ?? 0,
  );

  /// Cria um MonthData novo a partir deste template.
  MonthData aplicarPara(int year, int month) {
    return MonthData(
      year: year,
      month: month,
      gastosGerais: gastosGerais
          .map((e) => e.copyWith(id: _gid(), resetPago: true))
          .toList(),
      entradas: entradas
          .map(
            (e) => IncomeEntry(
              id: _gid(),
              descricao: e.descricao,
              valor: e.valor,
              data: DateTime(year, month, 1),
            ),
          )
          .toList(),
      orcamentoAlimentacao: orcamentoAlimentacao,
      orcamentoTransporte: orcamentoTransporte,
      orcamentoGastosExtras: orcamentoGastosExtras,
    );
  }

  static TemplateData padrao() {
    return TemplateData(
      gastosGerais: [
        ExpenseEntry(id: _gid(), tipo: 'Aluguel', valor: 250),
        ExpenseEntry(id: _gid(), tipo: 'Água', valor: 100),
        ExpenseEntry(id: _gid(), tipo: 'Luz', valor: 150),
        ExpenseEntry(id: _gid(), tipo: 'Gás', valor: 90),
        ExpenseEntry(id: _gid(), tipo: 'Internet Wifi', valor: 70),
        ExpenseEntry(id: _gid(), tipo: 'Internet chip', valor: 50),
        ExpenseEntry(id: _gid(), tipo: 'Cartão Nubank', valor: 600),
        ExpenseEntry(id: _gid(), tipo: 'Streaming', valor: 40),
        ExpenseEntry(id: _gid(), tipo: 'Aniversários', valor: 0),
        ExpenseEntry(id: _gid(), tipo: 'Mãe', valor: 400),
        ExpenseEntry(id: _gid(), tipo: 'Leninha', valor: 100),
        ExpenseEntry(id: _gid(), tipo: 'Emergência', valor: 200),
        ExpenseEntry(id: _gid(), tipo: 'Imprevistos', valor: 300),
        ExpenseEntry(id: _gid(), tipo: 'Turbo', valor: 1200),
        ExpenseEntry(id: _gid(), tipo: 'Claude IA', valor: 120),
        ExpenseEntry(id: _gid(), tipo: 'Udemy', valor: 50),
      ],
      entradas: [
        IncomeEntry(
          id: _gid(),
          descricao: 'Salário',
          valor: 5288,
          data: DateTime.now(),
        ),
      ],
      orcamentoAlimentacao: 660,
      orcamentoTransporte: 300,
      orcamentoGastosExtras: 300,
    );
  }
}

/// Dados financeiros de um único mês.
class MonthData {
  final int year;
  final int month;
  List<ExpenseEntry> gastosGerais;
  List<ExpenseEntry> alimentacao;
  List<ExpenseEntry> gastosExtras;
  List<TransportEntry> transporte;
  List<IncomeEntry> entradas;
  double orcamentoAlimentacao;
  double orcamentoTransporte;
  double orcamentoGastosExtras;

  MonthData({
    required this.year,
    required this.month,
    List<ExpenseEntry>? gastosGerais,
    List<ExpenseEntry>? alimentacao,
    List<ExpenseEntry>? gastosExtras,
    List<TransportEntry>? transporte,
    List<IncomeEntry>? entradas,
    this.orcamentoAlimentacao = 0,
    this.orcamentoTransporte = 0,
    this.orcamentoGastosExtras = 0,
  })  : gastosGerais = gastosGerais ?? [],
        alimentacao = alimentacao ?? [],
        gastosExtras = gastosExtras ?? [],
        transporte = transporte ?? [],
        entradas = entradas ?? [];

  String get chave => '$year-${month.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
    'year': year,
    'month': month,
    'gastosGerais': gastosGerais.map((e) => e.toJson()).toList(),
    'alimentacao': alimentacao.map((e) => e.toJson()).toList(),
    'gastosExtras': gastosExtras.map((e) => e.toJson()).toList(),
    'transporte': transporte.map((e) => e.toJson()).toList(),
    'entradas': entradas.map((e) => e.toJson()).toList(),
    'orcamentoAlimentacao': orcamentoAlimentacao,
    'orcamentoTransporte': orcamentoTransporte,
    'orcamentoGastosExtras': orcamentoGastosExtras,
  };

  factory MonthData.fromJson(Map<String, dynamic> json) => MonthData(
    year: (json['year'] as num).toInt(),
    month: (json['month'] as num).toInt(),
    gastosGerais: ((json['gastosGerais'] as List?) ?? [])
        .map((e) => ExpenseEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    alimentacao: ((json['alimentacao'] as List?) ?? [])
        .map((e) => ExpenseEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    gastosExtras: ((json['gastosExtras'] as List?) ?? [])
        .map((e) => ExpenseEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    transporte: ((json['transporte'] as List?) ?? [])
        .map((e) => TransportEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    entradas: ((json['entradas'] as List?) ?? [])
        .map((e) => IncomeEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    orcamentoAlimentacao:
        (json['orcamentoAlimentacao'] as num?)?.toDouble() ?? 0,
    orcamentoTransporte: (json['orcamentoTransporte'] as num?)?.toDouble() ?? 0,
    orcamentoGastosExtras:
        (json['orcamentoGastosExtras'] as num?)?.toDouble() ?? 0,
  );
}

class FinanceData {
  Map<String, MonthData> meses;
  List<AlertConfig> alertas;
  TemplateData template;

  FinanceData({
    Map<String, MonthData>? meses,
    List<AlertConfig>? alertas,
    TemplateData? template,
  })  : meses = meses ?? {},
        alertas = alertas ?? [],
        template = template ?? TemplateData.padrao();

  Map<String, dynamic> toJson() => {
    'versao': 2,
    'meses': meses.map((k, v) => MapEntry(k, v.toJson())),
    'alertas': alertas.map((e) => e.toJson()).toList(),
    'template': template.toJson(),
  };

  factory FinanceData.fromJson(Map<String, dynamic> json) {
    final versao = (json['versao'] as num?)?.toInt() ?? 1;

    final alertas = ((json['alertas'] as List?) ?? [])
        .map((e) => AlertConfig.fromJson(e as Map<String, dynamic>))
        .toList();

    final template = json['template'] != null
        ? TemplateData.fromJson(json['template'] as Map<String, dynamic>)
        : TemplateData.padrao();

    if (versao == 1) {
      // Migração: dados planos → estrutura mensal.
      final now = DateTime.now();
      final mes = MonthData(
        year: now.year,
        month: now.month,
        gastosGerais: _parseExp(json['gastosGerais']),
        alimentacao: _parseExp(json['alimentacao']),
        gastosExtras: _parseExp(json['gastosExtras']),
        transporte: _parseTra(json['transporte']),
        entradas: _parseInc(json['entradas']),
      );
      return FinanceData(
        meses: {mes.chave: mes},
        alertas: alertas,
        template: template,
      );
    }

    final mesesJson = (json['meses'] as Map?)?.cast<String, dynamic>() ?? {};
    return FinanceData(
      meses: mesesJson.map(
        (k, v) => MapEntry(k, MonthData.fromJson(v as Map<String, dynamic>)),
      ),
      alertas: alertas,
      template: template,
    );
  }

  factory FinanceData.exemplo() {
    final tmpl = TemplateData.padrao();
    final now = DateTime.now();
    final mes = tmpl.aplicarPara(now.year, now.month);
    return FinanceData(meses: {mes.chave: mes}, template: tmpl);
  }

  static List<ExpenseEntry> _parseExp(dynamic list) =>
      ((list as List?) ?? [])
          .map((e) => ExpenseEntry.fromJson(e as Map<String, dynamic>))
          .toList();

  static List<TransportEntry> _parseTra(dynamic list) =>
      ((list as List?) ?? [])
          .map((e) => TransportEntry.fromJson(e as Map<String, dynamic>))
          .toList();

  static List<IncomeEntry> _parseInc(dynamic list) =>
      ((list as List?) ?? [])
          .map((e) => IncomeEntry.fromJson(e as Map<String, dynamic>))
          .toList();
}

// ---------------------------------------------------------------------------
// Utilitários internos compartilhados entre os modelos.
// ---------------------------------------------------------------------------

int _seq = 0;
String _gid() => '${DateTime.now().microsecondsSinceEpoch}_${++_seq}';
