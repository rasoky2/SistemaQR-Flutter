import 'dart:math';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Utilidades matemáticas para el modelo QR de inventario
class MathUtils {
  /// PDF de la distribución normal estándar
  /// φ(x) = exp(-0.5 * x^2) / sqrt(2π)
  static double normalPdf(double x) {
    return exp(-0.5 * x * x) / sqrt(2 * pi);
  }

  /// CDF de la distribución normal estándar usando aproximación de error function
  /// Φ(x) ≈ 0.5 * (1 + erf(x / sqrt(2)))
  /// Se usa la aproximación de Abramowitz y Stegun fórmula 7.1.26
  static double normalCdf(double x) {
    // Aproximación de Abramowitz y Stegun fórmula 7.1.26
    const a1 = 0.254829592;
    const a2 = -0.284496736;
    const a3 = 1.421413741;
    const a4 = -1.453152027;
    const a5 = 1.061405429;
    const p = 0.3275911;

    final sign = x < 0 ? -1 : 1;
    final absX = x.abs() / sqrt(2);
    final t = 1.0 / (1.0 + p * absX);
    // y ≈ 1 - (((((a5*t + a4)*t + a3)*t + a2)*t + a1)*t) * exp(-absX^2)
    final y = 1.0 -
        (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) *
            t *
            exp(-absX * absX);
    return 0.5 * (1.0 + sign * y);
  }

  /// Función de pérdida normal estándar L(z)
  /// L(z) = φ(z) - z * (1 - Φ(z))
  static double normalLossFunction(double z) {
    final phi = normalPdf(z);
    final phiCdf = normalCdf(z);
    return phi - z * (1 - phiCdf);
  }

  /// Calcula el z-score para un punto de reorden dado
  /// z = (R - μL) / σL
  static double calcularZScore(
      double puntoReorden, double demandaLeadTime, double desviacionLeadTime) {
    return (puntoReorden - demandaLeadTime) / desviacionLeadTime;
  }

  /// Calcula la demanda en el lead time
  /// μL = D * (L / 365)
  static double calcularDemandaLeadTime(
      double demandaAnual, double leadTimeDias) {
    return demandaAnual * (leadTimeDias / 365.0);
  }

  /// Calcula la desviación estándar en el lead time
  /// σL = σD * sqrt(L)
  static double calcularDesviacionLeadTime(
      double desviacionDiaria, double leadTimeDias) {
    return desviacionDiaria * sqrt(leadTimeDias);
  }

  /// Calcula los backorders esperados
  /// E[BO] = σL * L(z)
  static double calcularBackordersEsperados(
      double desviacionLeadTime, double zScore) {
    final lz = normalLossFunction(zScore);
    return desviacionLeadTime * lz;
  }

  /// Calcula el stock de seguridad
  /// SS = max(0, R - μL)
  static double calcularStockSeguridad(
      double puntoReorden, double demandaLeadTime) {
    final ss = puntoReorden - demandaLeadTime;
    return ss > 0 ? ss : 0.0;
  }

  /// Inventario promedio anual con backorders en política (Q, R)
  /// \bar{I} = Q/2 + SS - E[BO], truncado a 0
  static double calcularInventarioPromedio(
    double tamanoLote,
    double stockSeguridad,
    double backordersEsperados,
  ) {
    final inv = (tamanoLote / 2.0) + stockSeguridad - backordersEsperados;
    return inv > 0 ? inv : 0.0;
  }

  /// Inventario promedio para costo de mantenimiento según fórmula
  /// I_h = max(0, (Q - E[BO]) / 2)
  static double calcularInventarioPromedioHolding(
    double tamanoLote,
    double backordersEsperados,
  ) {
    final inv = (tamanoLote - backordersEsperados) / 2.0;
    return inv > 0 ? inv : 0.0;
  }

  /// Componente: Costo de pedidos anual Ck = (D/Q) * K
  static double calcularCostoPedidosComponent(
      double demandaAnual, double tamanoLote, double costoPedido) {
    return (demandaAnual / tamanoLote) * costoPedido;
  }

  /// Componente: Costo de mantenimiento anual Ch = \bar{I} * h
  static double calcularCostoMantenimientoComponent(
      double inventarioPromedio, double costoMantenimiento) {
    return inventarioPromedio * costoMantenimiento;
  }

  /// Componente: Costo de faltante anual Cp = (D/Q) * E[BO] * p
  static double calcularCostoServicioComponent(
    double demandaAnual,
    double tamanoLote,
    double backordersEsperados,
    double costoFaltante,
  ) {
    // Versión anual clásica: (D/Q) * E[BO] * p
    return (demandaAnual / tamanoLote) * backordersEsperados * costoFaltante;
  }

  /// Componente de costo de faltante usando solo E[BO] * p (sin factor D/Q)
  static double calcularCostoServicioComponentEBOPuro(
    double backordersEsperados,
    double costoFaltante,
  ) {
    return backordersEsperados * costoFaltante;
  }

  /// Costo total anual C = Ck + Ch + Cp (política Q,R con backorders)
  static double calcularCostoTotalQR({
    required double demandaAnual,
    required double tamanoLote,
    required double costoPedido,
    required double inventarioPromedio,
    required double costoMantenimiento,
    required double backordersEsperados,
    required double costoFaltante,
  }) {
    // Por requerimiento de negocio, el costo total debe seguir:
    // C = (D/Q)*K + ((Q/2) - E[BO]) * h + E[BO] * p
    final cK =
        calcularCostoPedidosComponent(demandaAnual, tamanoLote, costoPedido);
    final cH = calcularCostoMantenimientoComponent(
        inventarioPromedio, costoMantenimiento);
    final cP = calcularCostoServicioComponentEBOPuro(
        backordersEsperados, costoFaltante);
    return cK + cH + cP;
  }

  /// Calcula el costo total de un artículo
  /// C = (D/Q)*K + ((Q - E[BO])/2)*h + E[BO]*p
  static double calcularCostoTotal({
    required double demandaAnual,
    required double tamanoLote,
    required double costoPedido,
    required double backordersEsperados,
    required double costoMantenimiento,
    required double costoFaltante,
  }) {
    // (D/Q)*K
    final costoPedidos = (demandaAnual / tamanoLote) * costoPedido;
    // ((Q - E[BO])/2)*h
    final costoMantenimientoInv =
        ((tamanoLote - backordersEsperados) / 2) * costoMantenimiento;
    // E[BO]*p
    final costoServicio = backordersEsperados * costoFaltante;

    return costoPedidos + costoMantenimientoInv + costoServicio;
  }

  /// Calcula el tamaño de lote EOQ clásico
  /// Q* = sqrt( 2 * D * K / h )
  static double calcularEOQ(
      double demandaAnual, double costoPedido, double costoMantenimiento) {
    if (demandaAnual <= 0 || costoPedido <= 0 || costoMantenimiento <= 0) {
      return 1.0;
    }
    final valor = 2 * demandaAnual * costoPedido / costoMantenimiento;
    final q = sqrt(valor);
    if (!q.isFinite || q <= 0) {
      return 1.0;
    }
    return q;
  }

  /// Calcula el espacio usado por un artículo
  /// Espacio = R * s
  static double calcularEspacioUsado(
      double puntoReorden, double espacioUnidad) {
    return puntoReorden * espacioUnidad;
  }

  /// Calcula el número de pedidos por año
  /// N = D / Q
  static double calcularNumeroPedidos(double demandaAnual, double tamanoLote) {
    return demandaAnual / tamanoLote;
  }

  /// Presupuesto para un artículo: c * R
  static double calcularPresupuestoArticulo(
      double costoUnitario, double puntoReorden) {
    return costoUnitario * puntoReorden;
  }

  /// Valida las restricciones del sistema
  /// Retorna un mapa con el cumplimiento de cada restricción
  static Map<String, bool> validarRestricciones({
    required double espacioTotal,
    required double espacioMaximo,
    required double presupuestoTotal,
    required double presupuestoMaximo,
    required double numeroTotalPedidos,
    required double numeroMaximoPedidos,
  }) {
    return {
      'espacio': espacioTotal <= espacioMaximo,
      'presupuesto': presupuestoTotal <= presupuestoMaximo,
      'pedidos': numeroTotalPedidos <= numeroMaximoPedidos,
    };
  }

  // Configuración de formato para la UI: 'coma_punto', 'punto_coma', 'comilla_punto'
  static String formatoNumeroUI = 'punto_coma';

  static String _aplicarFormatoUI(String valorEnUS) {
    switch (formatoNumeroUI) {
      case 'punto_coma':
        // Reemplazar , por temporal, . por , y temporal por .
        return valorEnUS.replaceAll(',', '_').replaceAll('.', ',').replaceAll('_', '.');
      case 'comilla_punto':
        // Reemplazar , por '
        return valorEnUS.replaceAll(',', "'");
      case 'coma_punto':
      default:
        return valorEnUS;
    }
  }

  /// Formatea un valor como moneda para la UI
  static String formatearMoneda(double valor) {
    final NumberFormat format = NumberFormat.currency(
      locale: 'en_US',
      symbol: 'S/.',
      decimalDigits: 2,
    );
    final formateado = format.format(valor);
    final conEspacio = formateado.replaceFirst('S/.', 'S/. ');
    final parteNumerica = conEspacio.substring(4); // 'S/. ' tiene longitud 4
    return 'S/. ${_aplicarFormatoUI(parteNumerica)}';
  }

  /// Formatea un valor como número sin símbolo de moneda para la UI
  static String formatearNumero(double valor) {
    final NumberFormat format = NumberFormat.decimalPattern('en_US');
    final formatted = format.format(double.parse(valor.toStringAsFixed(2)));
    return _aplicarFormatoUI(formatted);
  }

  /// Formatea un valor numérico aplicando la configuración regional de la UI y decimales personalizados.
  static String formatearConDecimales(double valor, int decimales) {
    final NumberFormat format = NumberFormat.decimalPattern('en_US');
    final formatted = format.format(double.parse(valor.toStringAsFixed(decimales)));
    return _aplicarFormatoUI(formatted);
  }

  /// Formatea un valor como número conservando el comportamiento original es_PE (para Excel)
  static String formatearNumeroParaExcel(double valor) {
    final NumberFormat format = NumberFormat.decimalPattern('es_PE');
    return format.format(double.parse(valor.toStringAsFixed(2)));
  }

  /// Formatea un número con unidades para la UI
  static String formatearUnidades(double valor, String unidad) {
    final NumberFormat format = NumberFormat.decimalPattern('en_US');
    final formatted = format.format(double.parse(valor.toStringAsFixed(2)));
    return '${_aplicarFormatoUI(formatted)} $unidad';
  }

  /// Redondea un valor según su tipo y magnitud
  static double redondearInteligente(double valor,
      {String tipo = 'general', int? decimales}) {
    switch (tipo) {
      case 'dias':
        // Lead time: redondear a 1 decimal
        return double.parse(valor.toStringAsFixed(1));

      case 'espacio':
        // Espacio en m²: redondear a 1 decimal
        return double.parse(valor.toStringAsFixed(1));

      case 'moneda':
        // Valores monetarios: redondear a 2 decimales
        return double.parse(valor.toStringAsFixed(2));

      case 'unidades':
        // Punto de reorden, tamaño de lote: redondear a números enteros
        return valor.roundToDouble();

      case 'unidades_decimales':
        // Punto de reorden, tamaño de lote con decimales personalizados
        final decimalesFinal = decimales ?? 0;
        return double.parse(valor.toStringAsFixed(decimalesFinal));

      case 'pedidos':
        // Número de pedidos: redondear a números enteros
        return valor.roundToDouble();

      case 'porcentaje':
        // Porcentajes: redondear a 1 decimal
        return double.parse(valor.toStringAsFixed(1));

      default:
        // General: redondear a 2 decimales
        return double.parse(valor.toStringAsFixed(2));
    }
  }

  /// Formatea un valor redondeado según su tipo
  static String formatearValorRedondeado(double valor,
      {String tipo = 'general'}) {
    final valorRedondeado = redondearInteligente(valor, tipo: tipo);

    switch (tipo) {
      case 'dias':
        return '${valorRedondeado.toStringAsFixed(1)} días';

      case 'espacio':
        return '${valorRedondeado.toStringAsFixed(1)} m²';

      case 'moneda':
        return formatearMoneda(valorRedondeado);

      case 'unidades':
        return '${valorRedondeado.toStringAsFixed(0)} unidades';

      case 'pedidos':
        return '${valorRedondeado.toStringAsFixed(0)} pedidos';

      case 'porcentaje':
        return '${valorRedondeado.toStringAsFixed(1)}%';

      default:
        return valorRedondeado.toStringAsFixed(2);
    }
  }

  /// Valida y redondea un valor de entrada del usuario
  static double validarYRedondearEntrada(String input,
      {String tipo = 'general', double? valorPorDefecto}) {
    if (input.trim().isEmpty) {
      return valorPorDefecto ?? 0.0;
    }

    // Parsear el valor usando el parseador regional
    final valor = parseDouble(input) ?? valorPorDefecto ?? 0.0;

    // Validar que sea positivo (excepto para porcentajes que pueden ser negativos)
    if (tipo != 'porcentaje' && valor < 0) {
      return 0.0;
    }

    // Redondear según el tipo
    return redondearInteligente(valor, tipo: tipo);
  }

  /// Analiza y convierte una cadena formateada con separadores a double.
  /// Soporta formatos regionales con puntos/comas de miles y decimales.
  static double? parseDouble(Object? v) {
    if (v == null) {
      return null;
    }
    String s = v.toString().trim();
    if (s.isEmpty) {
      return null;
    }

    // 1. Quitar espacios y espacios de no separación (NBSP)
    s = s.replaceAll('\u00A0', '').replaceAll(' ', '');

    // 2. Determinar separadores según el formato regional activo de la UI
    // formatoNumeroUI: 'punto_coma' (1.250,00), 'coma_punto' (1,250.00), 'comilla_punto' (1'250.00)
    String milesSep;
    String decimalSep;
    if (formatoNumeroUI == 'punto_coma') {
      milesSep = '.';
      decimalSep = ',';
    } else if (formatoNumeroUI == 'comilla_punto') {
      milesSep = "'";
      decimalSep = '.';
    } else {
      milesSep = ',';
      decimalSep = '.';
    }

    // Si la cadena contiene ambos separadores:
    if (s.contains(milesSep) && s.contains(decimalSep)) {
      final firstMiles = s.indexOf(milesSep);
      final lastDecimal = s.lastIndexOf(decimalSep);
      if (firstMiles < lastDecimal) {
        // El orden de los separadores es el correcto para el formato regional
        s = s.replaceAll(milesSep, '').replaceAll(decimalSep, '.');
      } else {
        // Están en el orden inverso (ej: ingresaron formato US en local ES o viceversa)
        final fallback = _parseDoubleFallback(s);
        if (fallback != null) {
          return fallback;
        }
      }
    }
    // Si contiene solo uno de los separadores:
    else if (s.contains(milesSep)) {
      // Si contiene solo el separador de miles (ej: "550.000" en punto_coma o "550,000" en coma_punto)
      final lastIdx = s.lastIndexOf(milesSep);
      final charsAfter = s.substring(lastIdx + 1).length;
      if (charsAfter == 3 || s.split(milesSep).length > 2) {
        // Es separador de miles
        s = s.replaceAll(milesSep, '');
      } else {
        // Si no son 3 dígitos y es el único separador, puede ser que el usuario lo usó como decimal por error
        s = s.replaceAll(milesSep, '.');
      }
    }
    else if (s.contains(decimalSep)) {
      // Contiene solo el separador decimal activo. Lo reemplazamos por '.'
      s = s.replaceAll(decimalSep, '.');
    }
    // Si contiene un punto/coma que no es ninguno de los activos:
    else if (s.contains('.') || s.contains(',') || s.contains("'")) {
      final fallback = _parseDoubleFallback(s);
      if (fallback != null) {
        return fallback;
      }
    }

    return double.tryParse(s);
  }

  /// Parser de respaldo genérico e inteligente basado en análisis posicional de caracteres.
  static double? _parseDoubleFallback(String s) {
    s = s.replaceAll("'", '');
    final hasComma = s.contains(',');
    final hasDot = s.contains('.');
    if (hasComma && hasDot) {
      final lastComma = s.lastIndexOf(',');
      final lastDot = s.lastIndexOf('.');
      if (lastComma > lastDot) {
        s = s.replaceAll('.', '').replaceAll(',', '.');
      } else {
        s = s.replaceAll(',', '');
      }
    } else if (hasComma && !hasDot) {
      final lastIdx = s.lastIndexOf(',');
      final decimals = s.substring(lastIdx + 1);
      if (decimals.length == 3) {
        s = s.replaceAll(',', '');
      } else {
        s = s.replaceAll(',', '.');
      }
    } else if (hasDot && !hasComma) {
      final lastIdx = s.lastIndexOf('.');
      final decimals = s.substring(lastIdx + 1);
      if (decimals.length == 3) {
        s = s.replaceAll('.', '');
      }
    }
    return double.tryParse(s);
  }

  /// Retorna los formatters de texto para inputs numéricos, limitando los decimales según la configuración regional.
  static List<TextInputFormatter> getInputFormatters({bool allowDecimal = true}) {
    final decimalSep = formatoNumeroUI == 'punto_coma' ? ',' : '.';
    return [
      FilteringTextInputFormatter.allow(RegExp(allowDecimal ? r"[0-9.,'\u00A0 ]" : r'[0-9]')),
      if (allowDecimal)
        TextInputFormatter.withFunction((oldValue, newValue) {
          final text = newValue.text;
          // Contar ocurrencias del separador decimal
          final count = decimalSep.allMatches(text).length;
          if (count > 1) {
            return oldValue;
          }
          return newValue;
        }),
    ];
  }
}
