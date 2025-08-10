import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inventario_qr/providers/inventario.provider.dart';
import 'package:inventario_qr/screens/ingresar_datos_screen.dart';
import 'package:inventario_qr/screens/resultados_screen.dart';
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
          IconButton(
              onPressed: () => mostrarDialogoRestricciones(context),
            icon: const Icon(Icons.settings),
            tooltip: 'Configurar restricciones',
            ),
          ],
      ),
      body: Consumer<InventarioProvider>(
        builder: (context, provider, child) {
          debugPrint('🏠 HomeScreen: Consumer reconstruyendo - Artículos: ${provider.articulos.length}');
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
                  Icon(UniconsLine.info_circle, color: Theme.of(context).primaryColor),
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

  Widget _buildNavigationCards(BuildContext context, InventarioProvider provider) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
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
          () => NavigationHelper.pushSlideLeft(context, const IngresarDatosScreen()),
        ),
        _buildNavigationCard(
          context,
          'Datos de Ejemplo',
          'Cargar datos de prueba',
          UniconsLine.bolt,
          Colors.green,
          () => provider.cargarDatosEjemplo(),
        ),
        _buildNavigationCard(
          context,
          'Ver Resultados',
          'Mostrar cálculos detallados',
          UniconsLine.calculator,
          Colors.orange,
          () => NavigationHelper.pushSlideLeft(context, const ResultadosScreen()),
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
    
    // Tamaño de fuente responsivo basado en el ancho de la pantalla
    final titleFontSize = screenWidth > 1200 ? 14.0 : 
                         screenWidth > 800 ? 12.0 : 10.0;
    final subtitleFontSize = screenWidth > 1200 ? 10.0 : 
                           screenWidth > 800 ? 8.0 : 6.0;
    final iconSize = screenWidth > 1200 ? 24.0 : 
                    screenWidth > 800 ? 20.0 : 16.0;
    
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

  Widget _buildArticulosTable(InventarioProvider provider, BuildContext context) {
    debugPrint('🏠 HomeScreen: Construyendo tabla de artículos');
    debugPrint('🏠 HomeScreen: Total de artículos en provider: ${provider.articulos.length}');
    debugPrint('🏠 HomeScreen: Nombres de artículos: ${provider.articulos.map((a) => a.nombre).toList()}');
    
    return ArticulosTable(
      articulos: provider.articulos,
      title: 'Artículos en Inventario',
      height: 300,
    );
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
  State<_AnimatedNavigationCard> createState() => _AnimatedNavigationCardState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DoubleProperty('iconSize', iconSize))
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
                padding: const EdgeInsets.all(8.0),
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
                    const SizedBox(height: 4),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: widget.titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: widget.enabled ? Colors.black : Colors.grey,
                      ),
                  textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
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