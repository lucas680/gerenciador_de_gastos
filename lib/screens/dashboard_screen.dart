import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/finance_provider.dart';
import '../theme.dart';
import '../widgets/forms.dart';
import '../widgets/resumo.dart';

/// Tela inicial: visão geral das finanças + lista de "Gastos gerais"
/// (despesas fixas) com marcação de pago e indicador de progresso.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final gastos = provider.gastosGerais;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
        children: [
          ResumoCard(
            entradas: provider.totalEntradas,
            saidas: provider.totalSaidas,
          ),
          const SizedBox(height: 12),
          _CardProgresso(provider: provider),
          const SizedBox(height: 12),
          _ResumoCategorias(provider: provider),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: AppCores.verde),
                const SizedBox(width: 8),
                Text(
                  'Gastos gerais',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                Text(
                  formatarReal(provider.totalGastosGerais),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppCores.verde,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (gastos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: EstadoVazio(
                icone: Icons.receipt_long,
                texto: 'Nenhum gasto fixo cadastrado.',
              ),
            )
          else
            ...gastos.map((e) => _LinhaGasto(provider: provider, gasto: e)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () =>
            mostrarFormDespesa(context, provider, Categoria.gastosGerais),
        icon: const Icon(Icons.add),
        label: const Text('Novo gasto'),
      ),
    );
  }
}

class _CardProgresso extends StatelessWidget {
  final FinanceProvider provider;
  const _CardProgresso({required this.provider});

  @override
  Widget build(BuildContext context) {
    final percent = provider.percentualPago;
    final total = provider.gastosGerais.length;
    final pago = provider.gastosGerais.where((e) => e.pago).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircularPercentIndicator(
              radius: 44,
              lineWidth: 9,
              percent: percent,
              animation: true,
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: AppCores.verde,
              backgroundColor: AppCores.verdeFundo,
              center: Text(
                '${(percent * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gastos fixos pagos',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$pago de $total itens',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumoCategorias extends StatelessWidget {
  final FinanceProvider provider;
  const _ResumoCategorias({required this.provider});

  @override
  Widget build(BuildContext context) {
    final itens = [
      (
        Icons.directions_bus,
        'Transporte',
        provider.totalTransporte,
        provider.orcamentoTransporte,
      ),
      (
        Icons.restaurant,
        'Alimentação',
        provider.totalAlimentacao,
        provider.orcamentoAlimentacao,
      ),
      (
        Icons.shopping_bag,
        'Extras',
        provider.totalGastosExtras,
        provider.orcamentoGastosExtras,
      ),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: itens.map((it) {
            final gasto = it.$3;
            final orcamento = it.$4;
            final percent = orcamento > 0
                ? (gasto / orcamento).clamp(0.0, 1.0)
                : 0.0;
            final excedeu = orcamento > 0 && gasto > orcamento;
            final cor = excedeu ? AppCores.vermelho : AppCores.verde;
            return Column(
              children: [
                CircularPercentIndicator(
                  radius: 30,
                  lineWidth: 5,
                  percent: percent,
                  animation: true,
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: cor,
                  backgroundColor: AppCores.verdeFundo,
                  center: Icon(it.$1, color: cor, size: 20),
                ),
                const SizedBox(height: 6),
                Text(it.$2, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  orcamento > 0
                      ? '${(percent * 100).toStringAsFixed(0)}%'
                      : formatarReal(gasto),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: excedeu ? AppCores.vermelho : Colors.black87,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _LinhaGasto extends StatelessWidget {
  final FinanceProvider provider;
  final ExpenseEntry gasto;
  const _LinhaGasto({required this.provider, required this.gasto});

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(gasto.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => mostrarFormDespesa(
              context,
              provider,
              Categoria.gastosGerais,
              existente: gasto,
            ),
            backgroundColor: AppCores.verde,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Editar',
          ),
          SlidableAction(
            onPressed: (_) =>
                provider.removerDespesa(Categoria.gastosGerais, gasto.id),
            backgroundColor: AppCores.vermelho,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Excluir',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: ListTile(
          onTap: () => provider.alternarPago(Categoria.gastosGerais, gasto.id),
          leading: Checkbox(
            value: gasto.pago,
            activeColor: AppCores.verde,
            shape: const CircleBorder(),
            onChanged: (_) =>
                provider.alternarPago(Categoria.gastosGerais, gasto.id),
          ),
          title: Text(
            gasto.tipo,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              decoration: gasto.pago ? TextDecoration.lineThrough : null,
              color: gasto.pago ? Colors.grey : null,
            ),
          ),
          subtitle: Text(gasto.pago ? 'Pago' : 'Pendente'),
          trailing: Text(
            formatarReal(gasto.valor),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: gasto.pago ? Colors.grey : AppCores.verde,
            ),
          ),
        ),
      ),
    );
  }
}
