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
      final costoMantenimiento = ((articulo.tamanoLote - backordersEsperados) / 2) * articulo.costoMantenimiento;
      final costoServicio = backordersEsperados * articulo.costoFaltante;
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

  /// Genera datos de ejemplo para pruebas
  static List<Articulo> generarDatosEjemplo() {
    return [
      const Articulo(
        nombre: 'Artículo 1',
        demandaAnual: 1200.0,
        costoPedido: 100.0,
        costoMantenimiento: 2.0,
        costoFaltante: 5.0,
        costoUnitario: 20.0,
        espacioUnidad: 0.5,
        desviacionDiaria: 2.0,
        puntoReorden: 120.0,
        tamanoLote: 200.0,
      ),
      const Articulo(
        nombre: 'Artículo 2',
        demandaAnual: 800.0,
        costoPedido: 80.0,
        costoMantenimiento: 3.0,
        costoFaltante: 6.0,
        costoUnitario: 30.0,
        espacioUnidad: 1.0,
        desviacionDiaria: 3.0,
        puntoReorden: 90.0,
        tamanoLote: 160.0,
      ),
    ];
  }

  /// Calcula estadísticas adicionales del sistema
  static Map<String, dynamic> calcularEstadisticas(ResultadoSistema resultado) {
    final costosPromedio = resultado.resultados.map((r) => r.costoTotal).reduce((a, b) => a + b) / resultado.resultados.length;
    final espacioPromedio = resultado.resultados.map((r) => r.espacioUsado).reduce((a, b) => a + b) / resultado.resultados.length;
    final zScorePromedio = resultado.resultados.map((r) => r.zScore).reduce((a, b) => a + b) / resultado.resultados.length;
    
    final costosOrdenados = resultado.resultados.map((r) => r.costoTotal).toList()..sort();
    final medianaCosto = costosOrdenados[costosOrdenados.length ~/ 2];
    
    return {
      'costoPromedio': costosPromedio,
      'espacioPromedio': espacioPromedio,
      'zScorePromedio': zScorePromedio,
      'medianaCosto': medianaCosto,
      'articuloMasCostoso': resultado.resultados.reduce((a, b) => a.costoTotal > b.costoTotal ? a : b).nombre,
      'articuloMenosCostoso': resultado.resultados.reduce((a, b) => a.costoTotal < b.costoTotal ? a : b).nombre,
      'articuloMasEspacio': resultado.resultados.reduce((a, b) => a.espacioUsado > b.espacioUsado ? a : b).nombre,
      'articuloMenosEspacio': resultado.resultados.reduce((a, b) => a.espacioUsado < b.espacioUsado ? a : b).nombre,
    };
  }
} 