import 'package:flutter/material.dart';
import 'package:inventario_qr/providers/inventario.provider.dart';
import 'package:inventario_qr/widgets/restricciones_estadisticas_dialog.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

class RestriccionFab extends StatefulWidget {
  const RestriccionFab({super.key});

  @override
  State<RestriccionFab> createState() => _RestriccionFabState();
}

class _RestriccionFabState extends State<RestriccionFab> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<InventarioProvider>(
      builder: (context, provider, _) {
        final resultado = provider.resultado;
        double ratio = 0.0;
        Color color = Colors.green;
        String tooltip = 'Uso de restricciones';
        IconData centerIcon = UniconsLine.analytics;
        String? exceededLabel;

        double espacioRatio = 0;
        double presupuestoRatio = 0;
        double pedidosRatio = 0;
        if (resultado != null) {
          espacioRatio = provider.espacioMaximo > 0
              ? (resultado.espacioTotalUsado / provider.espacioMaximo)
              : 0.0;
          presupuestoRatio = provider.presupuestoMaximo > 0
              ? (resultado.presupuestoTotal / provider.presupuestoMaximo)
              : 0.0;
          pedidosRatio = provider.numeroMaximoPedidos > 0
              ? (resultado.numeroTotalPedidos / provider.numeroMaximoPedidos)
              : 0.0;

          // Determinar la restricción más exigida
          final pairs = <String, double>{
            'Espacio': espacioRatio,
            'Presupuesto': presupuestoRatio,
            'Pedidos': pedidosRatio,
          };
          String maxKey = 'Espacio';
          double maxVal = -1;
          pairs.forEach((k, v) {
            if (v.isFinite && v >= 0 && v > maxVal) {
              maxVal = v;
              maxKey = k;
            }
          });
          ratio = maxVal.clamp(0.0, 1.2);

          if (maxKey == 'Espacio') {
            centerIcon = UniconsLine.store;
          }
          if (maxKey == 'Presupuesto') {
            centerIcon = UniconsLine.money_bill;
          }
          if (maxKey == 'Pedidos') {
            centerIcon = UniconsLine.box;
          }

          if (ratio >= 1.0) {
            color = Colors.red;
            exceededLabel = '¡$maxKey superado!';
            tooltip = '¡$maxKey superado!';
          } else if (ratio >= 0.8) {
            color = Colors.orange;
            tooltip = 'Cerca del límite de $maxKey';
          } else {
            color = Colors.green;
            tooltip = 'Uso de $maxKey dentro del límite';
          }

          // Tooltip detallado
          String detalle;
          switch (maxKey) {
            case 'Espacio':
              detalle =
                  'Usado: ${resultado.espacioTotalUsado.toStringAsFixed(2)} / '
                  '${provider.espacioMaximo.toStringAsFixed(2)} m²';
              break;
            case 'Presupuesto':
              detalle =
                  'Usado: S/ ${resultado.presupuestoTotal.toStringAsFixed(2)} / '
                  'S/ ${provider.presupuestoMaximo.toStringAsFixed(2)}';
              break;
            default:
              detalle = 'Usado: ${resultado.numeroTotalPedidos} / '
                  '${provider.numeroMaximoPedidos} pedidos';
          }
          tooltip = '$tooltip\n$detalle';
        }

        final barValue = ratio.clamp(0.0, 1.0);

        final fab = FloatingActionButton(
          onPressed: () => mostrarDialogoEstadisticasRestricciones(context),
          tooltip: tooltip,
          backgroundColor: Colors.white,
          shape: const CircleBorder(),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    value: barValue,
                    strokeWidth: 5,
                    color: color,
                    backgroundColor: Colors.white,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: ratio >= 1.0
                      ? Icon(centerIcon,
                          key: const ValueKey('icon'), color: color, size: 20)
                      : Text(
                          '${(barValue * 100).round()}%',
                          key: const ValueKey('text'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                ),
              ],
            ),
          ),
        );

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: _isHovering && (exceededLabel != null)
                    ? Container(
                        key: const ValueKey('label'),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border:
                              Border.all(color: color.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            Icon(centerIcon, size: 14, color: color),
                            const SizedBox(width: 6),
                            Text(
                              exceededLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              if (_isHovering && (exceededLabel != null))
                const SizedBox(width: 8),
              fab,
            ],
          ),
        );
      },
    );
  }
}
