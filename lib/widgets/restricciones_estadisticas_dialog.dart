import 'package:flutter/material.dart';
import 'package:inventario_qr/providers/inventario.provider.dart';
import 'package:inventario_qr/utils/theme_colors.dart';
import 'package:inventario_qr/widgets/restriccion_dialog.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

class RestriccionesEstadisticasDialog extends StatelessWidget {
  const RestriccionesEstadisticasDialog({super.key});

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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: MDSJColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${(barValue * 100).round()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: stateColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: barValue,
              backgroundColor: const Color(0xFFE6EEF2),
              color: stateColor,
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Usado: $usadoLabel',
                style: const TextStyle(fontSize: 13, color: MDSJColors.textPrimary),
              ),
              Text(
                'Límite: $maxLabel',
                style: const TextStyle(fontSize: 13, color: MDSJColors.textPrimary),
              ),
            ],
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Row(
        children: [
          Icon(UniconsLine.analytics, color: MDSJColors.primary, size: 18),
          SizedBox(width: 8),
          Text('Uso de Restricciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: MDSJColors.textPrimary)),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: (resultado == null)
            ? const Text('No hay resultados disponibles aún. Agrega artículos o importa desde Excel.',
                style: TextStyle(fontSize: 14, color: MDSJColors.textPrimary))
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildItem(
                    icon: UniconsLine.store,
                    titulo: 'Espacio',
                    usadoLabel: '${resultado.espacioTotalUsado.toStringAsFixed(2)} m²',
                    maxLabel: '${provider.espacioMaximo.toStringAsFixed(2)} m²',
                    ratio: provider.espacioMaximo > 0
                        ? resultado.espacioTotalUsado / provider.espacioMaximo
                        : 0.0,
                    color: const Color(0xFF1E88E5),
                  ),
                  const SizedBox(height: 16),
                  buildItem(
                    icon: UniconsLine.money_bill,
                    titulo: 'Presupuesto',
                    usadoLabel: 'S/ ${resultado.presupuestoTotal.toStringAsFixed(2)}',
                    maxLabel: 'S/ ${provider.presupuestoMaximo.toStringAsFixed(2)}',
                    ratio: provider.presupuestoMaximo > 0
                        ? resultado.presupuestoTotal / provider.presupuestoMaximo
                        : 0.0,
                    color: const Color(0xFF43A047),
                  ),
                  const SizedBox(height: 16),
                  buildItem(
                    icon: UniconsLine.box,
                    titulo: 'Pedidos',
                    usadoLabel: resultado.numeroTotalPedidos.toStringAsFixed(0),
                    maxLabel: provider.numeroMaximoPedidos.toStringAsFixed(0),
                    ratio: provider.numeroMaximoPedidos > 0
                        ? resultado.numeroTotalPedidos / provider.numeroMaximoPedidos
                        : 0.0,
                    color: const Color(0xFF8E24AA),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar', style: TextStyle(fontSize: 13)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            mostrarDialogoRestricciones(context);
          },
          child: const Text('Configurar', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}

void mostrarDialogoEstadisticasRestricciones(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => const RestriccionesEstadisticasDialog(),
  );
}


