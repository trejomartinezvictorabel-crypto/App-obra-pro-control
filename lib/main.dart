import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
//  OBRA PRO CONTROL - App offline de control y cotizacion de obra
// ============================================================

class AppColors {
  static const Color fondo = Color(0xFF000000);
  static const Color acento = Color(0xFFFFC400);
  static const Color tarjeta = Color(0xFF121212);
  static const Color borde = Color(0xFF2E2E2E);
  static const Color textoClaro = Color(0xFFFFFFFF);
  static const Color textoGris = Color(0xFFB0B0B0);
  static const Color error = Color(0xFFFF5252);
}

const String kPinKey = 'obra_pin';
const String kItemsKey = 'obra_items';
const String kPinDefault = '1234';

const List<Map<String, String>> kUnidades = [
  {'key': 'm', 'label': 'm (Lineales)'},
  {'key': 'm2', 'label': 'm² (Cuadrados - Losa/Firme)'},
  {'key': 'm3', 'label': 'm³ (Cúbicos - Zapatas/Concreto)'},
  {'key': 'pza', 'label': 'Pza / Unidades'},
  {'key': 'jornada', 'label': 'Jornada / Día'},
];

const List<Map<String, String>> kEtapas = [
  {
    'titulo': 'Excavación y Movimiento de Tierra',
    'descripcion':
        'Preparación del terreno: limpieza, trazo, nivelación y excavación hasta el nivel de desplante.',
    'pasos':
        'Limpiar y deshierbar el terreno.|Trazar ejes y niveles con hilo, estacas y manguera de nivel.|Excavar zanjas según planos (profundidad y ancho de zapata).|Verificar que el fondo sea firme y esté a nivel.|Compactar el fondo con pisón o bailarina.|Retirar el material sobrante o acomodarlo lejos de la zanja.',
  },
  {
    'titulo': 'Cimentación y Zapatas',
    'descripcion':
        'Base que transmite el peso de la construcción al suelo: plantilla, armado, cimbra y colado.',
    'pasos':
        'Colar plantilla de concreto pobre (5 cm) para limpiar el fondo.|Armar el acero de zapatas y contratrabes según plano.|Colocar separadores (galletas) para respetar el recubrimiento.|Habilitar cimbra o contener los lados de la zanja.|Colar concreto y vibrar para evitar huecos.|Curar con agua durante al menos 3 días.|Dejar arranques de columnas y castillos a plomo.',
  },
  {
    'titulo': 'Estructura y Muros',
    'descripcion':
        'Levantado de muros, castillos y cadenas que forman el esqueleto de la edificación.',
    'pasos':
        'Colocar la primera hilada a nivel con mortero y verificar escuadra.|Levantar muros a plomo con hilo guía.|Armar castillos y cadenas de cerramiento.|Colar castillos en tramos, vibrando bien.|Dejar preparados vanos de puertas y ventanas.|Colocar dalas y cerramientos sobre vanos.|Revisar plomos y niveles antes de continuar.',
  },
  {
    'titulo': 'Losa y Entrepiso',
    'descripcion':
        'Techo o piso intermedio: cimbra, armado de acero, instalaciones previas y colado.',
    'pasos':
        'Colocar cimbra, polines y puntales bien apuntalados.|Armar parrilla o malla y cuchillas/vigas según diseño.|Dejar pasos y preparaciones para instalaciones.|Colocar bastones y refuerzos en apoyos.|Revisar niveles y recubrimientos con separadores.|Colar de forma continua y vibrar el concreto.|Curar la losa y descimbrar hasta alcanzar la resistencia indicada.',
  },
  {
    'titulo': 'Instalaciones Ocultas',
    'descripcion':
        'Tuberías hidráulicas, sanitarias, gas y ductos eléctricos que quedan dentro de muros y pisos.',
    'pasos':
        'Marcar recorridos de tuberías y registros.|Abrir canalizaciones (ranuras) en muros sin dañar castillos.|Instalar tubería sanitaria con pendiente adecuada.|Instalar tubería hidráulica y hacer prueba de presión.|Colocar ductos y cajas eléctricas a las alturas de proyecto.|Pasar guías para cableado.|Tapar canalizaciones solo después de aprobar las pruebas.',
  },
  {
    'titulo': 'Aplanados y Falsos Rys',
    'descripcion':
        'Acabados base en muros y plafones: repellado, aplanado fino, boquillas y remates.',
    'pasos':
        'Humedecer el muro antes de apl
