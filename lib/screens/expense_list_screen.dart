import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/finance_provider.dart';
import '../theme.dart';
import '../widgets/forms.dart';
import '../widgets/resumo.dart';

class ExpenseListScreen extends StatelessWidget {
  final Categoria categoria;
  final IconData icone;
  const ExpenseListScreen({
    super.key,
    required this.categoria,
    required this.icone,
  });

  double _orcamento(FinanceProvider p) {
    switch (categoria) {
      case Categoria.alimentacao:
        return p.orcamentoAlimentacao;
      case Categoria.gastosExtras:
        return p.orcamentoGastosExtras;
      default:
        return 0;
    }
  }

  double _gasto(FinanceProvider p) {
    switch (categoria) {
      case Categoria.alimentacao:
        return p.totalAlimentacao;
      case Categoria.gastosExtras:
        return p.totalGastosExtras;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final lista = categoria == Categoria.alimentacao
        ? provider.alimentacao
        : provider.gastosExtras;
    final dataFmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: OrcamentoCard(
              categoriaLabel: categoria.titulo,
              orcamento: _orcamento(provider),
              gasto: _gasto(provider),
              onEditar: () =>
                  mostrarDialogOrcamento(context, provider, categoria),
            ),
          ),
          Expanded(
            child: lista.isEmpty
                ? EstadoVazio(
                    icone: icone,
                    texto: 'Nenhum gasto em ${categoria.titulo}.\n'
                        'Toque em + para adicionar.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: lista.length,
                    itemBuilder: (context, i) {
                      final e = lista[i];
                      return Slidable(
                        key: ValueKey(e.id),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) => mostrarFormDespesa(
                                context,
                                provider,
                                categoria,
                                existente: e,
                              ),
                              backgroundColor: AppCores.verde,
                              foregroundColor: Colors.white,
                              icon: Icons.edit,
                              label: 'Editar',
                            ),
                            SlidableAction(
                              onPressed: (_) =>
                                  provider.removerDespesa(categoria, e.id),
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
                            leading: CircleAvatar(
                              backgroundColor: AppCores.verdeFundo,
                              child: Icon(icone, color: AppCores.verde),
                            ),
                            title: Text(
                              e.tipo,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: e.data != null
                                ? Text(dataFmt.format(e.data!))
                                : null,
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
        onPressed: () => mostrarFormDespesa(context, provider, categoria),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
      ),
    );
  }
}
