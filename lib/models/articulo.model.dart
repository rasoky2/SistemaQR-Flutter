
/// Modelo de artículo para el sistema QR de inventario
class Articulo {
  final String nombre;
  final double demandaAnual; // D
  final double costoPedido; // K
  final double costoMantenimiento; // h
  final double costoFaltante; // p
  final double costoUnitario; // c
  final double espacioUnidad; // s
  final double desviacionDiaria; // sigmaD
  final double puntoReorden; // R
  final double tamanoLote; // Q

  const Articulo({
    required this.nombre,
    required this.demandaAnual,
    required this.costoPedido,
    required this.costoMantenimiento,
    required this.costoFaltante,
    required this.costoUnitario,
    required this.espacioUnidad,
    required this.desviacionDiaria,
    required this.puntoReorden,
    required this.tamanoLote,
  });

  /// Crea un artículo desde un mapa (útil para importación de Excel)
  factory Articulo.fromMap(Map<String, dynamic> map) {
    return Articulo(
      nombre: (map['nombre'] as String?)?.toString() ?? '',
      demandaAnual: (map['demandaAnual'] as num?)?.toDouble() ?? 0.0,
      costoPedido: (map['costoPedido'] as num?)?.toDouble() ?? 0.0,
      costoMantenimiento: (map['costoMantenimiento'] as num?)?.toDouble() ?? 0.0,
      costoFaltante: (map['costoFaltante'] as num?)?.toDouble() ?? 0.0,
      costoUnitario: (map['costoUnitario'] as num?)?.toDouble() ?? 0.0,
      espacioUnidad: (map['espacioUnidad'] as num?)?.toDouble() ?? 0.0,
      desviacionDiaria: (map['desviacionDiaria'] as num?)?.toDouble() ?? 0.0,
      puntoReorden: (map['puntoReorden'] as num?)?.toDouble() ?? 0.0,
      tamanoLote: (map['tamanoLote'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convierte el artículo a un mapa (útil para exportación a Excel)
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'demandaAnual': demandaAnual,
      'costoPedido': costoPedido,
      'costoMantenimiento': costoMantenimiento,
      'costoFaltante': costoFaltante,
      'costoUnitario': costoUnitario,
      'espacioUnidad': espacioUnidad,
      'desviacionDiaria': desviacionDiaria,
      'puntoReorden': puntoReorden,
      'tamanoLote': tamanoLote,
    };
  }

  /// Crea una copia del artículo con algunos valores modificados
  Articulo copyWith({
    String? nombre,
    double? demandaAnual,
    double? costoPedido,
    double? costoMantenimiento,
    double? costoFaltante,
    double? costoUnitario,
    double? espacioUnidad,
    double? desviacionDiaria,
    double? puntoReorden,
    double? tamanoLote,
  }) {
    return Articulo(
      nombre: nombre ?? this.nombre,
      demandaAnual: demandaAnual ?? this.demandaAnual,
      costoPedido: costoPedido ?? this.costoPedido,
      costoMantenimiento: costoMantenimiento ?? this.costoMantenimiento,
      costoFaltante: costoFaltante ?? this.costoFaltante,
      costoUnitario: costoUnitario ?? this.costoUnitario,
      espacioUnidad: espacioUnidad ?? this.espacioUnidad,
      desviacionDiaria: desviacionDiaria ?? this.desviacionDiaria,
      puntoReorden: puntoReorden ?? this.puntoReorden,
      tamanoLote: tamanoLote ?? this.tamanoLote,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Articulo &&
        other.nombre == nombre &&
        other.demandaAnual == demandaAnual &&
        other.costoPedido == costoPedido &&
        other.costoMantenimiento == costoMantenimiento &&
        other.costoFaltante == costoFaltante &&
        other.costoUnitario == costoUnitario &&
        other.espacioUnidad == espacioUnidad &&
        other.desviacionDiaria == desviacionDiaria &&
        other.puntoReorden == puntoReorden &&
        other.tamanoLote == tamanoLote;
  }

  @override
  int get hashCode {
    return Object.hash(
      nombre,
      demandaAnual,
      costoPedido,
      costoMantenimiento,
      costoFaltante,
      costoUnitario,
      espacioUnidad,
      desviacionDiaria,
      puntoReorden,
      tamanoLote,
    );
  }

  @override
  String toString() {
    return 'Articulo(nombre: $nombre, demandaAnual: $demandaAnual, costoPedido: $costoPedido, costoMantenimiento: $costoMantenimiento, costoFaltante: $costoFaltante, costoUnitario: $costoUnitario, espacioUnidad: $espacioUnidad, desviacionDiaria: $desviacionDiaria, puntoReorden: $puntoReorden, tamanoLote: $tamanoLote)';
  }
} 