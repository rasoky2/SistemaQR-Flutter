# Propuesta de métricas y mejoras matemáticas (Q,R con backorders)

Este documento describe métricas/columnas adicionales y extensiones del modelo (Q,R) con backorders para enriquecer la tabla de resultados, los gráficos y la exportación. Incluye: fórmulas, dónde calcularlas en el código y beneficios esperados.

## 1) Métricas por artículo propuestas

- Nivel de servicio y faltantes
  - Nivel de servicio: Φ(z)
    - Fórmula: Φ(z) = CDF normal estándar del z-score
    - Código: `final nivelServicio = MathUtils.normalCdf(zScore);`
  - Probabilidad de ruptura: 1 − Φ(z)
    - Código: `final probRuptura = 1 - nivelServicio;`
  - Fill rate (tasa de cumplimiento): 1 − E[BO]/Q
    - Fórmula: `fillRate = 1.0 - (backordersEsperados / Q)` (acotar a [0,1])

- Lead time y stock
  - Demanda en LT (μL): D · (L/365)
    - Código: `final muL = MathUtils.calcularDemandaLeadTime(D, L);`
  - Desviación en LT (σL): σd · √L
    - Código: `final sigmaL = MathUtils.calcularDesviacionLeadTime(sigmaDiaria, L);`
  - Stock de seguridad (SS): max(0, R − μL)
    - Código: `final safetyStock = max(0, R - muL);`
  - Inventario promedio (Ī): Q/2 + SS − E[BO]
    - Código: `final inventarioProm = Q/2 + safetyStock - backordersEsperados;`

- Ciclos y rotación
  - Pedidos por año: D/Q
    - Código: `final pedidosAnuales = D / Q;`
  - Días entre pedidos: 365 · (Q/D)
    - Código: `final diasEntrePedidos = 365.0 * (Q / D);`
  - Rotación de inventario: D/Ī (si Ī > 0)
    - Código: `final rotacion = inventarioProm > 0 ? D / inventarioProm : 0;`

- Costos desglosados y normalizados
  - Costo de pedidos (CK): (D/Q) · K
  - Costo de mantenimiento (Ch): h · Ī
  - Costo de faltantes (Cp): (D/Q) · E[BO] · p
  - Costo total por unidad demandada: (CK + Ch + Cp) / D
  - Participación en costo del sistema: costoArticulo / Σ costoSistema (se calcula en UI con el total del sistema)

- Presupuesto y espacio
  - Presupuesto por artículo: c · R
  - % del presupuesto máximo: (c · R) / PresupuestoMax
  - % de uso de espacio: (R · s) / EspacioMax

## 2) Cambios propuestos al modelo de datos

Archivo: `lib/models/resultado.model.dart` (extender `ResultadoArticulo`)

- Nuevos campos sugeridos:
  - `double muLeadTime;`
  - `double sigmaLeadTime;`
  - `double safetyStock;`
  - `double inventarioPromedio;`
  - `double pedidosAnuales;`
  - `double diasEntrePedidos;`
  - `double nivelServicio;`
  - `double probRuptura;`
  - `double fillRate;`
  - `double rotacionInventario;`
  - `double costoUnitarioDemandado;` // (CK+Ch+Cp)/D
  - `double presupuestoArticulo;` // c·R

> Compatibilidad: mantener los campos actuales y añadir estos como opcionales.

## 3) Dónde calcularlo en el repositorio

Archivo: `lib/repositories/inventario.repository.dart` (dentro del bucle por artículo)

- Ya existen: `demandaLeadTime (μL)`, `desviacionLeadTime (σL)`, `zScore`, `backordersEsperados`, `costoPedidos`, `costoMantenimiento` (con Ī), `costoServicio`.
- Añadir:
  - `final safetyStock = max(0, R - demandaLeadTime);`
  - `final inventarioPromedio = max(0, Q/2 + safetyStock - backordersEsperados);`
  - `final pedidosAnuales = D / Q;`
  - `final diasEntrePedidos = 365.0 * (Q / D);`
  - `final nivelServicio = MathUtils.normalCdf(zScore);`
  - `final probRuptura = 1.0 - nivelServicio;`
  - `final fillRate = (1.0 - (backordersEsperados / Q)).clamp(0.0, 1.0);`
  - `final rotacion = inventarioPromedio > 0 ? D / inventarioPromedio : 0.0;`
  - `final costoUnitDemand = (costoPedidos + costoMantenimiento + costoServicio) / max(D, 1e-9);`
  - `final presupuestoArticulo = c * R;`

Y devolver estos campos en `ResultadoArticulo`.

## 4) Cambios en UI (tabla y exportación)

- Archivo: `lib/screens/resultados_screen.dart`
  - Añadir columnas: Φ(z), E[BO], fill rate, Ī, pedidos/año, días entre pedidos, rotación, CK, Ch, Cp, costo por unidad demandada, presupuesto artículo.
  - Mostrar porcentajes con 2 decimales y acotar a [0,100].
- Archivo: `lib/repositories/excel.repository.dart`
  - Exportar las nuevas columnas a la hoja “Resultados”.

## 5) Beneficios

- Analítico: separación clara de costos (CK, Ch, Cp) y métricas de servicio.
- Gestión: visibilidad de rotación, días entre pedidos y consumo de presupuesto/espacio por artículo.
- Docencia: trazabilidad completa desde parámetros → z → E[BO] → costos.
- Decisión: priorización por costo unitario demandado o por fill rate/rotación.

## 6) Consideraciones

- Estabilidad numérica: acotar divisiones (p. ej., D>0, Q>0) y valores en [0,1] para tasas.
- Formatos: 2 decimales para moneda y 2–3 para tasas.
- Performance: cálculo O(n) por artículo, sin impacto significativo.

## 7) Plan de implementación (incremental)

1) Extender `ResultadoArticulo` con campos opcionales.
2) Calcular y rellenar en `InventarioRepository` (sin romper fórmulas actuales).
3) Exponer en tabla de `ResultadosScreen` (sección “Avanzado”).
4) Exportar a Excel.
5) Añadir ayudas en `TutorialScreen` con nuevas fórmulas.

## 8) Autocalculado de Q y R (pendiente)

Objetivo: si un artículo llega sin Q o sin R, calcularlos automáticamente con fórmulas estándar, manteniendo consistencia con el resto del modelo.

- Q (Tamaño de lote) si falta → EOQ
  - Fórmula: Q* = sqrt(2 · D · K / H)
    - D: demanda anual
    - K: costo por pedido
    - H: costo anual de mantenimiento por unidad
  - Código (sitio): `lib/repositories/inventario.repository.dart`, al iniciar el bucle por artículo, antes de costos y z:
    - Si `articulo.tamanoLote <= 0`, calcular Q y usarlo para el resto (pedidos, costos, Ī, etc.).

- R (Punto de reorden) si falta → modelo (Q,R)
  - Fórmula: R = d · L + z · σL
    - d = D / 365
    - σL = σd · √L
    - z configurable según nivel de servicio objetivo (p. ej. default 1.65)
  - Código (sitio): `lib/repositories/inventario.repository.dart`, tras obtener μL y σL:
    - Si `articulo.puntoReorden < 0` o `== 0` (según convención), asignar R con la fórmula.

Parámetros de configuración sugeridos
- `zObjetivo` en `InventarioProvider` (p. ej., 1.65 por defecto), editable en el diálogo de restricciones.
- Bandera global `autoCalcularQR` para activar/desactivar este comportamiento.

Validaciones y consideraciones
- Asegurar `Q* >= 1` (clamp) y `R >= 0`.
- Si D == 0 o H == 0, no calcular EOQ (devolver valor mínimo o mantener Q actual).
- Mantener logs `debugPrint` indicando cuándo hubo autocalculado para trazabilidad.

Integración con importación Excel
- Si una celda de Q o R viene vacía/cero, el autocalculado rellenará valores al calcular resultados, y esos valores pueden mostrarse en UI y exportarse a Excel de resultados.

---
Última actualización: pendiente de aprobación docente.