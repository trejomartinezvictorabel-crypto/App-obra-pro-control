// ============================================================================
// OBRA PRO - Calculadora, cotizador y biblioteca de obra (100% offline)
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
// CONTROLADOR Y MODELOS
// ============================================================================

class AppController extends ChangeNotifier {
  final SharedPreferences prefs;
  
  AppController._(this.prefs);

  static Future<AppController> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AppController._(prefs);
  }
}

// ============================================================================
// APLICACIÓN PRINCIPAL
// ============================================================================

class ObraProApp extends StatelessWidget {
  final AppController controller;
  const ObraProApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Obra Pro Control',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: HomeScreen(controller: controller),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final AppController controller;
  const HomeScreen({super.key, required this.controller});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _precioController = TextEditingController();
  double resultado = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Obra Pro Control'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'CALCULADORA DE MANO DE OBRA Y MATERIALES',
              style: TextStyle(
                color: AppColors.yellow,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _precioController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.white),
              decoration: const InputDecoration(
                labelText: 'Precio manual por unidad / jornada',
                labelStyle: TextStyle(color: AppColors.muted),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.yellow, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellow,
                foregroundColor: AppColors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                setState(() {
                  double val = double.tryParse(_precioController.text) ?? 0.0;
                  resultado = val;
                });
              },
              child: const Text(
                'CALCULAR',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Total: \$${resultado.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
