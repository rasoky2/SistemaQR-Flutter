import 'package:inventario_qr/models/articulo.model.dart';
import 'package:inventario_qr/models/resultado.model.dart';
import 'package:inventario_qr/utils/math_utils.dart';

/// Repositorio para manejar los cálculos del modelo QR de inventario
class InventarioRepository {
  /// Evalúa el modelo QR para una lista de artículos
  static ResultadoSistema evaluarModeloQR(
    List<Articulo> articulos, {
    double leadTimeDias = 36.5,
    double espacioMaximo = 150.0,
    double presupuestoMaximo = 10000.0,
    double numeroMaximoPedidos = 100.0,
  }) {
    final resultados = <ResultadoArticulo>[];
    double costoTotalSistema = 0;
    double espacioTotalUsado = 0;
    double presupuestoTotal = 0;
    double numeroTotalPedidos = 0;

    for (final articulo in articulos) {
      // Cálculos del lead time
      final demandaLeadTime = MathUtils.calcularDemandaLeadTime(
        articulo.demandaAnual,
        leadTimeDias,
      );
      final desviacionLeadTime = MathUtils.calcularDesviacionLeadTime(
        articulo.desviacionDiaria,
        leadTimeDias,
      );

      // Z-score y backorders esperados
      final zScore = MathUtils.calcularZScore(
        articulo.puntoReorden,
        demandaLeadTime,
        desviacionLeadTime,
      );
      final backordersEsperados = MathUtils.calcularBackordersEsperados(
        desviacionLeadTime,
        zScore,
      );

      // Cálculo de costos
      final costoPedidos = (articulo.demandaAnual / articulo.tamanoLote) * articulo.costoPedido;
      // Inventario promedio: Q/2 + SS - E[BO], con SS = max(0, R - μL)
      final double stockSeguridad = (articulo.puntoReorden - demandaLeadTime) > 0
          ? (articulo.puntoReorden - demandaLeadTime)
          : 0.0;
      final double inventarioPromedio = (articulo.tamanoLote / 2) + stockSeguridad - backordersEsperados;
      final double inventarioPromedioNoNegativo = inventarioPromedio > 0 ? inventarioPromedio : 0.0;
      final costoMantenimiento = inventarioPromedioNoNegativo * articulo.costoMantenimiento;
      // Costo de faltante anual: p * (D/Q) * E[BO]
      final costoServicio = (articulo.demandaAnual / articulo.tamanoLote) * backordersEsperados * articulo.costoFaltante;
      final costoTotal = costoPedidos + costoMantenimiento + costoServicio;

      // Espacio usado
      final espacioUsado = MathUtils.calcularEspacioUsado(
        articulo.puntoReorden,
        articulo.espacioUnidad,
      );

      // Número de pedidos
      final numeroPedidos = MathUtils.calcularNumeroPedidos(
        articulo.demandaAnual,
        articulo.tamanoLote,
      );

      // Presupuesto para este artículo
      final presupuestoArticulo = articulo.costoUnitario * articulo.puntoReorden;

      // Acumular totales
      costoTotalSistema += costoTotal;
      espacioTotalUsado += espacioUsado;
      presupuestoTotal += presupuestoArticulo;
      numeroTotalPedidos += numeroPedidos;

      // Crear resultado del artículo
      final resultado = ResultadoArticulo(
        nombre: articulo.nombre,
        tamanoLote: articulo.tamanoLote,
        puntoReorden: articulo.puntoReorden,
        zScore: zScore,
        backordersEsperados: backordersEsperados,
        costoTotal: costoTotal,
        espacioUsado: espacioUsado,
        costoPedidos: costoPedidos,
        costoMantenimiento: costoMantenimiento,
        costoServicio: costoServicio,
      );

      resultados.add(resultado);
    }

    return ResultadoSistema(
      resultados: resultados,
      costoTotalSistema: costoTotalSistema,
      espacioTotalUsado: espacioTotalUsado,
      presupuestoTotal: presupuestoTotal,
      numeroTotalPedidos: numeroTotalPedidos.round(),
    );
  }

  /// Valida las restricciones del sistema
  static Map<String, bool> validarRestricciones(
    ResultadoSistema resultado, {
    double espacioMaximo = 150.0,
    double presupuestoMaximo = 10000.0,
    double numeroMaximoPedidos = 100.0,
  }) {
    return MathUtils.validarRestricciones(
      espacioTotal: resultado.espacioTotalUsado,
      espacioMaximo: espacioMaximo,
      presupuestoTotal: resultado.presupuestoTotal,
      presupuestoMaximo: presupuestoMaximo,
      numeroTotalPedidos: resultado.numeroTotalPedidos.toDouble(),
      numeroMaximoPedidos: numeroMaximoPedidos,
    );
  }

  // Datos de ejemplo eliminados (no usados)

  /// Calcula estadísticas adicionales del sistema
  static Map<String, dynamic> calcularEstadisticas(ResultadoSistema resultado) {
    final resultados = resultado.resultados;
    if (resultados.isEmpty) {
      return {
        'costoPromedio': 0.0,
        'espacioPromedio': 0.0,
        'zScorePromedio': 0.0,
        'medianaCosto': 0.0,
        'articuloMasCostoso': '',
        'articuloMenosCostoso': '',
        'articuloMasEspacio': '',
        'articuloMenosEspacio': '',
      };
    }

    double sumaCostos = 0.0;
    double sumaEspacio = 0.0;
    double sumaZ = 0.0;
    double maxCosto = double.negativeInfinity;
    double minCosto = double.infinity;
    double maxEspacio = double.negativeInfinity;
    double minEspacio = double.infinity;
    String maxCostoNombre = '';
    String minCostoNombre = '';
    String maxEspacioNombre = '';
    String minEspacioNombre = '';

    final costosParaMediana = <double>[];

    for (final r in resultados) {
      sumaCostos += r.costoTotal;
      sumaEspacio += r.espacioUsado;
      sumaZ += r.zScore;
      costosParaMediana.add(r.costoTotal);

      if (r.costoTotal > maxCosto) {
        maxCosto = r.costoTotal;
        maxCostoNombre = r.nombre;
      }
      if (r.costoTotal < minCosto) {
        minCosto = r.costoTotal;
        minCostoNombre = r.nombre;
      }
      if (r.espacioUsado > maxEspacio) {
        maxEspacio = r.espacioUsado;
        maxEspacioNombre = r.nombre;
      }
      if (r.espacioUsado < minEspacio) {
        minEspacio = r.espacioUsado;
        minEspacioNombre = r.nombre;
      }
    }

    costosParaMediana.sort();
    final medianaCosto = costosParaMediana[costosParaMediana.length ~/ 2];
    final n = resultados.length.toDouble();

    return {
      'costoPromedio': sumaCostos / n,
      'espacioPromedio': sumaEspacio / n,
      'zScorePromedio': sumaZ / n,
      'medianaCosto': medianaCosto,
      'articuloMasCostoso': maxCostoNombre,
      'articuloMenosCostoso': minCostoNombre,
      'articuloMasEspacio': maxEspacioNombre,
      'articuloMenosEspacio': minEspacioNombre,
    };
  }
} 