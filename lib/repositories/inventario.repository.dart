import 'package:inventario_qr/models/articulo.model.dart';
import 'package:inventario_qr/models/resultado.model.dart';
import 'package:inventario_qr/utils/logger.dart';
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

    logDebug('🧮 Repo: evaluarModeloQR -> artículos=${articulos.length}, leadTime=$leadTimeDias, espacioMax=$espacioMaximo, presupuestoMax=$presupuestoMaximo, pedidosMax=$numeroMaximoPedidos');

    for (final articulo in articulos) {
      logDebug('➡️  Artículo: ${articulo.nombre} | D=${articulo.demandaAnual} K=${articulo.costoPedido} h=${articulo.costoMantenimiento} p=${articulo.costoFaltante} c=${articulo.costoUnitario} s=${articulo.espacioUnidad} σd=${articulo.desviacionDiaria} R=${articulo.puntoReorden} Q=${articulo.tamanoLote}');
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
      final double safeDesviacionLeadTime = desviacionLeadTime.abs() < 1e-9 ? 1e-9 : desviacionLeadTime;
      final zScore = MathUtils.calcularZScore(articulo.puntoReorden, demandaLeadTime, safeDesviacionLeadTime);
      final backordersEsperados = MathUtils.calcularBackordersEsperados(safeDesviacionLeadTime, zScore);

      // Determinar Q: usar el tamaño de lote ingresado si es válido; de lo contrario, calcular EOQ
      final double qEoq = MathUtils.calcularEOQ(
        articulo.demandaAnual,
        articulo.costoPedido,
        articulo.costoMantenimiento,
      );
      final double safeTamanoLote =
          (articulo.tamanoLote > 0 && articulo.tamanoLote.isFinite) ? articulo.tamanoLote : qEoq;
      logDebug('   Q_importado=${articulo.tamanoLote} Q_eoq=$qEoq -> Q_usado=$safeTamanoLote');
      // Inventario promedio y componentes de costo movidos a MathUtils
      final double stockSeguridad = MathUtils.calcularStockSeguridad(articulo.puntoReorden, demandaLeadTime);
      final double inventarioPromedioNoNegativo = MathUtils.calcularInventarioPromedio(safeTamanoLote, stockSeguridad, backordersEsperados);
      final double costoPedidos = MathUtils.calcularCostoPedidosComponent(articulo.demandaAnual, safeTamanoLote, articulo.costoPedido);
      final double costoMantenimiento = MathUtils.calcularCostoMantenimientoComponent(inventarioPromedioNoNegativo, articulo.costoMantenimiento);
      final double costoServicio = MathUtils.calcularCostoServicioComponent(articulo.demandaAnual, safeTamanoLote, backordersEsperados, articulo.costoFaltante);
      final double costoTotal = MathUtils.calcularCostoTotalQR(
        demandaAnual: articulo.demandaAnual,
        tamanoLote: safeTamanoLote,
        costoPedido: articulo.costoPedido,
        inventarioPromedio: inventarioPromedioNoNegativo,
        costoMantenimiento: articulo.costoMantenimiento,
        backordersEsperados: backordersEsperados,
        costoFaltante: articulo.costoFaltante,
      );

      logDebug('   μL=$demandaLeadTime σL=$safeDesviacionLeadTime z=$zScore E[BO]=$backordersEsperados SS=$stockSeguridad');
      logDebug('   Q=$safeTamanoLote invProm=$inventarioPromedioNoNegativo Ck=$costoPedidos Ch=$costoMantenimiento Cp=$costoServicio Ctotal=$costoTotal');

      // Espacio usado
      final espacioUsado = MathUtils.calcularEspacioUsado(
        articulo.puntoReorden,
        articulo.espacioUnidad,
      );

      // Número de pedidos
      final numeroPedidos = MathUtils.calcularNumeroPedidos(
        articulo.demandaAnual,
        safeTamanoLote,
      );

      // Presupuesto para este artículo
      final presupuestoArticulo = MathUtils.calcularPresupuestoArticulo(articulo.costoUnitario, articulo.puntoReorden);

      // Acumular totales
      costoTotalSistema += costoTotal;
      espacioTotalUsado += espacioUsado;
      presupuestoTotal += presupuestoArticulo;
      numeroTotalPedidos += numeroPedidos;

      logDebug('   espacioUsado=$espacioUsado pedidos=$numeroPedidos presupuestoArt=$presupuestoArticulo');

      // Crear resultado del artículo
      final resultado = ResultadoArticulo(
        nombre: articulo.nombre,
        tamanoLote: safeTamanoLote,
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

    logDebug('✅ Totales -> costoSistema=$costoTotalSistema espacioTotal=$espacioTotalUsado presupuestoTotal=$presupuestoTotal numeroPedidos=${numeroTotalPedidos.round()}');

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