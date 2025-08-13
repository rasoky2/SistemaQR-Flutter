# Sistema QR de Inventario

Una aplicación de escritorio desarrollada en **Flutter** con **FluentUI** para la gestión de inventario multi-artículo bajo el modelo QR (Quantity-Reorder point) con restricciones.

## 🎯 Características

### Funcionalidades Principales
- **Modelo QR de Inventario**: Implementación completa del modelo Quantity-Reorder point
- **Gestión Multi-Artículo**: Soporte para múltiples artículos con diferentes parámetros
- **Restricciones del Sistema**: Validación de espacio, presupuesto y número de pedidos
- **Importación/Exportación Excel**: Manejo completo de archivos `.xlsx` y `.xls`
- **Interfaz FluentUI**: Diseño moderno optimizado para Windows Desktop
- **Cálculos Automáticos**: Evaluación automática del modelo con resultados detallados

### Parámetros por Artículo
- **Demanda Anual** (D): Demanda esperada por año
- **Costo por Pedido** (K): Costo fijo por realizar un pedido
- **Costo de Mantenimiento** (h): Costo anual por mantener una unidad en inventario
- **Costo por Faltante** (p): Penalización por unidad faltante
- **Costo Unitario** (c): Precio de compra por unidad
- **Espacio por Unidad** (s): Espacio requerido por unidad (m²)
- **Desviación Estándar Diaria** (σ): Variabilidad de la demanda diaria
- **Punto de Reorden** (R): Nivel de inventario para reordenar
- **Tamaño de Lote** (Q): Cantidad a ordenar

### Restricciones del Sistema
1. **Espacio**: Σ(sᵢ × Rᵢ) ≤ S_max
2. **Presupuesto**: Σ(cᵢ × Rᵢ) ≤ C_max  
3. **Número de Pedidos**: Σ(Dᵢ/Qᵢ) ≤ N_max

## 🏗️ Arquitectura

### Estructura del Proyecto
```
lib/
├── models/
│   ├── articulo.model.dart      # Modelo de datos para artículos
│   └── resultado.model.dart     # Modelo de resultados del cálculo
├── repositories/
│   ├── inventario.repository.dart  # Lógica de negocio del modelo QR
│   └── excel.repository.dart       # Manejo de archivos Excel
├── providers/
│   └── inventario.provider.dart    # Gestión de estado con Provider
├── screens/
│   ├── home_screen.dart            # Pantalla principal
│   ├── resultados_screen.dart      # Visualización de resultados
│   └── configuracion_screen.dart  # Configuración del sistema
├── utils/
│   └── math_utils.dart             # Utilidades matemáticas
└── main.dart                       # Punto de entrada de la aplicación
```

### Flujo de Datos
```
Screens → Providers → Repositories → Models
```

## 📊 Fórmulas del Modelo QR

### Función Objetivo (revisada)
```
TC = Σ( Dᵢ/Qᵢ × Kᵢ
      + (Qᵢ/2 + max(0, Rᵢ − μLᵢ) − E[Bᵢ]) × hᵢ
      + (Dᵢ/Qᵢ) × E[Bᵢ] × pᵢ )
```

### Cálculos Intermedios
- **Demanda en Lead Time**: μ_L = D × (L/365)
- **Desviación en Lead Time**: σ_L = σ × √L
- **Z-Score**: z = (R - μ_L) / σ_L
- **Backorders Esperados**: E[B] = σ_L × L(z)
## 📝 Roadmap y notas

- [ ] Autocalcular Q y R cuando falten datos
  - Q*: sqrt(2·D·S/H)
  - R: d·L + z·σL, con d = D/365 y z configurable


Donde L(z) es la función de pérdida normal estándar.

## 🚀 Instalación y Uso

### Requisitos
- Flutter SDK 3.0.0 o superior
- Windows 10/11 para desarrollo de escritorio

### Instalación
```bash
# Clonar el repositorio
git clone <repository-url>
cd inventario_qr

# Instalar dependencias
flutter pub get

# Ejecutar la aplicación
flutter run -d windows
```

### Uso Básico
1. **Cargar Datos**: Usar "Datos de Ejemplo" o "Importar Datos" desde Excel
2. **Configurar Parámetros**: Ajustar restricciones en la pantalla de configuración
3. **Ejecutar Cálculos**: Los resultados se calculan automáticamente
4. **Ver Resultados**: Revisar resultados detallados en la pantalla correspondiente
5. **Exportar**: Guardar resultados en formato Excel

## 📁 Estructura de Archivos Excel

### Archivo de Entrada (Artículos)
| Columna | Descripción | Ejemplo |
|---------|-------------|---------|
| Nombre | Nombre del artículo | "Artículo 1" |
| DemandaAnual | Demanda anual (unidades) | 1200 |
| CostoPedido | Costo por pedido ($) | 100 |
| CostoMantenimiento | Costo anual de mantenimiento ($) | 2 |
| CostoFaltante | Penalización por faltante ($) | 5 |
| CostoUnitario | Precio unitario ($) | 20 |
| EspacioUnidad | Espacio por unidad (m²) | 0.5 |
| DesviacionDiaria | Desviación estándar diaria | 2 |
| PuntoReorden | Punto de reorden (unidades) | 120 |
| TamanoLote | Tamaño de lote (unidades) | 200 |

### Archivo de Salida (Resultados)
- **Hoja 1**: Resumen del sistema
- **Hoja 2**: Resultados por artículo
- **Hoja 3**: Detalles de restricciones

## 🎨 Interfaz de Usuario

### Características de FluentUI
- **Diseño Nativo de Windows**: Interfaz que sigue las directrices de Microsoft
- **Navegación Intuitiva**: Uso de CommandBar y PageHeader
- **Componentes Modernos**: Cards, Buttons, TextFormBox optimizados para escritorio
- **Responsive Design**: Adaptado específicamente para pantallas de escritorio
- **Accesibilidad**: Soporte completo para lectores de pantalla y navegación por teclado

### Pantallas Principales
1. **Home Screen**: Dashboard principal con resumen y navegación
2. **Resultados Screen**: Visualización detallada de cálculos y estadísticas
3. **Configuración Screen**: Ajuste de parámetros del sistema

## ⚙️ Configuración del Sistema

### Parámetros Globales
- **Lead Time**: Tiempo de entrega en días (default: 36.5)
- **Espacio Máximo**: Capacidad del almacén en m² (default: 150.0)
- **Presupuesto Máximo**: Presupuesto total disponible en $ (default: 10,000.0)
- **Número Máximo de Pedidos**: Límite de pedidos por año (default: 100.0)

## 📈 Interpretación de Resultados

### Métricas Clave
- **Z-Score**: Indica el nivel de servicio (mayor = mejor servicio)
- **Backorders Esperados**: Cantidad promedio de faltantes
- **Costo Total**: Suma de costos de pedidos, mantenimiento y faltantes
- **Espacio Usado**: Espacio total requerido por el inventario

### Validación de Restricciones
- ✅ **Verde**: Restricción cumplida
- ❌ **Rojo**: Restricción violada
- ⚠️ **Amarillo**: Restricción en el límite

## 🔧 Desarrollo

### Dependencias Principales
```yaml
dependencies:
  fluent_ui: ^4.7.4          # Interfaz de usuario para Windows
  provider: ^6.1.1            # Gestión de estado
  excel: ^2.1.0               # Manejo de archivos Excel
  file_picker: ^8.0.0+1       # Selección de archivos
  path_provider: ^2.1.2       # Acceso al sistema de archivos
```

### Estructura de Estado
```dart
class InventarioProvider extends ChangeNotifier {
  List<Articulo> articulos = [];
  ResultadoSistema? resultado;
  bool isLoading = false;
  String? error;
  // ... configuración del sistema
}
```