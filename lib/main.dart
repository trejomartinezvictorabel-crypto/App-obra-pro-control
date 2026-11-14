// ============================================================================
// OBRA PRO - Calculadora, cotizador y biblioteca de obra (100% offline)
// ============================================================================
//
// DEPENDENCIAS (agregar en pubspec.yaml, sección dependencies):
//
//   dependencies:
//     flutter:
//       sdk: flutter
//     shared_preferences: ^2.3.2
//     image_picker: ^1.1.2
//     share_plus: ^10.1.4
//     path_provider: ^2.1.4
//     path: ^1.9.0
//     crypto: ^3.0.5
//
// ANDROID (android/app/build.gradle o build.gradle.kts):
//   compileSdk = 36
//   targetSdk  = 36
//   minSdk     = 24
//   Usa Flutter estable reciente y Java 17.
//
// ANDROID MANIFEST: ver el archivo AndroidManifest.xml entregado junto a este.
//
// Toda la información (borrador, fotos y presupuestos guardados) se guarda en
// la memoria interna del teléfono. No se usa internet en ningún momento.
// ============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// PUNTO DE ENTRADA
// ============================================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF000000),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  final AppController controller = await AppController.create();
  runApp(ObraProApp(controller: controller));
}

// ============================================================================
// COLORES Y TEMA
// ============================================================================

class AppColors {
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color yellow = Color(0xFFFFC400);
  static const Color orange = Color(0xFFFF8F00);
  static const Color card = Color(0xFF121212);
  static const Color cardBorder = Color(0xFF2E2E2E);
  static const Color muted = Color(0xFFB5B5B5);
  static const Color hint = Color(0xFF707070);
  static const Color danger = Color(0xFFFF5252);
}

ThemeData buildTheme() {
  const ColorScheme scheme = ColorScheme.dark(
    primary: AppColors.yellow,
    onPrimary: AppColors.black,
    secondary: AppColors.orange,
    onSecondary: AppColors.black,
    surface: AppColors.black,
    onSurface: AppColors.white,
    error: AppColors.danger,
    onError: AppColors.black,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.black,
    canvasColor: AppColors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.black,
      foregroundColor: AppColors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.white,
        fontSize: 24,
        fontWeight: FontWeight.w800,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.white, fontSize: 18),
      bodyMedium: TextStyle(color: AppColors.white, fontSize: 17),
      titleMedium: TextStyle(color: AppColors.white, fontSize: 20),
    ),
  );
}

// ============================================================================
// UTILIDADES
// ============================================================================

String format
