import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/finance_provider.dart';
import '../theme.dart';
import '../widgets/forms.dart';
import '../widgets/resumo.dart';

class IncomeScreen extends StatelessWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<FinanceProvider>();
    final entradas = p.entradas;
    final dataFmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: ResumoCard(
              entradas: p.totalEntradas,
              saidas: p.totalSaidas,
            ),
          ),
          // Painel de comprometimento: mostra como a renda foi alocada.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Como sua renda está alocada',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _linha('Gastos fixos', p.totalGastosGerais),
                    _linha(
                      'Orç. Alimentação',
                      p.orcamentoAlimentacao,
                      sub: 'gasto: ${formatarReal(p.totalAlimentacao)}',
                    ),
                    _linha(
                      'Orç. Transporte',
                      p.orcamentoTransporte,
                      sub: 'gasto: ${formatarReal(p.totalTransporte)}',
                    ),
                    _linha(
                      'Orç. Extras',
                      p.orcamentoGastosExtras,
                      sub: 'gasto: ${formatarReal(p.totalGastosExtras)}',
                    ),
                    const Divider(height: 20),
                    _linha('Comprometido', p.totalComprometido, destaque: true),
                    _linha(
                      'Disponível',
                      p.totalDisponivel,
                      destaque: true,
                      cor: p.totalDisponivel < 0
                          ? AppCores.vermelho
                          : AppCores.verde,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.arrow_downward, color: AppCores.verde),
                const SizedBox(width: 8),
                Text(
                  'Entradas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: entradas.isEmpty
                ? const EstadoVazio(
                    icone: Icons.account_balance_wallet,
                    texto: 'Nenhuma entrada cadastrada.\n'
                        'Toque em + para adicionar.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 90),
                    itemCount: entradas.length,
                    itemBuilder: (context, i) {
                      final e = entradas[i];
                      return Slidable(
                        key: ValueKey(e.id),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) => mostrarFormEntrada(
                                context,
                                p,
                                existente: e,
                              ),
                              backgroundColor: AppCores.verde,
                              foregroundColor: Colors.white,
                              icon: Icons.edit,
                              label: 'Editar',
                            ),
                            SlidableAction(
                              onPressed: (_) => p.removerEntrada(e.id),
                              backgroundColor: AppCores.vermelho,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              label: 'Excluir',
                            ),
                          ],
                        ),
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppCores.verdeFundo,
                              child: Icon(Icons.attach_money,
                                  color: AppCores.verde),
                            ),
                            title: Text(
                              e.descricao,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(dataFmt.format(e.data)),
                            trailing: Text(
                              formatarReal(e.valor),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppCores.verde,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
            heroTag: null,
        onPressed: () => mostrarFormEntrada(context, p),
        icon: const Icon(Icons.add),
        label: const Text('Nova entrada'),
      ),
    );
  }

  Widget _linha(
    String titulo,
    double valor, {
    bool destaque = false,
    String? sub,
    Color? cor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontWeight:
                        destaque ? FontWeight.bold : FontWeight.normal,
                    fontSize: destaque ? 15 : 14,
                  ),
                ),
                if (sub != null)
                  Text(sub,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 11)),
              ],
            ),
          ),
          Text(
            formatarReal(valor),
            style: TextStyle(
              fontWeight:
                  destaque ? FontWeight.bold : FontWeight.w500,
              color: cor ??
                  (destaque ? Colors.grey.shade800 : Colors.grey.shade700),
              fontSize: destaque ? 15 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
