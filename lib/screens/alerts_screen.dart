import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/finance_provider.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import '../widgets/resumo.dart';

/// Tela para criar e gerenciar alertas/notificações recorrentes.
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final alertas = provider.alertas;

    return Scaffold(
      appBar: AppBar(title: const Text('Alertas')),
      body: alertas.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: EstadoVazio(
                icone: Icons.notifications_active,
                texto: 'Nenhum alerta criado.\n\nCrie lembretes para registrar '
                    'seus gastos em dias e horários escolhidos por você.',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: alertas.length,
              itemBuilder: (context, i) {
                final a = alertas[i];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: a.ativo
                          ? AppCores.verdeFundo
                          : Colors.grey.shade200,
                      child: Icon(
                        Icons.alarm,
                        color: a.ativo ? AppCores.verde : Colors.grey,
                      ),
                    ),
                    title: Text(
                      a.mensagem,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('${a.horarioFormatado} • ${a.diasFormatados}'),
                    trailing: Switch(
                      value: a.ativo,
                      activeThumbColor: AppCores.verde,
                      onChanged: (v) {
                        a.ativo = v;
                        provider.atualizarAlerta(a);
                      },
                    ),
                    onTap: () => _abrirEditor(context, provider, existente: a),
                    onLongPress: () => provider.removerAlerta(a.id),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
            heroTag: null,
        onPressed: () => _abrirEditor(context, provider),
        icon: const Icon(Icons.add_alert),
        label: const Text('Novo alerta'),
      ),
    );
  }

  void _abrirEditor(
    BuildContext context,
    FinanceProvider provider, {
    AlertConfig? existente,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditorAlerta(provider: provider, existente: existente),
    );
  }
}

class _EditorAlerta extends StatefulWidget {
  final FinanceProvider provider;
  final AlertConfig? existente;
  const _EditorAlerta({required this.provider, this.existente});

  @override
  State<_EditorAlerta> createState() => _EditorAlertaState();
}

class _EditorAlertaState extends State<_EditorAlerta> {
  late TextEditingController _mensagem;
  late TimeOfDay _hora;
  late Set<int> _dias;

  @override
  void initState() {
    super.initState();
    final a = widget.existente;
    _mensagem = TextEditingController(
      text: a?.mensagem ?? 'Não esqueça de registrar seus gastos de hoje!',
    );
    _hora = a != null
        ? TimeOfDay(hour: a.hora, minute: a.minuto)
        : const TimeOfDay(hour: 8, minute: 0);
    _dias = a?.diasSemana.toSet() ?? {1, 2, 3, 4, 5};
  }

  @override
  void dispose() {
    _mensagem.dispose();
    super.dispose();
  }

  Future<void> _escolherHora() async {
    final t = await showTimePicker(context: context, initialTime: _hora);
    if (t != null) setState(() => _hora = t);
  }

  Future<void> _salvar() async {
    if (_mensagem.text.trim().isEmpty || _dias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe a mensagem e ao menos um dia da semana.'),
        ),
      );
      return;
    }
    // Garante permissão de notificação antes de agendar.
    await NotificationService().solicitarPermissao();

    final dias = _dias.toList()..sort();
    final alerta = AlertConfig(
      id: widget.existente?.id ??
          (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 100000000,
      mensagem: _mensagem.text.trim(),
      hora: _hora.hour,
      minuto: _hora.minute,
      diasSemana: dias,
      ativo: true,
    );

    if (widget.existente == null) {
      await widget.provider.adicionarAlerta(alerta);
    } else {
      await widget.provider.atualizarAlerta(alerta);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final novo = widget.existente == null;
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
            novo ? 'Novo alerta' : 'Editar alerta',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _mensagem,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Mensagem da notificação',
              prefixIcon: Icon(Icons.message_outlined),
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: _escolherHora,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Horário',
                prefixIcon: Icon(Icons.access_time),
              ),
              child: Text(
                _hora.format(context),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Dias da semana',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: List.generate(7, (i) {
              final dia = i + 1; // 1=Seg ... 7=Dom
              final sel = _dias.contains(dia);
              return FilterChip(
                label: Text(AlertConfig.nomesDias[i]),
                selected: sel,
                selectedColor: AppCores.verde,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: sel ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (v) => setState(() {
                  if (v) {
                    _dias.add(dia);
                  } else {
                    _dias.remove(dia);
                  }
                }),
              );
            }),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: const Text('Seg a Sex'),
                onPressed: () => setState(() => _dias = {1, 2, 3, 4, 5}),
              ),
              ActionChip(
                label: const Text('Todos os dias'),
                onPressed: () =>
                    setState(() => _dias = {1, 2, 3, 4, 5, 6, 7}),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppCores.verde,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _salvar,
            icon: const Icon(Icons.check),
            label: Text(novo ? 'Criar alerta' : 'Salvar'),
          ),
        ],
      ),
    );
  }
}
