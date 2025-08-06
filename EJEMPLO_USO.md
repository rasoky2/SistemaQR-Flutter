# Manual de Usuario - Sistema QR de Inventario

## Introducción

El Sistema QR de Inventario es una aplicación Flutter que implementa el modelo de inventario (Q,R) para múltiples artículos con restricciones de espacio, presupuesto y número de pedidos. Este manual explica la teoría matemática, el uso del programa y proporciona ejemplos prácticos.

## Modelo Matemático QR

### Formulación del Problema

Para cada artículo $i$ con parámetros:
- $D_i$: Demanda anual
- $K_i$: Costo por pedido
- $h_i$: Costo de mantenimiento por unidad/año
- $p_i$: Penalización por faltante por unidad
- $c_i$: Costo unitario
- $s_i$: Espacio por unidad
- $\sigma_i$: Desviación estándar diaria
- $L$: Lead time en años
- $R_i$: Punto de reorden
- $Q_i$: Tamaño de lote

### Función Objetivo

El costo total del sistema se minimiza con:

$$TC = \sum_{i=1}^n \left[\frac{D_i}{Q_i}K_i + \frac{Q_i - E[B_i]}{2}h_i + E[B_i]p_i\right]$$

Donde $E[B_i]$ son los backorders esperados en el lead time.

### Implementación Matemática en math_utils.dart

#### 1. Distribución Normal Estándar

La función de densidad de probabilidad (PDF) se implementa como:

```dart
static double normalPdf(double x) {
  return exp(-0.5 * x * x) / sqrt(2 * pi);
}
```

La función de distribución acumulativa (CDF) usa la aproximación de Abramowitz y Stegun:

```dart
static double normalCdf(double x) {
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
```

#### 2. Función de Pérdida Normal

La función de pérdida normal estándar $L(z)$ se calcula como:

$$L(z) = \phi(z) - z(1-\Phi(z))$$

Donde $\phi(z)$ es la PDF y $\Phi(z)$ es la CDF de la distribución normal estándar.

```dart
static double normalLossFunction(double z) {
  final phi = normalPdf(z);
  final Phi = normalCdf(z);
  return phi - z * (1 - Phi);
}
```

#### 3. Cálculos Intermedios

**Demanda en lead time**: $\mu_L = D_i \cdot L$

```dart
static double calcularDemandaLeadTime(double demandaAnual, double leadTimeDias) {
  return demandaAnual * (leadTimeDias / 365.0);
}
```

**Desviación en lead time**: $\sigma_L = \sigma_i \cdot \sqrt{L \cdot 365}$

```dart
static double calcularDesviacionLeadTime(double desviacionDiaria, double leadTimeDias) {
  return desviacionDiaria * sqrt(leadTimeDias);
}
```

**Z-score**: $z_i = \frac{R_i - \mu_L}{\sigma_L}$

```dart
static double calcularZScore(double puntoReorden, double demandaLeadTime, double desviacionLeadTime) {
  return (puntoReorden - demandaLeadTime) / desviacionLeadTime;
}
```

**Backorders esperados**: $E[B_i] = \sigma_L \cdot L(z_i)$

```dart
static double calcularBackordersEsperados(double desviacionLeadTime, double zScore) {
  final Lz = normalLossFunction(zScore);
  return desviacionLeadTime * Lz;
}
```

#### 4. Cálculo de Costos

**Costo total por artículo**:

$$TC_i = \frac{D_i}{Q_i}K_i + \frac{Q_i - E[B_i]}{2}h_i + E[B_i]p_i$$

```dart
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
```

#### 5. Cálculos de Restricciones

**Espacio usado**: $S_i = R_i \cdot s_i$

```dart
static double calcularEspacioUsado(double puntoReorden, double espacioUnidad) {
  return puntoReorden * espacioUnidad;
}
```

**Número de pedidos**: $N_i = \frac{D_i}{Q_i}$

```dart
static double calcularNumeroPedidos(double demandaAnual, double tamanoLote) {
  return demandaAnual / tamanoLote;
}
```

**Presupuesto total**: $C = \sum_i c_i \cdot R_i$

```dart
static double calcularPresupuestoTotal(List<Map<String, dynamic>> articulos) {
  double presupuesto = 0;
  for (final articulo in articulos) {
    final costoUnitario = articulo['costoUnitario'] as double;
    final puntoReorden = articulo['puntoReorden'] as double;
    presupuesto += costoUnitario * puntoReorden;
  }
  return presupuesto;
}
```

### Restricciones del Sistema

- **Espacio máximo**: $\sum_i s_i R_i \leq S_{max}$
- **Presupuesto de compra**: $\sum_i c_i R_i \leq C_{max}$
- **Límite de órdenes**: $\sum_i \frac{D_i}{Q_i} \leq N_{max}$

```dart
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
```

## Datos de Ejemplo

### Parámetros de los Artículos

**Artículo 1**:
- Demanda anual $D_1 = 1200$ unidades
- Costo por pedido $K_1 = 100$ soles
- Costo mantenimiento $h_1 = 2$ soles/unidad
- Costo por faltante $p_1 = 5$ soles/unidad
- Costo unitario $c_1 = 20$ soles
- Espacio por unidad $s_1 = 0.5$ m²
- Desviación estándar diaria $\sigma_1 = 2$ unidades/día
- Punto de reorden $R_1 = 120$ unidades
- Tamaño de lote $Q_1 = 200$ unidades

**Artículo 2**:
- Demanda anual $D_2 = 800$ unidades
- Costo por pedido $K_2 = 80$ soles
- Costo mantenimiento $h_2 = 3$ soles/unidad
- Costo por faltante $p_2 = 6$ soles/unidad
- Costo unitario $c_2 = 30$ soles
- Espacio por unidad $s_2 = 1.0$ m²
- Desviación estándar diaria $\sigma_2 = 3$ unidades/día
- Punto de reorden $R_2 = 90$ unidades
- Tamaño de lote $Q_2 = 160$ unidades

**Parámetros globales**:
- Lead time $L = 0.1$ años (36.5 días)
- Restricción de espacio: máximo 150 m²

### Cálculos Numéricos

**Para Artículo 1**:
- Demanda en lead time: $\mu_{L1} = 1200 \cdot 0.1 = 120$ unidades
- Desviación en lead time: $\sigma_{L1} = 2 \cdot \sqrt{36.5} = 12.08$ unidades
- Z-score: $z_1 = \frac{120 - 120}{12.08} = 0.000$
- Función de pérdida: $L(0) = 0.3989$
- Backorders esperados: $E[B_1] = 12.08 \cdot 0.3989 = 4.82$ unidades
- Costo pedidos: $\frac{1200}{200} \cdot 100 = 600$ soles
- Costo mantenimiento: $\frac{200 - 4.82}{2} \cdot 2 = 195.18$ soles
- Costo servicio: $4.82 \cdot 5 = 24.10$ soles
- Costo total: $600 + 195.18 + 24.10 = 819.28$ soles
- Espacio usado: $120 \cdot 0.5 = 60$ m²

**Para Artículo 2**:
- Demanda en lead time: $\mu_{L2} = 800 \cdot 0.1 = 80$ unidades
- Desviación en lead time: $\sigma_{L2} = 3 \cdot \sqrt{36.5} = 18.12$ unidades
- Z-score: $z_2 = \frac{90 - 80}{18.12} = 0.552$
- Función de pérdida: $L(0.552) = 0.181$
- Backorders esperados: $E[B_2] = 18.12 \cdot 0.181 = 3.28$ unidades
- Costo pedidos: $\frac{800}{160} \cdot 80 = 400$ soles
- Costo mantenimiento: $\frac{160 - 3.28}{2} \cdot 3 = 235.08$ soles
- Costo servicio: $3.28 \cdot 6 = 19.68$ soles
- Costo total: $400 + 235.08 + 19.68 = 654.76$ soles
- Espacio usado: $90 \cdot 1.0 = 90$ m²

### Totales del Sistema

- Costo total: $819.28 + 654.76 = 1,474.04$ soles
- Espacio total: $60 + 90 = 150$ m²
- Número total de pedidos: $\frac{1200}{200} + \frac{800}{160} = 6 + 5 = 11$ pedidos/año

## Guía de Uso del Programa

### Instalación y Configuración

1. Abrir la aplicación en tu dispositivo
2. Verificar dependencias en pubspec.yaml:
   ```yaml
   dependencies:
     excel: ^4.0.6
     file_picker: ^10.2.0
     path_provider: ^2.1.2
     open_file: ^3.3.2
   ```

### Cargar Datos de Ejemplo

1. Pantalla principal - Toca "Datos de Ejemplo"
2. Esperar carga - Los datos se cargan automáticamente
3. Verificar - Revisa que aparezcan 2 artículos en la tabla

### Ingresar Datos Manualmente

1. Pantalla principal - Toca "Ingresar Datos"
2. Completar formulario con los parámetros del artículo:
   - Nombre del artículo
   - Demanda anual (unidades)
   - Costo por pedido (soles)
   - Costo mantenimiento (soles/unidad)
   - Costo por faltante (soles/unidad)
   - Costo unitario (soles)
   - Espacio por unidad (m²)
   - Desviación estándar diaria
   - Punto de reorden (unidades)
   - Tamaño de lote (unidades)
3. Toca "Agregar Artículo"
4. Repite para más artículos

### Importar desde Excel

1. Pantalla "Ingresar Datos" - Toca "Importar desde Excel"
2. Seleccionar archivo - Elige tu archivo Excel
3. Seleccionar columnas - Marca las columnas a importar
4. Confirmar importación - Toca "Importar"

**Formato Excel Requerido**:

Estructura estándar (artículos en filas):
```
Nombre | Demanda Anual | Costo Pedido | Costo Mantenimiento | ...
Art1   | 1200         | 100          | 2                  | ...
Art2   | 800          | 80           | 3                  | ...
```

Estructura de parámetros (parámetros en filas):
```
Parámetro           | Artículo 1 | Artículo 2
Demanda anual      | 1200        | 800
Costo por pedido   | 100         | 80
...                | ...         | ...
```

### Ver Resultados

1. Pantalla principal - Toca "Ver Resultados"
2. Revisar resumen - Costo total, espacio usado, presupuesto
3. Analizar restricciones - Estado de cumplimiento
4. Examinar detalles - Resultados por artículo

### Exportar Resultados

1. Pantalla "Resultados" - Sección "Exportar Resultados"
2. Toca "Exportar a Excel"
3. Seleccionar ubicación - Elige dónde guardar
4. Confirmar apertura - ¿Abrir archivo?

## Configuración del Sistema

### Parámetros Globales

Accede desde Pantalla principal - Configurar Restricciones:

- Lead Time: 36.5 días (por defecto)
- Espacio Máximo: 150 m²
- Presupuesto Máximo: 10,000 soles
- Número Máximo de Pedidos: 100

### Interpretación de Resultados

**Z-Score**:
- $z > 0$: Punto de reorden mayor que la demanda esperada
- $z = 0$: Punto de reorden igual a la demanda esperada  
- $z < 0$: Punto de reorden menor que la demanda esperada

**Backorders Esperados**:
- Indica unidades faltantes esperadas durante el lead time
- Valores altos = mayor riesgo de faltantes

**Costos**:
- Costo Pedidos: Costo fijo por realizar pedidos
- Costo Mantenimiento: Costo por mantener inventario
- Costo Servicio: Penalización por faltantes

## Estructura del Código

### Archivos Principales

**lib/utils/math_utils.dart**:
Contiene las funciones matemáticas del modelo QR:

```dart
// Función de pérdida normal estándar L(z)
static double normalLossFunction(double z) {
  final phi = normalPdf(z);
  final Phi = normalCdf(z);
  return phi - z * (1 - Phi);
}

// Cálculo de backorders esperados
static double calcularBackordersEsperados(double desviacionLeadTime, double zScore) {
  final Lz = normalLossFunction(zScore);
  return desviacionLeadTime * Lz;
}
```

**lib/repositories/inventario.repository.dart**:
Implementa la evaluación del modelo QR:

```dart
static ResultadoSistema evaluarModeloQR(List<Articulo> articulos, {
  double leadTimeDias = 36.5,
  double espacioMaximo = 150.0,
  double presupuestoMaximo = 10000.0,
  double numeroMaximoPedidos = 100.0,
}) {
  // Cálculos para cada artículo
  for (final articulo in articulos) {
    final demandaLeadTime = MathUtils.calcularDemandaLeadTime(
      articulo.demandaAnual, leadTimeDias);
    final desviacionLeadTime = MathUtils.calcularDesviacionLeadTime(
      articulo.desviacionDiaria, leadTimeDias);
    // ... más cálculos
  }
}
```

**lib/repositories/excel.repository.dart**:
Maneja importación/exportación Excel:

```dart
// Importar artículos desde Excel
static Future<List<Articulo>> importarArticulosConColumnas(
  Set<String> columnasSeleccionadas, String filePath) async {
  // Leer archivo Excel y convertir a objetos Articulo
}

// Exportar resultados a Excel
static Future<void> exportarResultadosExcel(
  ResultadoSistema resultado, [String? outputPath]) async {
  // Generar archivo Excel con resultados
}
```

## Optimización del Sistema

### Estrategias de Optimización

1. Ajustar Q y R para minimizar costos totales
2. Monitorear restricciones para asegurar factibilidad
3. Analizar sensibilidad a cambios en parámetros
4. Considerar trade-offs entre costos y servicio

### Análisis de Sensibilidad

**Efecto del Lead Time**:
- Lead Time ↑: Mayor variabilidad, más backorders
- Lead Time ↓: Menor variabilidad, menos backorders

**Efecto de la Desviación**:
- Desviación ↑: Mayor incertidumbre, más backorders
- Desviación ↓: Menor incertidumbre, menos backorders

**Efecto de los Costos**:
- Costo Faltante ↑: Menor nivel de servicio aceptable
- Costo Mantenimiento ↑: Lotes más pequeños, más pedidos

## Troubleshooting

### Problemas Comunes

**Error de Importación Excel**:
- Verificar columnas: Asegúrate de que el archivo tenga las columnas correctas
- Validar datos: Los datos numéricos deben ser válidos
- Revisar formato: No debe haber filas vacías

**Restricciones No Cumplidas**:
- Ajustar parámetros: Modifica la configuración del sistema
- Reducir puntos de reorden: Disminuye $R_i$ para cumplir restricciones
- Aumentar tamaños de lote: Incrementa $Q_i$ para reducir pedidos

**Cálculos Incorrectos**:
- Revisar unidades: Confirma que las unidades sean consistentes
- Validar costos: Todos los costos deben ser positivos
