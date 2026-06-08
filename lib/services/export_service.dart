import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart' as xls;
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';

/// Serviço de exportação/importação de dados.
///
/// Permite:
///  - Exportar um backup em JSON e importá-lo em outro celular;
///  - Exportar uma planilha Excel (.xlsx);
///  - Exportar/imprimir um relatório em PDF.
class ExportService {
  final _dataFmt = DateFormat('dd/MM/yyyy');
  final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  String _fmtData(DateTime? d) => d == null ? '-' : _dataFmt.format(d);

  // ------------------------------------------------------------------
  // Backup JSON (usado para transferir os dados entre aparelhos)
  // ------------------------------------------------------------------

  Future<void> exportarBackupJson(FinanceData data) async {
    final dir = await getTemporaryDirectory();
    final agora = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
    final file = File('${dir.path}/controle_gastos_$agora.json');
    await file.writeAsString(jsonEncode(data.toJson()));
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Backup do Controle de Gastos',
        subject: 'Controle de Gastos - Backup',
      ),
    );
  }

  /// Abre o seletor de arquivos para o usuário escolher um backup .json
  /// gerado em outro aparelho e devolve os dados importados.
  Future<FinanceData?> importarBackupJson() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.single;
    String conteudo;
    if (picked.bytes != null) {
      conteudo = utf8.decode(picked.bytes!);
    } else if (picked.path != null) {
      conteudo = await File(picked.path!).readAsString();
    } else {
      return null;
    }
    final map = jsonDecode(conteudo) as Map<String, dynamic>;
    return FinanceData.fromJson(map);
  }

  // ------------------------------------------------------------------
  // Excel
  // ------------------------------------------------------------------

  Future<void> exportarExcel(MonthData data) async {
    final excel = xls.Excel.createExcel();
    final padrao = excel.getDefaultSheet();

    void cabecalho(xls.Sheet s, List<String> titulos) {
      s.appendRow(titulos.map((t) => xls.TextCellValue(t)).toList());
    }

    // Gastos gerais
    final gg = excel['Gastos gerais'];
    cabecalho(gg, ['Tipo de gasto', 'Data', 'Valor', 'Pago']);
    for (final e in data.gastosGerais) {
      gg.appendRow([
        xls.TextCellValue(e.tipo),
        xls.TextCellValue(_fmtData(e.data)),
        xls.DoubleCellValue(e.valor),
        xls.TextCellValue(e.pago ? 'Sim' : 'Não'),
      ]);
    }

    // Alimentação
    final al = excel['Alimentação'];
    cabecalho(al, ['Tipo de gasto', 'Data', 'Valor']);
    for (final e in data.alimentacao) {
      al.appendRow([
        xls.TextCellValue(e.tipo),
        xls.TextCellValue(_fmtData(e.data)),
        xls.DoubleCellValue(e.valor),
      ]);
    }

    // Gastos extras
    final ge = excel['Gastos extras'];
    cabecalho(ge, ['Tipo de gasto', 'Data', 'Valor']);
    for (final e in data.gastosExtras) {
      ge.appendRow([
        xls.TextCellValue(e.tipo),
        xls.TextCellValue(_fmtData(e.data)),
        xls.DoubleCellValue(e.valor),
      ]);
    }

    // Transporte
    final tr = excel['Transporte'];
    cabecalho(tr, ['Tipo de gasto', 'Q. Vezes', 'Valor', 'Total']);
    for (final e in data.transporte) {
      tr.appendRow([
        xls.TextCellValue(e.tipo),
        xls.IntCellValue(e.quantidade),
        xls.DoubleCellValue(e.valorUnitario),
        xls.DoubleCellValue(e.total),
      ]);
    }

    // Entradas e saídas (resumo)
    final es = excel['Entradas e Saídas'];
    cabecalho(es, ['Descrição', 'Data', 'Valor']);
    for (final e in data.entradas) {
      es.appendRow([
        xls.TextCellValue(e.descricao),
        xls.TextCellValue(_fmtData(e.data)),
        xls.DoubleCellValue(e.valor),
      ]);
    }

    // Remove a planilha padrão vazia gerada pelo pacote.
    if (padrao != null && excel.sheets.length > 1) {
      excel.delete(padrao);
    }

    final bytes = excel.save();
    if (bytes == null) return;
    final dir = await getTemporaryDirectory();
    final agora = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
    final file = File('${dir.path}/controle_gastos_$agora.xlsx');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Controle de Gastos - Excel',
      ),
    );
  }

  // ------------------------------------------------------------------
  // PDF
  // ------------------------------------------------------------------

  Future<pw.Document> _gerarPdf(
    MonthData data, {
    required double totalEntradas,
    required double totalSaidas,
  }) async {
    final doc = pw.Document();
    final restante = totalEntradas - totalSaidas;

    pw.Widget tabela(String titulo, List<String> colunas,
        List<List<String>> linhas) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 14),
          pw.Text(
            titulo,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF107C48),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.TableHelper.fromTextArray(
            headers: colunas,
            data: linhas,
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF22C55E),
            ),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 10),
          ),
        ],
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Controle de Gastos',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(
            'Gerado em ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE8F5EE),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _resumoPdf('Entradas', _moeda.format(totalEntradas)),
                _resumoPdf('Saídas', _moeda.format(totalSaidas)),
                _resumoPdf('Restante', _moeda.format(restante)),
              ],
            ),
          ),
          tabela(
            'Gastos gerais',
            ['Tipo', 'Data', 'Valor', 'Pago'],
            data.gastosGerais
                .map((e) => [
                      e.tipo,
                      _fmtData(e.data),
                      _moeda.format(e.valor),
                      e.pago ? 'Sim' : 'Não',
                    ])
                .toList(),
          ),
          tabela(
            'Transporte',
            ['Tipo', 'Q. Vezes', 'Valor', 'Total'],
            data.transporte
                .map((e) => [
                      e.tipo,
                      '${e.quantidade}',
                      _moeda.format(e.valorUnitario),
                      _moeda.format(e.total),
                    ])
                .toList(),
          ),
          tabela(
            'Alimentação',
            ['Tipo', 'Data', 'Valor'],
            data.alimentacao
                .map((e) =>
                    [e.tipo, _fmtData(e.data), _moeda.format(e.valor)])
                .toList(),
          ),
          tabela(
            'Gastos extras',
            ['Tipo', 'Data', 'Valor'],
            data.gastosExtras
                .map((e) =>
                    [e.tipo, _fmtData(e.data), _moeda.format(e.valor)])
                .toList(),
          ),
          tabela(
            'Entradas',
            ['Descrição', 'Data', 'Valor'],
            data.entradas
                .map((e) =>
                    [e.descricao, _fmtData(e.data), _moeda.format(e.valor)])
                .toList(),
          ),
        ],
      ),
    );
    return doc;
  }

  pw.Widget _resumoPdf(String titulo, String valor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(titulo,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(valor,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  Future<void> exportarPdf(
    MonthData data, {
    required double totalEntradas,
    required double totalSaidas,
  }) async {
    final doc = await _gerarPdf(
      data,
      totalEntradas: totalEntradas,
      totalSaidas: totalSaidas,
    );
    final bytes = await doc.save();
    final agora = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'controle_gastos_$agora.pdf',
    );
  }

  Future<void> imprimirPdf(
    MonthData data, {
    required double totalEntradas,
    required double totalSaidas,
  }) async {
    final doc = await _gerarPdf(
      data,
      totalEntradas: totalEntradas,
      totalSaidas: totalSaidas,
    );
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }
}
