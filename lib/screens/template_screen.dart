import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/finance_provider.dart';
import '../theme.dart';

/// Tela para editar o template padrão que é aplicado ao abrir um mês novo.
/// Permite configurar os gastos fixos padrão, orçamentos e entradas recorrentes.
class TemplateScreen extends StatefulWidget {
  const TemplateScreen({super.key});

  @override
  State<TemplateScreen> createState() => _TemplateScreenState();
}

class _TemplateScreenState extends State<TemplateScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _adicionarGasto(BuildContext context, FinanceProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FormGastoTemplate(provider: provider),
    );
  }

  void _adicionarEntrada(BuildContext context, FinanceProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FormEntradaTemplate(provider: provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Template padrão'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: 'Gastos fixos'),
            Tab(icon: Icon(Icons.savings), text: 'Orçamentos'),
            Tab(icon: Icon(Icons.attach_money), text: 'Entradas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _TabGastoFixo(),
          _TabOrcamentos(),
          _TabEntradas(),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabs,
        builder: (_, __) {
          if (_tabs.index == 1) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            heroTag: null,
            onPressed: () {
              if (_tabs.index == 0) {
                _adicionarGasto(context, provider);
              } else {
                _adicionarEntrada(context, provider);
              }
            },
            icon: const Icon(Icons.add),
            label: Text(_tabs.index == 0 ? 'Gasto' : 'Entrada'),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Aba de gastos fixos do template
// ---------------------------------------------------------------------------

class _TabGastoFixo extends StatelessWidget {
  const _TabGastoFixo();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final tmpl = provider.template;
    final lista = tmpl.gastosGerais;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Card(
            color: AppCores.verdeFundo,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppCores.verde, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esses gastos serão pré-preenchidos ao abrir um mês novo. '
                      'Arrastando o item para a esquerda você pode editar ou excluir.',
                      style: TextStyle(
                          color: Colors.grey.shade700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: lista.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('Nenhum gasto fixo no template.',
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
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
                            onPressed: (_) =>
                                _editarGasto(context, provider, i, e),
                            backgroundColor: AppCores.verde,
                            foregroundColor: Colors.white,
                            icon: Icons.edit,
                            label: 'Editar',
                          ),
                          SlidableAction(
                            onPressed: (_) {
                              final novo = TemplateData(
                                gastosGerais: [...tmpl.gastosGerais]
                                  ..removeAt(i),
                                entradas: tmpl.entradas,
                                orcamentoAlimentacao:
                                    tmpl.orcamentoAlimentacao,
                                orcamentoTransporte:
                                    tmpl.orcamentoTransporte,
                                orcamentoGastosExtras:
                                    tmpl.orcamentoGastosExtras,
                              );
                              provider.atualizarTemplate(novo);
                            },
                            backgroundColor: AppCores.vermelho,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Excluir',
                          ),
                        ],
                      ),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppCores.verdeFundo,
                            child: Icon(Icons.receipt_long,
                                color: AppCores.verde, size: 18),
                          ),
                          title: Text(e.tipo,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          trailing: Text(
                            formatarReal(e.valor),
                            style: const TextStyle(
                                color: AppCores.verde,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _editarGasto(
    BuildContext context,
    FinanceProvider provider,
    int index,
    ExpenseEntry entry,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FormGastoTemplate(
        provider: provider,
        existente: entry,
        index: index,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Aba de orçamentos padrão
// ---------------------------------------------------------------------------

class _TabOrcamentos extends StatefulWidget {
  const _TabOrcamentos();

  @override
  State<_TabOrcamentos> createState() => _TabOrcamentosState();
}

class _TabOrcamentosState extends State<_TabOrcamentos> {
  late TextEditingController _alimentacao;
  late TextEditingController _transporte;
  late TextEditingController _extras;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tmpl = context.read<FinanceProvider>().template;
    _alimentacao = TextEditingController(
      text: tmpl.orcamentoAlimentacao > 0
          ? UtilBrasilFields.obterReal(
              tmpl.orcamentoAlimentacao, moeda: false)
          : '',
    );
    _transporte = TextEditingController(
      text: tmpl.orcamentoTransporte > 0
          ? UtilBrasilFields.obterReal(
              tmpl.orcamentoTransporte, moeda: false)
          : '',
    );
    _extras = TextEditingController(
      text: tmpl.orcamentoGastosExtras > 0
          ? UtilBrasilFields.obterReal(
              tmpl.orcamentoGastosExtras, moeda: false)
          : '',
    );
  }

  @override
  void dispose() {
    _alimentacao.dispose();
    _transporte.dispose();
    _extras.dispose();
    super.dispose();
  }

  double _parse(TextEditingController c) {
    if (c.text.trim().isEmpty) return 0;
    try {
      return UtilBrasilFields.converterMoedaParaDouble(c.text);
    } catch (_) {
      return double.tryParse(
              c.text.replaceAll('.', '').replaceAll(',', '.')) ??
          0;
    }
  }

  void _salvar() {
    final provider = context.read<FinanceProvider>();
    final tmpl = provider.template;
    final novo = TemplateData(
      gastosGerais: tmpl.gastosGerais,
      entradas: tmpl.entradas,
      orcamentoAlimentacao: _parse(_alimentacao),
      orcamentoTransporte: _parse(_transporte),
      orcamentoGastosExtras: _parse(_extras),
    );
    provider.atualizarTemplate(novo);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Orçamentos padrão salvos!')),
    );
  }

  Widget _campo(String label, TextEditingController ctrl, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          CentavosInputFormatter(moeda: false),
        ],
        decoration: InputDecoration(
          labelText: label,
          prefixText: 'R\$ ',
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: AppCores.verdeFundo,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppCores.verde, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esses valores serão o orçamento padrão de cada '
                      'categoria ao abrir um mês novo.',
                      style: TextStyle(
                          color: Colors.grey.shade700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _campo(
              'Orçamento Alimentação', _alimentacao, Icons.restaurant),
          _campo('Orçamento Transporte', _transporte,
              Icons.directions_bus),
          _campo('Orçamento Extras', _extras, Icons.shopping_bag),
          const Spacer(),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppCores.verde,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _salvar,
            icon: const Icon(Icons.check),
            label: const Text('Salvar orçamentos'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Aba de entradas recorrentes (ex: salário)
// ---------------------------------------------------------------------------

class _TabEntradas extends StatelessWidget {
  const _TabEntradas();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final tmpl = provider.template;
    final lista = tmpl.entradas;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Card(
            color: AppCores.verdeFundo,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppCores.verde, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Entradas recorrentes (ex: salário) que serão '
                      'inseridas automaticamente em cada mês novo.',
                      style: TextStyle(
                          color: Colors.grey.shade700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: lista.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.attach_money,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('Nenhuma entrada no template.',
                          style:
                              TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
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
                            onPressed: (_) =>
                                _editarEntrada(context, provider, i, e),
                            backgroundColor: AppCores.verde,
                            foregroundColor: Colors.white,
                            icon: Icons.edit,
                            label: 'Editar',
                          ),
                          SlidableAction(
                            onPressed: (_) {
                              final novo = TemplateData(
                                gastosGerais: tmpl.gastosGerais,
                                entradas: [...tmpl.entradas]..removeAt(i),
                                orcamentoAlimentacao:
                                    tmpl.orcamentoAlimentacao,
                                orcamentoTransporte:
                                    tmpl.orcamentoTransporte,
                                orcamentoGastosExtras:
                                    tmpl.orcamentoGastosExtras,
                              );
                              provider.atualizarTemplate(novo);
                            },
                            backgroundColor: AppCores.vermelho,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Excluir',
                          ),
                        ],
                      ),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppCores.verdeFundo,
                            child: Icon(Icons.attach_money,
                                color: AppCores.verde),
                          ),
                          title: Text(e.descricao,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          trailing: Text(
                            formatarReal(e.valor),
                            style: const TextStyle(
                                color: AppCores.verde,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _editarEntrada(
    BuildContext context,
    FinanceProvider provider,
    int index,
    IncomeEntry entry,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FormEntradaTemplate(
        provider: provider,
        existente: entry,
        index: index,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Formulários internos do template
// ---------------------------------------------------------------------------

class _FormGastoTemplate extends StatefulWidget {
  final FinanceProvider provider;
  final ExpenseEntry? existente;
  final int? index;
  const _FormGastoTemplate(
      {required this.provider, this.existente, this.index});

  @override
  State<_FormGastoTemplate> createState() => _FormGastoTemplateState();
}

class _FormGastoTemplateState extends State<_FormGastoTemplate> {
  late TextEditingController _tipo;
  late TextEditingController _valor;

  @override
  void initState() {
    super.initState();
    final e = widget.existente;
    _tipo = TextEditingController(text: e?.tipo ?? '');
    _valor = TextEditingController(
      text: e != null && e.valor > 0
          ? UtilBrasilFields.obterReal(e.valor, moeda: false)
          : '',
    );
  }

  @override
  void dispose() {
    _tipo.dispose();
    _valor.dispose();
    super.dispose();
  }

  double _parse() {
    if (_valor.text.trim().isEmpty) return 0;
    try {
      return UtilBrasilFields.converterMoedaParaDouble(_valor.text);
    } catch (_) {
      return double.tryParse(
              _valor.text.replaceAll('.', '').replaceAll(',', '.')) ??
          0;
    }
  }

  void _salvar() {
    if (_tipo.text.trim().isEmpty) return;
    final tmpl = widget.provider.template;
    final novaLista = [...tmpl.gastosGerais];
    final novoItem = ExpenseEntry(
      id: widget.existente?.id ?? 'tmpl_${DateTime.now().millisecondsSinceEpoch}',
      tipo: _tipo.text.trim(),
      valor: _parse(),
    );
    if (widget.index != null) {
      novaLista[widget.index!] = novoItem;
    } else {
      novaLista.add(novoItem);
    }
    widget.provider.atualizarTemplate(TemplateData(
      gastosGerais: novaLista,
      entradas: tmpl.entradas,
      orcamentoAlimentacao: tmpl.orcamentoAlimentacao,
      orcamentoTransporte: tmpl.orcamentoTransporte,
      orcamentoGastosExtras: tmpl.orcamentoGastosExtras,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existente == null
                ? 'Adicionar ao template'
                : 'Editar gasto',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _tipo,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Tipo de gasto',
              prefixIcon: Icon(Icons.label_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _valor,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CentavosInputFormatter(moeda: false),
            ],
            decoration: const InputDecoration(
              labelText: 'Valor padrão',
              prefixText: 'R\$ ',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppCores.verde,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _salvar,
            icon: const Icon(Icons.check),
            label: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}

class _FormEntradaTemplate extends StatefulWidget {
  final FinanceProvider provider;
  final IncomeEntry? existente;
  final int? index;
  const _FormEntradaTemplate(
      {required this.provider, this.existente, this.index});

  @override
  State<_FormEntradaTemplate> createState() => _FormEntradaTemplateState();
}

class _FormEntradaTemplateState extends State<_FormEntradaTemplate> {
  late TextEditingController _desc;
  late TextEditingController _valor;

  @override
  void initState() {
    super.initState();
    final e = widget.existente;
    _desc = TextEditingController(text: e?.descricao ?? '');
    _valor = TextEditingController(
      text: e != null && e.valor > 0
          ? UtilBrasilFields.obterReal(e.valor, moeda: false)
          : '',
    );
  }

  @override
  void dispose() {
    _desc.dispose();
    _valor.dispose();
    super.dispose();
  }

  double _parse() {
    if (_valor.text.trim().isEmpty) return 0;
    try {
      return UtilBrasilFields.converterMoedaParaDouble(_valor.text);
    } catch (_) {
      return double.tryParse(
              _valor.text.replaceAll('.', '').replaceAll(',', '.')) ??
          0;
    }
  }

  void _salvar() {
    if (_desc.text.trim().isEmpty) return;
    final tmpl = widget.provider.template;
    final novaLista = [...tmpl.entradas];
    final novoItem = IncomeEntry(
      id: widget.existente?.id ?? 'tmpl_${DateTime.now().millisecondsSinceEpoch}',
      descricao: _desc.text.trim(),
      valor: _parse(),
      data: DateTime.now(),
    );
    if (widget.index != null) {
      novaLista[widget.index!] = novoItem;
    } else {
      novaLista.add(novoItem);
    }
    widget.provider.atualizarTemplate(TemplateData(
      gastosGerais: tmpl.gastosGerais,
      entradas: novaLista,
      orcamentoAlimentacao: tmpl.orcamentoAlimentacao,
      orcamentoTransporte: tmpl.orcamentoTransporte,
      orcamentoGastosExtras: tmpl.orcamentoGastosExtras,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existente == null
                ? 'Adicionar entrada ao template'
                : 'Editar entrada',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _desc,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Descrição (Salário, etc.)',
              prefixIcon: Icon(Icons.work_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _valor,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CentavosInputFormatter(moeda: false),
            ],
            decoration: const InputDecoration(
              labelText: 'Valor padrão',
              prefixText: 'R\$ ',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppCores.verde,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _salvar,
            icon: const Icon(Icons.check),
            label: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
