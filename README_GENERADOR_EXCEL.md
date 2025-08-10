# 📊 Generador de Plantilla Excel

Este script de Python genera la plantilla Excel perfectamente formateada para el Sistema de Inventario QR.

## 🚀 Instalación

```bash
# Instalar dependencias
pip install -r requirements.txt

# O instalar directamente
pip install openpyxl
```

## 📋 Uso

```bash
# Ejecutar el generador
python generate_excel_template.py
```

## 📁 Salida

El script genera el archivo `assets/templates/plantilla_inventario.xlsx` con:

### 📊 Hoja 1: "Plantilla Inventario"
- **Encabezados profesionales** con formato azul y texto blanco
- **8 artículos de ejemplo** con datos realistas:
  - Laptop HP EliteBook
  - Mouse Logitech MX Master  
  - Teclado Mecánico Gaming
  - Monitor 24" Dell
  - Impresora Láser HP
  - Tablet Samsung Galaxy
  - Auriculares Sony WH-1000XM4
  - Cámara Web Logitech C920
- **Formato numérico** apropiado para cada columna
- **Bordes y alineación** profesional
- **Anchos de columna** optimizados

### 📖 Hoja 2: "Instrucciones"
- **Guía paso a paso** para usar la plantilla
- **Descripción detallada** de cada campo
- **Información del modelo matemático** EOQ
- **Notas importantes** y recomendaciones
- **Formato con colores** para diferentes tipos de información

### 📈 Hoja 3: "Ejemplo Resultados"
- **Resultados de ejemplo** del modelo QR
- **Métricas calculadas**: Q* óptimo, costos, frecuencias
- **Formato profesional** para comparación

## 🎯 Ventajas

- ✅ **Formato consistente** y profesional
- ✅ **Datos de ejemplo realistas** 
- ✅ **Múltiples hojas** con información completa
- ✅ **Fácil de modificar** el script para cambios futuros
- ✅ **Compatible** con Excel, LibreOffice, Google Sheets
- ✅ **Optimizado** para el flujo de trabajo del proyecto

## 🔧 Personalización

Para modificar la plantilla, edita las variables en `generate_excel_template.py`:

- `headers`: Nombres de las columnas
- `datos_ejemplo`: Filas de datos de ejemplo
- `instrucciones`: Contenido de la hoja de instrucciones
- Estilos y colores en las variables de formato

## 📝 Notas Técnicas

- **Librería**: `openpyxl` para manipulación de Excel
- **Formato**: Excel 2010+ (.xlsx)
- **Compatibilidad**: Funciona en Windows, macOS, Linux
- **Tamaño típico**: ~15-20 KB del archivo generado

## 🚀 Integración con Flutter

Una vez generado, el archivo Excel se coloca en `assets/templates/` y la aplicación Flutter:

1. **Lee el archivo** desde assets para generar templates
2. **Convierte automáticamente** a formato de descarga
3. **Mantiene compatibilidad** total con web, móvil y escritorio

¡Tu idea de pre-generar el Excel fue brillante! 🎉
