import 'package:flutter/material.dart';

import '../theme.dart';

/// Cartão de resumo global: Entradas | Saídas | Restante.
/// Usado no Dashboard e na tela de Entradas e Saídas.
class ResumoCard extends StatelessWidget {
  final double entradas;
  final double saidas;
  const ResumoCard({super.key, required this.entradas, required this.saidas});

  @override
  Widget build(BuildContext context) {
    final restante = entradas - saidas;
    return Card(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppCores.verde, AppCores.verdeClaro],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _item('Entradas', entradas, Icons.arrow_downward),
            _div(),
            _item('Saídas', saidas, Icons.arrow_upward),
            _div(),
            _item('Restante', restante, Icons.account_balance_wallet,
                destaque: true),
          ],
        ),
      ),
    );
  }

  Widget _div() => Container(width: 1, height: 44, color: Colors.white24);

  Widget _item(String titulo, double valor, IconData icone,
      {bool destaque = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(titulo,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          formatarReal(valor),
          style: TextStyle(
            color: valor < 0 ? const Color(0xFFFFCDD2) : Colors.white,
            fontSize: destaque ? 16 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Cartão de orçamento de categoria: Orçamento | Gasto | Restante.
/// Mostra uma barra de progresso e um botão para editar o orçamento.
class OrcamentoCard extends StatelessWidget {
  final String categoriaLabel;
  final double orcamento;
  final double gasto;
  final VoidCallback onEditar;

  const OrcamentoCard({
    super.key,
    required this.categoriaLabel,
    required this.orcamento,
    required this.gasto,
    required this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    final restante = orcamento - gasto;
    final semOrcamento = orcamento <= 0;
    final progresso = semOrcamento ? 0.0 : (gasto / orcamento).clamp(0.0, 1.0);
    final negativo = restante < 0;

    return Card(
      child: InkWell(
        onTap: onEditar,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: semOrcamento
                  ? [Colors.grey.shade600, Colors.grey.shade500]
                  : negativo
                      ? [const Color(0xFFB71C1C), const Color(0xFFE53935)]
                      : [AppCores.verde, AppCores.verdeClaro],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(16),
          child: semOrcamento ? _semOrcamento() : _comOrcamento(restante, progresso),
        ),
      ),
    );
  }

  Widget _semOrcamento() => Row(
    children: [
      const Icon(Icons.savings_outlined, color: Colors.white70),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sem orçamento definido',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text('Toque para destinar um valor para $categoriaLabel',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
      const Icon(Icons.edit, color: Colors.white70, size: 18),
    ],
  );

  Widget _comOrcamento(double restante, double progresso) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Orçamento: ${formatarReal(orcamento)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const Icon(Icons.edit, color: Colors.white70, size: 16),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _item('Gasto', gasto),
          Container(width: 1, height: 44, color: Colors.white24),
          _item('Restante', restante, destaque: true),
        ],
      ),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: progresso,
          minHeight: 6,
          backgroundColor: Colors.white24,
          valueColor: AlwaysStoppedAnimation<Color>(
            progresso >= 1 ? Colors.red.shade200 : Colors.white,
          ),
        ),
      ),
    ],
  );

  Widget _item(String titulo, double valor, {bool destaque = false}) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(titulo,
          style: const TextStyle(color: Colors.white70, fontSize: 12)),
      const SizedBox(height: 2),
      Text(
        formatarReal(valor),
        style: TextStyle(
          color: valor < 0 ? const Color(0xFFFFCDD2) : Colors.white,
          fontSize: destaque ? 16 : 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}

/// Estado vazio genérico.
class EstadoVazio extends StatelessWidget {
  final IconData icone;
  final String texto;
  const EstadoVazio({super.key, required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
