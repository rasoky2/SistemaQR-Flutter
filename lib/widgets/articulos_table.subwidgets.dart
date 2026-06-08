import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inventario_qr/utils/theme_colors.dart';
import 'package:unicons/unicons.dart';

/// Widget que se muestra cuando no hay artículos registrados en el inventario.
class SinArticulosPlaceholder extends StatelessWidget {
  const SinArticulosPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MDSJColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  UniconsLine.box,
                  size: 48,
                  color: MDSJColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No hay artículos agregados',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: MDSJColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Agrega artículos usando el formulario de arriba',
                style: TextStyle(
                  fontSize: 16,
                  color: MDSJColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: MDSJColors.infoBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: MDSJColors.infoBorder),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      UniconsLine.info_circle,
                      size: 16,
                      color: MDSJColors.primary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Los artículos aparecerán aquí',
                      style: TextStyle(
                        fontSize: 14,
                        color: MDSJColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Diálogo modal para confirmar la eliminación de uno o más artículos seleccionados.
class ConfirmarEliminacionDialog extends StatelessWidget {
  final int cantidadArticulos;
  final VoidCallback onConfirmar;

  const ConfirmarEliminacionDialog({
    super.key,
    required this.cantidadArticulos,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    final esPlural = cantidadArticulos != 1;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(UniconsLine.trash, color: Colors.red, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Confirmar Eliminación'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Estás seguro de que deseas eliminar $cantidadArticulos artículo${esPlural ? 's' : ''} seleccionado${esPlural ? 's' : ''}?',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(UniconsLine.exclamation_triangle,
                    color: Colors.red, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Esta acción no se puede deshacer',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
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
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirmar();
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Eliminar'),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<int>('cantidadArticulos', cantidadArticulos))
      ..add(ObjectFlagProperty<VoidCallback>.has('onConfirmar', onConfirmar));
  }
}
