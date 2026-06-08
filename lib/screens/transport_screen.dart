import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/finance_provider.dart';
import '../theme.dart';
import '../widgets/forms.dart';
import '../widgets/resumo.dart';

class TransportScreen extends StatelessWidget {
  const TransportScreen({super.key});

  FaIconData _icone(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains('ônibus') || t.contains('onibus') || t.contains('bus')) {
      return FontAwesomeIcons.bus;
    }
    if (t.contains('uber') ||
        t.contains('carro') ||
        t.contains('táxi') ||
        t.contains('taxi')) {
      return FontAwesomeIcons.car;
    }
    if (t.contains('metr')) return FontAwesomeIcons.trainSubway;
    if (t.contains('bike') || t.contains('bici')) {
      return FontAwesomeIcons.bicycle;
    }
    return FontAwesomeIcons.route;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final lista = provider.transporte;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: OrcamentoCard(
              categoriaLabel: 'Transporte',
              orcamento: provider.orcamentoTransporte,
              gasto: provider.totalTransporte,
              onEditar: () => mostrarDialogOrcamento(
                  context, provider, Categoria.transporte),
            ),
          ),
          Expanded(
            child: lista.isEmpty
                ? const EstadoVazio(
                    icone: Icons.directions_bus,
                    texto: 'Nenhum transporte cadastrado.\n'
                        'Toque em + para adicionar.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: lista.length,
                    itemBuilder: (context, i) {
                      final t = lista[i];
                      return Slidable(
                        key: ValueKey(t.id),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) => mostrarFormTransporte(
                                context,
                                provider,
                                existente: t,
                              ),
                              backgroundColor: AppCores.verde,
                              foregroundColor: Colors.white,
                              icon: Icons.edit,
                              label: 'Editar',
                            ),
                            SlidableAction(
                              onPressed: (_) =>
                                  provider.removerTransporte(t.id),
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
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppCores.verdeFundo,
                                  child: FaIcon(
                                    _icone(t.tipo),
                                    color: AppCores.verde,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.tipo,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${formatarReal(t.valorUnitario)} × ${t.quantidade}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Total: ${formatarReal(t.total)}',
                                        style: const TextStyle(
                                          color: AppCores.verde,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _BotaoQtd(
                                  icone: Icons.remove,
                                  onTap: () =>
                                      provider.decrementarQuantidade(t.id),
                                ),
                                Container(
                                  width: 34,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${t.quantidade}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                _BotaoQtd(
                                  icone: Icons.add,
                                  destaque: true,
                                  onTap: () =>
                                      provider.incrementarQuantidade(t.id),
                                ),
                              ],
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
        onPressed: () => mostrarFormTransporte(context, provider),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
      ),
    );
  }
}

class _BotaoQtd extends StatelessWidget {
  final IconData icone;
  final VoidCallback onTap;
  final bool destaque;
  const _BotaoQtd({
    required this.icone,
    required this.onTap,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: destaque ? AppCores.verde : AppCores.verdeFundo,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icone,
            size: 20,
            color: destaque ? Colors.white : AppCores.verde,
          ),
        ),
      ),
    );
  }
}
