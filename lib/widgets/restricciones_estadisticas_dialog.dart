import 'package:flutter/material.dart';
import 'package:inventario_qr/providers/inventario.provider.dart';
import 'package:inventario_qr/utils/math_utils.dart';
import 'package:inventario_qr/utils/theme_colors.dart';
import 'package:inventario_qr/widgets/restriccion_dialog.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

class RestriccionesEstadisticasDialog extends StatelessWidget {
  const RestriccionesEstadisticasDialog({super.key});

  /// Calcula el valor disponible basado en el ratio y el límite máximo
  String _calcularDisponible(double ratio, String maxLabel) {
    if (ratio >= 1.0) {
      return '0.00';
    }

    // Extraer el valor numérico del límite máximo
    final valorLimite =
        double.tryParse(maxLabel.replaceAll(RegExp(r'[^\d.-]'), '')) ?? 0.0;
    final valorDisponible = valorLimite * (1.0 - ratio);

    // Determinar el formato basado en el tipo de dato
    if (maxLabel.contains('m²')) {
      return '${valorDisponible.toStringAsFixed(2)} m²';
    } else if (maxLabel.contains('S/')) {
      return MathUtils.formatearMoneda(valorDisponible);
    } else {
      return valorDisponible.toStringAsFixed(0);
    }
  }

  /// Calcula el exceso cuando se supera el límite
  String _calcularExceso(double ratio, String usadoLabel) {
    if (ratio <= 1.0) {
      return '';
    }

    // Extraer el valor numérico del usado
    final valorUsado =
        double.tryParse(usadoLabel.replaceAll(RegExp(r'[^\d.-]'), '')) ?? 0.0;
    final valorExceso = valorUsado * (ratio - 1.0);

    // Determinar el formato basado en el tipo de dato
    if (usadoLabel.contains('m²')) {
      return '${valorExceso.toStringAsFixed(2)} m²';
    } else if (usadoLabel.contains('S/')) {
      return MathUtils.formatearMoneda(valorExceso);
    } else {
      return valorExceso.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventarioProvider>();
    final resultado = provider.resultado;

    Widget buildItem({
      required IconData icon,
      required String titulo,
      required String usadoLabel,
      required String maxLabel,
      required double ratio,
      required Color color,
    }) {
      ratio = ratio.clamp(0.0, 1.2);
      final barValue = ratio.clamp(0.0, 1.0);
      final stateColor = ratio >= 1.0
          ? const Color(0xFFE53935) // rojo visible
          : (ratio >= 0.8 ? const Color(0xFFFFA000) : color);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: stateColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: MDSJColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${(barValue * 100).round()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: stateColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: barValue,
                backgroundColor: Colors.transparent,
                color: stateColor,
                minHeight: 12,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Usado: $usadoLabel',
                style: const TextStyle(
                    fontSize: 14, color: MDSJColors.textPrimary),
              ),
              Text(
                'Límite: $maxLabel',
                style: const TextStyle(
                    fontSize: 14, color: MDSJColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Disponible: ${_calcularDisponible(ratio, maxLabel)}',
                style: TextStyle(
                  fontSize: 13,
                  color: ratio >= 1.0
                      ? const Color(0xFFE53935) // rojo si excede
                      : const Color(0xFF43A047), // verde si hay espacio
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (ratio > 1.0)
                Text(
                  'Exceso: ${_calcularExceso(ratio, usadoLabel)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFE53935),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header del diálogo
                const Row(
                  children: [
                    Icon(UniconsLine.analytics,
                        color: MDSJColors.primary, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Uso de Restricciones',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Contenido del diálogo
                if (resultado == null) const Text(
                        'No hay resultados disponibles aún. Agrega artículos o importa desde Excel.',
                        style: TextStyle(
                            fontSize: 15, color: MDSJColors.textPrimary)) else Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          buildItem(
                            icon: UniconsLine.store,
                            titulo: 'Espacio',
                            usadoLabel:
                                '${resultado.espacioTotalUsado.toStringAsFixed(2)} m²',
                            maxLabel:
                                '${provider.espacioMaximo.toStringAsFixed(2)} m²',
                            ratio: provider.espacioMaximo > 0
                                ? resultado.espacioTotalUsado /
                                    provider.espacioMaximo
                                : 0.0,
                            color: const Color(0xFF757575),
                          ),
                          const SizedBox(height: 16),
                          buildItem(
                            icon: UniconsLine.money_bill,
                            titulo: 'Presupuesto',
                            usadoLabel:
                                MathUtils.formatearMoneda(resultado.presupuestoTotal),
                            maxLabel:
                                MathUtils.formatearMoneda(provider.presupuestoMaximo),
                            ratio: provider.presupuestoMaximo > 0
                                ? resultado.presupuestoTotal /
                                    provider.presupuestoMaximo
                                : 0.0,
                            color: const Color(0xFF43A047),
                          ),
                          const SizedBox(height: 16),
                          buildItem(
                            icon: UniconsLine.box,
                            titulo: 'Pedidos',
                            usadoLabel:
                                resultado.numeroTotalPedidos.toStringAsFixed(0),
                            maxLabel:
                                provider.numeroMaximoPedidos.toStringAsFixed(0),
                            ratio: provider.numeroMaximoPedidos > 0
                                ? resultado.numeroTotalPedidos /
                                    provider.numeroMaximoPedidos
                                : 0.0,
                            color: const Color(0xFF8E24AA),
                          ),
                        ],
                      ),
                const SizedBox(height: 24),
                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child:
                          const Text('Cerrar', style: TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        mostrarDialogoRestricciones(context);
                      },
                      icon: const Icon(Icons.settings, size: 16),
                      label: const Text('Configurar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MDSJColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void mostrarDialogoEstadisticasRestricciones(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => const RestriccionesEstadisticasDialog(),
  );
}
