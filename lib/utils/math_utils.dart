import 'dart:math';
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
    final y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * exp(-absX * absX);
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
  static double calcularZScore(double puntoReorden, double demandaLeadTime, double desviacionLeadTime) {
    return (puntoReorden - demandaLeadTime) / desviacionLeadTime;
  }

  /// Calcula la demanda en el lead time
  /// μL = D * (L / 365)
  static double calcularDemandaLeadTime(double demandaAnual, double leadTimeDias) {
    return demandaAnual * (leadTimeDias / 365.0);
  }

  /// Calcula la desviación estándar en el lead time
  /// σL = σD * sqrt(L)
  static double calcularDesviacionLeadTime(double desviacionDiaria, double leadTimeDias) {
    return desviacionDiaria * sqrt(leadTimeDias);
  }

  /// Calcula los backorders esperados
  /// E[BO] = σL * L(z)
  static double calcularBackordersEsperados(double desviacionLeadTime, double zScore) {
    final lz = normalLossFunction(zScore);
    return desviacionLeadTime * lz;
  }

  /// Calcula el stock de seguridad
  /// SS = max(0, R - μL)
  static double calcularStockSeguridad(double puntoReorden, double demandaLeadTime) {
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
  static double calcularCostoPedidosComponent(double demandaAnual, double tamanoLote, double costoPedido) {
    return (demandaAnual / tamanoLote) * costoPedido;
  }

  /// Componente: Costo de mantenimiento anual Ch = \bar{I} * h
  static double calcularCostoMantenimientoComponent(double inventarioPromedio, double costoMantenimiento) {
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
    final cK = calcularCostoPedidosComponent(demandaAnual, tamanoLote, costoPedido);
    final cH = calcularCostoMantenimientoComponent(inventarioPromedio, costoMantenimiento);
    final cP = calcularCostoServicioComponentEBOPuro(backordersEsperados, costoFaltante);
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
    final costoMantenimientoInv = ((tamanoLote - backordersEsperados) / 2) * costoMantenimiento;
    // E[BO]*p
    final costoServicio = backordersEsperados * costoFaltante;
    
    return costoPedidos + costoMantenimientoInv + costoServicio;
  }

  /// Calcula el tamaño de lote EOQ clásico
  /// Q* = sqrt( 2 * D * K / h )
  static double calcularEOQ(double demandaAnual, double costoPedido, double costoMantenimiento) {
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
  static double calcularEspacioUsado(double puntoReorden, double espacioUnidad) {
    return puntoReorden * espacioUnidad;
  }

  /// Calcula el número de pedidos por año
  /// N = D / Q
  static double calcularNumeroPedidos(double demandaAnual, double tamanoLote) {
    return demandaAnual / tamanoLote;
  }

  /// Presupuesto para un artículo: c * R
  static double calcularPresupuestoArticulo(double costoUnitario, double puntoReorden) {
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

  /// Formatea un valor como moneda
  static String formatearMoneda(double valor) {
    final NumberFormat format = NumberFormat.currency(
      locale: 'es_PE',
      symbol: 'S/',
      decimalDigits: 2,
    );
    return format.format(valor);
  }

  /// Formatea un número con unidades
  static String formatearUnidades(double valor, String unidad) {
    final NumberFormat format = NumberFormat.decimalPattern('es_PE');
    return '${format.format(double.parse(valor.toStringAsFixed(2)))} $unidad';
  }
} 