// ============================================================================
// OBRA PRO - Calculadora, cotizador y biblioteca de obra (100% offline)
// Incluye: Bloqueo de PIN, Cálculos con Cuchillas, Parrilla/Alambre y Materiales
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
      titleTextStyle: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w800),
    ),
  );
}

// ============================================================================
// MODELOS Y CONTROLADOR
// ============================================================================

class ItemPresupuesto {
  String concepto;
  String tipoMedida; // m, m², m³, Pza, etc.
  double cantidad;
  double precioUnitario;
  String detalleMateriales; // Desglose de cuchillas, parrilla, alambre, etc.

  ItemPresupuesto({
    required this.concepto,
    required this.tipoMedida,
    required this.cantidad,
    required this.precioUnitario,
    required this.detalleMateriales,
  });

  double get subtotal => cantidad * precioUnitario;
}

class AppController extends ChangeNotifier {
  final SharedPreferences prefs;
  bool isLocked = true;

  AppController._(this.prefs) {
    if (!prefs.containsKey('user_pin')) {
      prefs.setString('user_pin', '1234');
    }
  }

  static Future<AppController> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AppController._(prefs);
  }

  bool verificarPin(String pinIngresado) {
    final pinGuardado = prefs.getString('user_pin') ?? '1234';
    if (pinIngresado == pinGuardado) {
      isLocked = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  void bloquear() {
    isLocked = true;
    notifyListeners();
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
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'Obra Pro Control',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          home: controller.isLocked ? PinScreen(controller: controller) : MainNavigationScreen(controller: controller),
        );
      },
    );
  }
}

// ============================================================================
// PANTALLA DE BLOQUEO DE PIN
// ============================================================================

class PinScreen extends StatefulWidget {
  final AppController controller;
  const PinScreen({super.key, required this.controller});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final TextEditingController _pinController = TextEditingController();
  String mensajeError = '';

  void _intentarDesbloquear() {
    bool ok = widget.controller.verificarPin(_pinController.text.trim());
    if (!ok) {
      setState(() {
        mensajeError = 'PIN Incorrecto (Prueba con 1234)';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_outline, size: 70, color: AppColors.yellow),
              const SizedBox(height: 20),
              const Text(
                'OBRA PRO SEGURIDAD',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ingresa tu PIN de acceso',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                style: const TextStyle(color: AppColors.white, fontSize: 24, letterSpacing: 8),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: '',
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.yellow, width: 2), borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (mensajeError.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(mensajeError, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)),
              ],
              const SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellow,
                  foregroundColor: AppColors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _intentarDesbloquear,
                child: const Text('DESBLOQUEAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// NAVEGACIÓN PRINCIPAL
// ============================================================================

class MainNavigationScreen extends StatefulWidget {
  final AppController controller;
  const MainNavigationScreen({super.key, required this.controller});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<ItemPresupuesto> _presupuestoItems = [];

  @override
  Widget build(BuildContext context) {
    final List<Widget> pantallas = [
      CalculadoraMedidasScreen(items: _presupuestoItems, onActualizar: () => setState(() {})),
      const BibliotecaObraScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Obra Pro Control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock, color: AppColors.yellow),
            tooltip: 'Bloquear app',
            onPressed: () => widget.controller.bloquear(),
          ),
        ],
      ),
      body: pantallas[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: AppColors.black,
        selectedItemColor: AppColors.yellow,
        unselectedItemColor: AppColors.muted,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'Calculadora'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Biblioteca Obra'),
        ],
      ),
    );
  }
}

// ============================================================================
// PESTAÑA 1: CALCULADORA CON CÁLCULO DE CUCHILLAS, PARRILLAS Y ALAMBRE
// ============================================================================

class CalculadoraMedidasScreen extends StatefulWidget {
  final List<ItemPresupuesto> items;
  final VoidCallback onActualizar;

  const CalculadoraMedidasScreen({super.key, required this.items, required this.onActualizar});

  @override
  State<CalculadoraMedidasScreen> createState() => _CalculadoraMedidasScreenState();
}

class _CalculadoraMedidasScreenState extends State<CalculadoraMedidasScreen> {
  final TextEditingController _conceptoCtrl = TextEditingController();
  final TextEditingController _cantidadCtrl = TextEditingController();
  final TextEditingController _precioCtrl = TextEditingController();
  String _tipoMedidaSeleccionada = 'm² (Cuadrados)';

  final List<String> _opcionesMedida = [
    'm (Lineales)',
    'm² (Cuadrados - Losa/Firme)',
    'm³ (Cúbicos - Zapatas/Concreto)',
    'Pza / Unidades',
    'Jornada / Día',
  ];

  void _agregarConcepto() {
    String concepto = _conceptoCtrl.text.trim();
    double cantidad = double.tryParse(_cantidadCtrl.text) ?? 0.0;
    double precio = double.tryParse(_precioCtrl.text) ?? 0.0;

    if (concepto.isNotEmpty && cantidad > 0 && precio > 0) {
      // Generar estimación automática de acero, cuchillas, parrilla y alambre según la medida
      String desglose = '';
      if (_tipoMedidaSeleccionada.contains('Cuadrados')) {
        double malla = cantidad; // 1 m² de malla por cada m² de losa
        double alambre = cantidad * 0.15; // aprox 150g de alambre por m²
        double cuchillas = cantidad * 0.8; // estimación de tramos de acero/cuchilla
        desglose = 'Est. Materiales: ${malla.toStringAsFixed(1)} m² malla | ${cuchillas.toStringAsFixed(1)} m. cuchillas | ${alambre.toStringAsFixed(1)} kg alambre';
      } else if (_tipoMedidaSeleccionada.contains('Cúbicos')) {
        double varillaArmado = cantidad * 12; // varilla estimada por m³ de estructura
        double alambre = cantidad * 0.8; 
        desglose = 'Est. Materiales: ${varillaArmado.toStringAsFixed(1)} m. varilla/cuchilla | ${alambre.toStringAsFixed(1)} kg alambre';
      } else {
        desglose = 'Medida directa por ${_tipoMedidaSeleccionada}';
      }

      setState(() {
        widget.items.add(ItemPresupuesto(
          concepto: concepto,
          tipoMedida: _tipoMedidaSeleccionada,
          cantidad: cantidad,
          precioUnitario: precio,
          detalleMateriales: desglose,
        ));
        _conceptoCtrl.clear();
        _cantidadCtrl.clear();
        _precioCtrl.clear();
      });
      widget.onActualizar();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rellena todos los campos con valores válidos'), backgroundColor: AppColors.danger),
      );
    }
  }

  double get _totalGeneral {
    double t = 0;
    for (var i in widget.items) {
      t += i.subtotal;
    }
    return t;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('COTIZADOR Y CÁLCULO DE MATERIALES', style: TextStyle(color: AppColors.yellow, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          TextField(
            controller: _conceptoCtrl,
            style: const TextStyle(color: AppColors.white),
            decoration: const InputDecoration(
              labelText: 'Concepto (Ej. Losa de azotea, Cimentación, Muro)',
              labelStyle: TextStyle(color: AppColors.muted),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.cardBorder)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.yellow, width: 2)),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _tipoMedidaSeleccionada,
            dropdownColor: AppColors.card,
            style: const TextStyle(color: AppColors.white),
            decoration: const InputDecoration(
              labelText: 'Tipo de Medida / Unidad',
              labelStyle: TextStyle(color: AppColors.muted),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.cardBorder)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.yellow, width: 2)),
            ),
            items: _opcionesMedida.map((val) {
              return DropdownMenuItem(value: val, child: Text(val));
            }).toList(),
            onChanged: (val) => setState(() => _tipoMedidaSeleccionada = val!),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cantidadCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.white),
                  decoration: const InputDecoration(
                    labelText: 'Cantidad / Medida',
                    labelStyle: TextStyle(color: AppColors.muted),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.cardBorder)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.yellow, width: 2)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _precioCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.white),
                  decoration: const InputDecoration(
                    labelText: 'Precio manual unitario',
                    labelStyle: TextStyle(color: AppColors.muted),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.cardBorder)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.yellow, width: 2)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.yellow,
              foregroundColor: AppColors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _agregarConcepto,
            child: const Text('AGREGAR CONCEPTO Y CALCULAR', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          const Text('CONCEPTOS Y MATERIALES ESTIMADOS:', style: TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: widget.items.isEmpty
                ? const Center(child: Text('No hay conceptos en la lista.', style: TextStyle(color: AppColors.hint)))
                : ListView.builder(
                    itemCount: widget.items.length,
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      return Card(
                        color: AppColors.card,
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: AppColors.cardBorder),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.between,
                                children: [
                                  Text(item.concepto, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('\$${item.subtotal.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.yellow, fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('${item.cantidad} ${item.tipoMedida} x \$${item.precioUnitario.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                              if (item.detalleMateriales.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.black,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.cardBorder),
                                  ),
                                  child: Text(item.detalleMateriales, style: const TextStyle(color: AppColors.yellow, fontSize: 12)),
                                ),
                              ],
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  icon: const Icon(Icons.delete, color: AppColors.danger, size: 18),
                                  label: const Text('Eliminar', style: TextStyle(color: AppColors.danger)),
                                  onPressed: () {
                                    setState(() {
                                      widget.items.removeAt(index);
                                    });
                                    widget.onActualizar();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.yellow, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL GENERAL:', style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text('\$${_totalGeneral.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.yellow, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PESTAÑA 2: BIBLIOTECA DE OBRA (De Excavación a Muebles y Accesorios)
// ============================================================================

class BibliotecaObraScreen extends StatelessWidget {
  const BibliotecaObraScreen({super.key});

  final List> etapasObra = const [
    {
      'etapa': '1. Excavación y Movimiento de Tierra',
      'desc': 'Cortes, cepas, retiro de escombro, nivelación y compactación de terreno.'
    },
    {
      'etapa': '2. Cimentación y Zapatas',
      'desc': 'Armado de acero, plantillas de concreto pobre, zapatas corridas y aisladas, dala de desplante.'
    },
    {
      'etapa': '3. Estructura y Muros',
      'desc': 'Levantamiento de columnas, castillos, trabes, muros de tabique o block y cerramientos.'
    },
    {
      'etapa': '4. Losa y Entrepiso',
      'desc': 'Cimbra, colocación de vigueta y bovedilla o losa maciza, malla electrosoldada y colado.'
    },
    {
      'etapa': '5. Instalaciones Ocultas',
      'desc': 'Tuberías hidráulicas, sanitarias, eléctricas, registros y salidas de gas.'
    },
    {
      'etapa': '6. Aplanados y Falsos Rys',
      'desc': 'Revoques, zarpeo, afine en muros, yeso o pasta en techos.'
    },
    {
      'etapa': '7. Pisos y Revestimientos',
      'desc': 'Colocación de firmes de concreto, loseta cerámica, azulejos en baños y zoclos.'
    },
    {
      'etapa': '8. Pintura e Impermeabilización',
      'desc': 'Sellador, aplicación de impermeabilizante en azoteas y pintura vinílica en muros.'
    },
    {
      'etapa': '9. Muebles y Accesorios Finales',
      'desc': 'Colocación de sanitarios, lavavabos, llaves, apagadores, contactos, chapas y puertas.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'BIBLIOTECA TÉCNICA DE OBRA',
            style: TextStyle(color: AppColors.yellow, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            'Secuencia constructiva desde la excavación hasta los acabados y accesorios:',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: etapasObra.length,
              itemBuilder: (context, index) {
                final etapa = etapasObra[index];
                return Card(
                  color: AppColors.card,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          etapa['etapa']!,
                          style: const TextStyle(color: AppColors.yellow, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          etapa['desc']!,
                          style: const TextStyle(color: AppColors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
