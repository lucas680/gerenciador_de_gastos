import 'package:flutter_test/flutter_test.dart';

import 'package:gerenciador_de_gastos/models/models.dart';

void main() {
  test('Serialização mensal (JSON round-trip)', () {
    final dados = FinanceData.exemplo();
    final json = dados.toJson();
    final restaurado = FinanceData.fromJson(json);

    expect(restaurado.meses.length, equals(dados.meses.length));

    final mesKey = dados.meses.keys.first;
    final mes = restaurado.meses[mesKey]!;
    expect(mes.gastosGerais.isNotEmpty, isTrue);
    expect(mes.entradas.first.valor, equals(5288));
  });

  test('Total de transporte = quantidade × valor unitário', () {
    final t = TransportEntry(
      id: '1',
      tipo: 'Ônibus',
      quantidade: 3,
      valorUnitario: 5.5,
    );
    expect(t.total, equals(16.5));
  });

  test('Template aplica dados para novo mês', () {
    final tmpl = TemplateData.padrao();
    final mes = tmpl.aplicarPara(2025, 1);
    expect(mes.year, equals(2025));
    expect(mes.month, equals(1));
    expect(mes.gastosGerais.isNotEmpty, isTrue);
    // Gastos fixos do template começam com pago = false.
    expect(mes.gastosGerais.every((e) => !e.pago), isTrue);
  });
}
