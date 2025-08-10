/// Modelo para los resultados del cálculo QR de inventario
class ResultadoArticulo {
  final String nombre;
  final double tamanoLote; // Q
  final double puntoReorden; // R
  final double zScore;
  final double backordersEsperados;
  final double costoTotal;
  final double espacioUsado;
  final double costoPedidos;
  final double costoMantenimiento;
  final double costoServicio;

  const ResultadoArticulo({
    required this.nombre,
    required this.tamanoLote,
    required this.puntoReorden,
    required this.zScore,
    required this.backordersEsperados,
    required this.costoTotal,
    required this.espacioUsado,
    required this.costoPedidos,
    required this.costoMantenimiento,
    required this.costoServicio,
  });

  /// Convierte el resultado a un mapa (útil para exportación a Excel)
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'tamanoLote': tamanoLote,
      'puntoReorden': puntoReorden,
      'zScore': zScore,
      'backordersEsperados': backordersEsperados,
      'costoTotal': costoTotal,
      'espacioUsado': espacioUsado,
      'costoPedidos': costoPedidos,
      'costoMantenimiento': costoMantenimiento,
      'costoServicio': costoServicio,
    };
  }

  @override
  String toString() {
    return 'ResultadoArticulo(nombre: $nombre, tamanoLote: $tamanoLote, puntoReorden: $puntoReorden, zScore: $zScore, backordersEsperados: $backordersEsperados, costoTotal: $costoTotal, espacioUsado: $espacioUsado, costoPedidos: $costoPedidos, costoMantenimiento: $costoMantenimiento, costoServicio: $costoServicio)';
  }
}

/// Modelo para los resultados totales del sistema
class ResultadoSistema {
  final List<ResultadoArticulo> resultados;
  final double costoTotalSistema;
  final double espacioTotalUsado;
  final double presupuestoTotal;
  final int numeroTotalPedidos;

  const ResultadoSistema({
    required this.resultados,
    required this.costoTotalSistema,
    required this.espacioTotalUsado,
    required this.presupuestoTotal,
    required this.numeroTotalPedidos,
  });

  /// Convierte el resultado del sistema a un mapa
  Map<String, dynamic> toMap() {
    return {
      'resultados': resultados.map((r) => r.toMap()).toList(),
      'costoTotalSistema': costoTotalSistema,
      'espacioTotalUsado': espacioTotalUsado,
      'presupuestoTotal': presupuestoTotal,
      'numeroTotalPedidos': numeroTotalPedidos,
    };
  }

  @override
  String toString() {
    return 'ResultadoSistema(resultados: $resultados, costoTotalSistema: $costoTotalSistema, espacioTotalUsado: $espacioTotalUsado, presupuestoTotal: $presupuestoTotal, numeroTotalPedidos: $numeroTotalPedidos)';
  }
} 