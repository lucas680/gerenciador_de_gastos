import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../providers/finance_provider.dart';
import '../theme.dart';

final _dataFmt = DateFormat('dd/MM/yyyy');

double _paraDouble(String texto) {
  if (texto.trim().isEmpty) return 0;
  try {
    return UtilBrasilFields.converterMoedaParaDouble(texto);
  } catch (_) {
    return double.tryParse(texto.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
  }
}

/// Cabeçalho padrão das folhas de formulário.
Widget _tituloSheet(String titulo) => Padding(
  padding: const EdgeInsets.only(bottom: 16),
  child: Row(
    children: [
      Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ],
  ),
);

Future<T?> _abrirSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
      ),
      child: child,
    ),
  );
}

// ---------------------------------------------------------------------------
// Despesa comum (Gastos gerais, Alimentação, Gastos extras)
// ---------------------------------------------------------------------------

Future<void> mostrarFormDespesa(
  BuildContext context,
  FinanceProvider provider,
  Categoria categoria, {
  ExpenseEntry? existente,
}) {
  return _abrirSheet(
    context,
    _FormDespesa(
      provider: provider,
      categoria: categoria,
      existente: existente,
    ),
  );
}

class _FormDespesa extends StatefulWidget {
  final FinanceProvider provider;
  final Categoria categoria;
  final ExpenseEntry? existente;
  const _FormDespesa({
    required this.provider,
    required this.categoria,
    this.existente,
  });

  @override
  State<_FormDespesa> createState() => _FormDespesaState();
}

class _FormDespesaState extends State<_FormDespesa> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tipo;
  late TextEditingController _valor;
  DateTime? _data;
  late bool _pago;

  bool get _mostrarPago => widget.categoria == Categoria.gastosGerais;

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
    _data = e?.data;
    _pago = e?.pago ?? false;
  }

  @override
  void dispose() {
    _tipo.dispose();
    _valor.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;
    final valor = _paraDouble(_valor.text);
    if (widget.existente == null) {
      widget.provider.adicionarDespesa(
        widget.categoria,
        tipo: _tipo.text.trim(),
        valor: valor,
        data: _data,
        pago: _pago,
      );
    } else {
      widget.provider.atualizarDespesa(
        widget.categoria,
        widget.existente!.id,
        tipo: _tipo.text.trim(),
        valor: valor,
        data: _data,
        pago: _pago,
      );
    }
    Navigator.pop(context);
  }

  Future<void> _escolherData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (escolhida != null) setState(() => _data = escolhida);
  }

  @override
  Widget build(BuildContext context) {
    final novo = widget.existente == null;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _tituloSheet(''),
          Text(
            '${novo ? 'Adicionar' : 'Editar'} - ${widget.categoria.titulo}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _tipo,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Tipo de gasto',
              prefixIcon: Icon(Icons.label_outline),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Informe o tipo' : null,
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
              labelText: 'Valor',
              prefixText: 'R\$ ',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _escolherData,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Data (opcional)',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                _data == null ? 'Sem data' : _dataFmt.format(_data!),
              ),
            ),
          ),
          if (_mostrarPago) ...[
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pago'),
              value: _pago,
              activeThumbColor: AppCores.verde,
              onChanged: (v) => setState(() => _pago = v),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppCores.verde,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _salvar,
            icon: const Icon(Icons.check),
            label: Text(novo ? 'Adicionar' : 'Salvar'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Transporte
// ---------------------------------------------------------------------------

Future<void> mostrarFormTransporte(
  BuildContext context,
  FinanceProvider provider, {
  TransportEntry? existente,
}) {
  return _abrirSheet(
    context,
    _FormTransporte(provider: provider, existente: existente),
  );
}

class _FormTransporte extends StatefulWidget {
  final FinanceProvider provider;
  final TransportEntry? existente;
  const _FormTransporte({required this.provider, this.existente});

  @override
  State<_FormTransporte> createState() => _FormTransporteState();
}

class _FormTransporteState extends State<_FormTransporte> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tipo;
  late TextEditingController _valor;
  late int _quantidade;

  @override
  void initState() {
    super.initState();
    final e = widget.existente;
    _tipo = TextEditingController(text: e?.tipo ?? '');
    _valor = TextEditingController(
      text: e != null && e.valorUnitario > 0
          ? UtilBrasilFields.obterReal(e.valorUnitario, moeda: false)
          : '',
    );
    _quantidade = e?.quantidade ?? 1;
  }

  @override
  void dispose() {
    _tipo.dispose();
    _valor.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;
    final valor = _paraDouble(_valor.text);
    if (widget.existente == null) {
      widget.provider.adicionarTransporte(
        tipo: _tipo.text.trim(),
        quantidade: _quantidade,
        valorUnitario: valor,
      );
    } else {
      widget.provider.atualizarTransporte(
        widget.existente!.id,
        tipo: _tipo.text.trim(),
        quantidade: _quantidade,
        valorUnitario: valor,
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final novo = widget.existente == null;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _tituloSheet(''),
          Text(
            '${novo ? 'Adicionar' : 'Editar'} - Transporte',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _tipo,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Tipo (Ônibus, UBER, etc.)',
              prefixIcon: Icon(Icons.directions_bus),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Informe o tipo' : null,
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
              labelText: 'Valor unitário',
              prefixText: 'R\$ ',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Quantidade de vezes',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const Spacer(),
              IconButton.filledTonal(
                onPressed: _quantidade > 0
                    ? () => setState(() => _quantidade--)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '$_quantidade',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => setState(() => _quantidade++),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppCores.verde,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _salvar,
            icon: const Icon(Icons.check),
            label: Text(novo ? 'Adicionar' : 'Salvar'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Entrada (renda)
// ---------------------------------------------------------------------------

Future<void> mostrarFormEntrada(
  BuildContext context,
  FinanceProvider provider, {
  IncomeEntry? existente,
}) {
  return _abrirSheet(
    context,
    _FormEntrada(provider: provider, existente: existente),
  );
}

class _FormEntrada extends StatefulWidget {
  final FinanceProvider provider;
  final IncomeEntry? existente;
  const _FormEntrada({required this.provider, this.existente});

  @override
  State<_FormEntrada> createState() => _FormEntradaState();
}

class _FormEntradaState extends State<_FormEntrada> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descricao;
  late TextEditingController _valor;
  late DateTime _data;

  @override
  void initState() {
    super.initState();
    final e = widget.existente;
    _descricao = TextEditingController(text: e?.descricao ?? '');
    _valor = TextEditingController(
      text: e != null && e.valor > 0
          ? UtilBrasilFields.obterReal(e.valor, moeda: false)
          : '',
    );
    _data = e?.data ?? DateTime.now();
  }

  @override
  void dispose() {
    _descricao.dispose();
    _valor.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;
    final valor = _paraDouble(_valor.text);
    if (widget.existente == null) {
      widget.provider.adicionarEntrada(
        descricao: _descricao.text.trim(),
        valor: valor,
        data: _data,
      );
    } else {
      widget.provider.atualizarEntrada(
        widget.existente!.id,
        descricao: _descricao.text.trim(),
        valor: valor,
        data: _data,
      );
    }
    Navigator.pop(context);
  }

  Future<void> _escolherData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (escolhida != null) setState(() => _data = escolhida);
  }

  @override
  Widget build(BuildContext context) {
    final novo = widget.existente == null;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _tituloSheet(''),
          Text(
            '${novo ? 'Adicionar' : 'Editar'} entrada',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descricao,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Descrição (Salário, etc.)',
              prefixIcon: Icon(Icons.work_outline),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Informe a descrição' : null,
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
              labelText: 'Valor',
              prefixText: 'R\$ ',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _escolherData,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Data',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(_dataFmt.format(_data)),
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
            label: Text(novo ? 'Adicionar' : 'Salvar'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Orçamento de categoria (Alimentação / Transporte / Gastos extras)
// ---------------------------------------------------------------------------

Future<void> mostrarDialogOrcamento(
  BuildContext context,
  FinanceProvider provider,
  Categoria categoria,
) {
  return _abrirSheet(
    context,
    _FormOrcamento(provider: provider, categoria: categoria),
  );
}

class _FormOrcamento extends StatefulWidget {
  final FinanceProvider provider;
  final Categoria categoria;
  const _FormOrcamento({required this.provider, required this.categoria});

  @override
  State<_FormOrcamento> createState() => _FormOrcamentoState();
}

class _FormOrcamentoState extends State<_FormOrcamento> {
  late TextEditingController _valor;

  double _orcamentoAtual() {
    switch (widget.categoria) {
      case Categoria.alimentacao:
        return widget.provider.orcamentoAlimentacao;
      case Categoria.transporte:
        return widget.provider.orcamentoTransporte;
      case Categoria.gastosExtras:
        return widget.provider.orcamentoGastosExtras;
      case Categoria.gastosGerais:
        return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    final atual = _orcamentoAtual();
    _valor = TextEditingController(
      text: atual > 0 ? UtilBrasilFields.obterReal(atual, moeda: false) : '',
    );
  }

  @override
  void dispose() {
    _valor.dispose();
    super.dispose();
  }

  void _salvar() {
    final v = _paraDouble(_valor.text);
    widget.provider.definirOrcamento(widget.categoria, v);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _tituloSheet(''),
        Text(
          'Orçamento — ${widget.categoria.titulo}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Quanto das suas entradas você quer destinar para '
          '${widget.categoria.titulo} este mês?',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _valor,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CentavosInputFormatter(moeda: false),
          ],
          decoration: const InputDecoration(
            labelText: 'Valor do orçamento',
            prefixText: 'R\$ ',
            prefixIcon: Icon(Icons.savings_outlined),
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
          label: const Text('Definir orçamento'),
        ),
      ],
    );
  }
}
