import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/finance_provider.dart';
import '../services/export_service.dart';
import '../theme.dart';
import 'alerts_screen.dart';
import 'dashboard_screen.dart';
import 'expense_list_screen.dart';
import 'income_screen.dart';
import 'template_screen.dart';
import 'transport_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indice = 0;
  final ExportService _export = ExportService();

  static const _titulos = [
    'Início',
    'Transporte',
    'Alimentação',
    'Extras',
    'Entradas e Saídas',
  ];

  final _telas = const [
    DashboardScreen(),
    TransportScreen(),
    ExpenseListScreen(
      categoria: Categoria.alimentacao,
      icone: Icons.restaurant,
    ),
    ExpenseListScreen(
      categoria: Categoria.gastosExtras,
      icone: Icons.shopping_bag,
    ),
    IncomeScreen(),
  ];

  Future<void> _executarExport(
    Future<void> Function() acao,
    String emAndamento,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text(emAndamento)));
    try {
      await acao();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: AppCores.vermelho),
      );
    }
  }

  void _abrirMenu(FinanceProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Opções',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Exportar para Excel'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _executarExport(
                  () => _export.exportarExcel(provider.mesAtualData),
                  'Gerando Excel...',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Exportar para PDF'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _executarExport(
                  () => _export.exportarPdf(
                    provider.mesAtualData,
                    totalEntradas: provider.totalEntradas,
                    totalSaidas: provider.totalSaidas,
                  ),
                  'Gerando PDF...',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.print, color: Colors.blueGrey),
              title: const Text('Imprimir PDF'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _executarExport(
                  () => _export.imprimirPdf(
                    provider.mesAtualData,
                    totalEntradas: provider.totalEntradas,
                    totalSaidas: provider.totalSaidas,
                  ),
                  'Abrindo impressão...',
                );
              },
            ),
            const Divider(),
            ListTile(
              leading:
                  const Icon(Icons.backup, color: AppCores.verde),
              title: const Text('Exportar backup (todos os meses)'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _executarExport(
                  () => _export.exportarBackupJson(provider.data),
                  'Gerando backup...',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore, color: AppCores.verde),
              title: const Text('Importar dados'),
              onTap: () async {
                Navigator.pop(sheetCtx);
                await _importar(provider);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _importar(FinanceProvider provider) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final dados = await _export.importarBackupJson();
      if (dados == null) return;
      if (!mounted) return;
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Importar dados'),
          content: const Text(
            'Isso vai substituir todos os dados atuais pelos do backup. '
            'Deseja continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppCores.verde),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Importar'),
            ),
          ],
        ),
      );
      if (confirmar == true) {
        await provider.importar(dados);
        messenger.showSnackBar(
          const SnackBar(content: Text('Dados importados!')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Não foi possível importar: $e'),
          backgroundColor: AppCores.vermelho,
        ),
      );
    }
  }

  /// Abre um diálogo para o usuário escolher qualquer mês com dados.
  void _mostrarSeletorMeses(FinanceProvider provider) {
    final meses = provider.mesesComDados;
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Selecionar mês'),
        children: meses.map((key) {
          final parts = key.split('-');
          final dt =
              DateTime(int.parse(parts[0]), int.parse(parts[1]));
          final ativo = provider.anoAtual == dt.year &&
              provider.mesAtual == dt.month;
          return SimpleDialogOption(
            onPressed: () {
              provider.irParaMes(dt.year, dt.month);
              Navigator.pop(ctx);
            },
            child: Text(
              DateFormat('MMMM yyyy', 'pt_BR').format(dt),
              style: TextStyle(
                fontWeight:
                    ativo ? FontWeight.bold : FontWeight.normal,
                color: ativo ? AppCores.verde : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();

    if (provider.carregando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final mesLabel = DateFormat('MMMM yyyy', 'pt_BR')
        .format(provider.dataMesAtual);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botão mês anterior
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: provider.mesAnterior,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            // Label clicável abre seletor de meses
            GestureDetector(
              onTap: () => _mostrarSeletorMeses(provider),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _titulos[_indice],
                      style: const TextStyle(
                          fontSize: 14, color: Colors.white70),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          mesLabel,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down,
                            color: Colors.white70, size: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Botão próximo mês
            IconButton(
              icon: Icon(
                Icons.chevron_right,
                color: provider.podeIrProximoMes
                    ? Colors.white
                    : Colors.white30,
              ),
              onPressed:
                  provider.podeIrProximoMes ? provider.proximoMes : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Alertas',
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AlertsScreen()),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              switch (v) {
                case 'export':
                  _abrirMenu(provider);
                case 'template':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TemplateScreen()),
                  );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Exportar / Importar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'template',
                child: ListTile(
                  leading: Icon(Icons.edit_note),
                  title: Text('Editar template padrão'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _indice, children: _telas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        indicatorColor: AppCores.verdeFundo,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppCores.verde),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_bus_outlined),
            selectedIcon:
                Icon(Icons.directions_bus, color: AppCores.verde),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon:
                Icon(Icons.restaurant, color: AppCores.verde),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon:
                Icon(Icons.shopping_bag, color: AppCores.verde),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_vert_outlined),
            selectedIcon: Icon(Icons.swap_vert, color: AppCores.verde),
            label: '',
          ),
        ],
      ),
    );
  }
}
