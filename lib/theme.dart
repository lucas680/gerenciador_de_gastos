import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';

/// Cores e tema do app (tema "dinheiro", em tons de verde).
class AppCores {
  static const Color verde = Color(0xFF107C48);
  static const Color verdeClaro = Color(0xFF22C55E);
  static const Color verdeFundo = Color(0xFFE8F5EE);
  static const Color vermelho = Color(0xFFE53935);
  static const Color amarelo = Color(0xFFFFC83C);
}

ThemeData construirTema() {
  final base = ColorScheme.fromSeed(
    seedColor: AppCores.verde,
    primary: AppCores.verde,
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: base,
    scaffoldBackgroundColor: const Color(0xFFF6F8F7),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppCores.verde,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppCores.verde,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Colors.white,
    ),
  );
}

/// Formata um valor double como moeda brasileira (R$ 1.234,56).
String formatarReal(double valor) =>
    'R\$ ${UtilBrasilFields.obterReal(valor, moeda: false)}';
