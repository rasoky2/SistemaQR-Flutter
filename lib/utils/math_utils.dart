import 'dart:math';

/// Utilidades matemáticas para el modelo QR de inventario
class MathUtils {
  /// PDF de la distribución normal estándar
  static double normalPdf(double x) {
    return exp(-0.5 * x * x) / sqrt(2 * pi);
  }

  /// CDF de la distribución normal estándar usando aproximación de error function
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
    final y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * exp(-absX * absX);
    return 0.5 * (1.0 + sign * y);
  }

  /// Función de pérdida normal estándar L(z)
  static double normalLossFunction(double z) {
    final phi = normalPdf(z);
    final phiCdf = normalCdf(z);
    return phi - z * (1 - phiCdf);
  }

  /// Calcula el z-score para un punto de reorden dado
  static double calcularZScore(double puntoReorden, double demandaLeadTime, double desviacionLeadTime) {
    return (puntoReorden - demandaLeadTime) / desviacionLeadTime;
  }

  /// Calcula la demanda en el lead time
  static double calcularDemandaLeadTime(double demandaAnual, double leadTimeDias) {
    return demandaAnual * (leadTimeDias / 365.0);
  }

  /// Calcula la desviación estándar en el lead time
  static double calcularDesviacionLeadTime(double desviacionDiaria, double leadTimeDias) {
    return desviacionDiaria * sqrt(leadTimeDias);
  }

  /// Calcula los backorders esperados
  static double calcularBackordersEsperados(double desviacionLeadTime, double zScore) {
    final lz = normalLossFunction(zScore);
    return desviacionLeadTime * lz;
  }

  /// Calcula el costo total de un artículo
  static double calcularCostoTotal({
    required double demandaAnual,
    required double tamanoLote,
    required double costoPedido,
    required double backordersEsperados,
    required double costoMantenimiento,
    required double costoFaltante,
  }) {
    final costoPedidos = (demandaAnual / tamanoLote) * costoPedido;
    final costoMantenimientoInv = ((tamanoLote - backordersEsperados) / 2) * costoMantenimiento;
    final costoServicio = backordersEsperados * costoFaltante;
    
    return costoPedidos + costoMantenimientoInv + costoServicio;
  }

  /// Calcula el espacio usado por un artículo
  static double calcularEspacioUsado(double puntoReorden, double espacioUnidad) {
    return puntoReorden * espacioUnidad;
  }

  /// Calcula el número de pedidos por año
  static double calcularNumeroPedidos(double demandaAnual, double tamanoLote) {
    return demandaAnual / tamanoLote;
  }

  /// Calcula el presupuesto total de compra
  static double calcularPresupuestoTotal(List<Map<String, dynamic>> articulos) {
    double presupuesto = 0;
    for (final articulo in articulos) {
      final costoUnitario = articulo['costoUnitario'] as double;
      final puntoReorden = articulo['puntoReorden'] as double;
      presupuesto += costoUnitario * puntoReorden;
    }
    return presupuesto;
  }

  /// Valida las restricciones del sistema
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
    return 'S/ ${valor.toStringAsFixed(2)}';
  }

  /// Formatea un número como porcentaje
  static String formatearPorcentaje(double valor) {
    return '${(valor * 100).toStringAsFixed(2)}%';
  }

  /// Formatea un número con unidades
  static String formatearUnidades(double valor, String unidad) {
    return '${valor.toStringAsFixed(2)} $unidad';
  }
} 