import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inventario_qr/providers/inventario.provider.dart';
import 'package:inventario_qr/screens/ingresar_datos_screen.dart';
import 'package:inventario_qr/screens/resultados_screen.dart';
import 'package:inventario_qr/screens/tutorial_screen.dart';
import 'package:inventario_qr/utils/logger.dart';
import 'package:inventario_qr/utils/page_transitions.dart';
import 'package:inventario_qr/widgets/articulos_table.dart';
import 'package:inventario_qr/widgets/restriccion_dialog.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Inventario MDSJ'),
        actions: [
          // ✅ SOLO MOSTRAR BOTÓN DE DESCARGA EN WEB
          if (kIsWeb)
            IconButton(
              onPressed: () => _descargarAppWindows(context),
              icon: const Icon(UniconsLine.windows),
              tooltip: 'Descargar App Windows',
            ),
          IconButton(
            onPressed: () => NavigationHelper.pushSlideUp(
              context,
              const TutorialScreen(),
            ),
            icon: const Icon(UniconsLine.question_circle),
            tooltip: 'Ayuda',
          ),
          IconButton(
            onPressed: () => mostrarDialogoRestricciones(context),
            icon: const Icon(Icons.settings),
            tooltip: 'Configurar restricciones',
          ),
        ],
      ),
      body: Consumer<InventarioProvider>(
        builder: (context, provider, child) {
          logDebug(
              '🏠 HomeScreen: Consumer reconstruyendo - Artículos: ${provider.articulos.length}');
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSystemSummary(provider),
                const SizedBox(height: 32),
                _buildNavigationCards(context, provider),
                const SizedBox(height: 32),
                _buildArticulosTable(provider, context),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSystemSummary(InventarioProvider provider) {
    return Builder(
      builder: (context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(UniconsLine.info_circle,
                      color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  const Text(
                    'Resumen del Sistema',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Artículos',
                      '${provider.articulos.length}',
                      UniconsLine.box,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'Costo Total',
                      provider.resultado != null
                          ? 'S/ ${provider.resultado!.costoTotalSistema.toStringAsFixed(2)}'
                          : 'N/A',
                      UniconsLine.money_bill,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'Espacio Usado',
                      provider.resultado != null
                          ? '${provider.resultado!.espacioTotalUsado.toStringAsFixed(1)} m²'
                          : 'N/A',
                      UniconsLine.store,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon) {
    return Builder(
      builder: (context) => Column(
        children: [
          Icon(icon, size: 32, color: Theme.of(context).primaryColor),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCards(
      BuildContext context, InventarioProvider provider) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1200
        ? 3
        : width > 800
            ? 2
            : 1;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: [
        _buildNavigationCard(
          context,
          'Ingresar Datos',
          'Agregar artículos manualmente',
          UniconsLine.plus,
          Colors.teal,
          () => NavigationHelper.pushSlideLeft(
              context, const IngresarDatosScreen()),
        ),
        _buildNavigationCard(
          context,
          'Ver Resultados',
          'Mostrar cálculos detallados',
          UniconsLine.calculator,
          Colors.orange,
          () =>
              NavigationHelper.pushSlideLeft(context, const ResultadosScreen()),
          enabled: provider.resultado != null,
        ),
        _buildNavigationCard(
          context,
          'Limpiar Datos',
          'Eliminar todos los artículos',
          UniconsLine.trash,
          Colors.red,
          () => provider.limpiarDatos(),
          enabled: provider.articulos.isNotEmpty,
        ),

      ],
    );
  }

  Widget _buildNavigationCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback? onPressed, {
    bool enabled = true,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Tamaños aumentados para mejor legibilidad en contenedores grandes
    final titleFontSize = screenWidth > 1200
        ? 18.0
        : screenWidth > 800
            ? 16.0
            : 14.0;
    final subtitleFontSize = screenWidth > 1200
        ? 12.0
        : screenWidth > 800
            ? 11.0
            : 10.0;
    final iconSize = screenWidth > 1200
        ? 36.0
        : screenWidth > 800
            ? 32.0
            : 28.0;

    return _AnimatedNavigationCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      color: color,
      onPressed: enabled ? onPressed : null,
      enabled: enabled,
      titleFontSize: titleFontSize,
      subtitleFontSize: subtitleFontSize,
      iconSize: iconSize,
    );
  }

  Widget _buildArticulosTable(
      InventarioProvider provider, BuildContext context) {
    logDebug('🏠 HomeScreen: Construyendo tabla de artículos');
    logDebug(
        '🏠 HomeScreen: Total de artículos en provider: ${provider.articulos.length}');
    logDebug(
        '🏠 HomeScreen: Total de artículos en provider: ${provider.articulos.length}');
    logDebug(
        '🏠 HomeScreen: Nombres de artículos: ${provider.articulos.map((a) => a.nombre).toList()}');

    return ArticulosTable(
      articulos: provider.articulos,
      title: 'Artículos en Inventario',
      height: 300,
    );
  }

  /// ✅ DESCARGAR APP WINDOWS DESDE ASSETS
  Future<void> _descargarAppWindows(BuildContext context) async {
    try {
      logDebug('📦 HomeScreen: Iniciando descarga de app Windows...');
      
      // Descargar el archivo ZIP usando el provider
      final provider = context.read<InventarioProvider>();
      final resultado = await provider.descargarArchivoZip('WindowsApp.zip');
      
      if (resultado != null) {
        logDebug('✅ HomeScreen: App Windows descargada exitosamente: $resultado');
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Descarga de app Windows iniciada: WindowsApp.zip'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      logDebug('❌ HomeScreen: Error al descargar app Windows: $e');
      
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Error de Descarga'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No se pudo descargar la app para Windows:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$e',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Asegúrate de que el archivo WindowsApp.zip esté en assets/templates/',
                            style: TextStyle(fontSize: 14, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      }
    }
  }
}

/// Widget de tarjeta de navegación con animación de presión
class _AnimatedNavigationCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool enabled;
  final double titleFontSize;
  final double subtitleFontSize;
  final double iconSize;

  const _AnimatedNavigationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.enabled,
    required this.titleFontSize,
    required this.subtitleFontSize,
    required this.iconSize,
  });

  @override
  State<_AnimatedNavigationCard> createState() =>
      _AnimatedNavigationCardState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('iconSize', iconSize))
      ..add(DoubleProperty('titleFontSize', titleFontSize))
      ..add(StringProperty('subtitle', subtitle))
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(ColorProperty('color', color))
      ..add(ObjectFlagProperty<VoidCallback?>.has('onPressed', onPressed))
      ..add(DiagnosticsProperty<bool>('enabled', enabled))
      ..add(DoubleProperty('subtitleFontSize', subtitleFontSize))
      ..add(StringProperty('title', title));
  }
}

class _AnimatedNavigationCardState extends State<_AnimatedNavigationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.enabled) {
      setState(() {
        _isPressed = true;
      });
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.enabled) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.enabled) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Card(
            elevation: _elevationAnimation.value,
            child: GestureDetector(
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: _onTapCancel,
              onTap: widget.enabled ? widget.onPressed : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 14.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _isPressed && widget.enabled
                      ? widget.color.withValues(alpha: 0.1)
                      : Colors.transparent,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.icon,
                      size: widget.iconSize,
                      color: widget.enabled ? widget.color : Colors.grey,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: widget.titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: widget.enabled ? Colors.black : Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: widget.subtitleFontSize,
                        color: widget.enabled ? Colors.grey : Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
