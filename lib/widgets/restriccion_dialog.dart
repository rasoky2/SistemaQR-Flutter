import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inventario_qr/providers/inventario.provider.dart';
import 'package:inventario_qr/utils/theme_colors.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

class RestriccionDialog extends StatefulWidget {
  const RestriccionDialog({super.key});

  @override
  State<RestriccionDialog> createState() => _RestriccionDialogState();
}

class _RestriccionDialogState extends State<RestriccionDialog> {
  late TextEditingController _leadTimeController;
  late TextEditingController _espacioMaximoController;
  late TextEditingController _presupuestoMaximoController;
  late TextEditingController _numeroMaximoPedidosController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<InventarioProvider>();
    _leadTimeController = TextEditingController(text: provider.leadTimeDias.toString());
    _espacioMaximoController = TextEditingController(text: provider.espacioMaximo.toString());
    _presupuestoMaximoController = TextEditingController(text: provider.presupuestoMaximo.toString());
    _numeroMaximoPedidosController = TextEditingController(text: provider.numeroMaximoPedidos.toString());
  }

  @override
  void dispose() {
    _leadTimeController.dispose();
    _espacioMaximoController.dispose();
    _presupuestoMaximoController.dispose();
    _numeroMaximoPedidosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<InventarioProvider>();
    
    return AlertDialog(
      title: Row(
        children: [
                          const Icon(UniconsLine.setting, color: MDSJColors.primary),
          const SizedBox(width: 8),
          Text(
            'Configurar Restricciones',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildConfigField(
              'Lead Time (días)',
              _leadTimeController,
              (value) => provider.actualizarConfiguracion(leadTimeDias: double.tryParse(value) ?? 36.5),
                              icon: UniconsLine.clock,
              tooltip: 'Tiempo promedio de entrega de pedidos',
            ),
            const SizedBox(height: 20),
            _buildConfigField(
              'Espacio Máximo (m²)',
              _espacioMaximoController,
              (value) => provider.actualizarConfiguracion(espacioMaximo: double.tryParse(value) ?? 150.0),
                              icon: UniconsLine.store,
              tooltip: 'Capacidad máxima de almacenamiento',
            ),
            const SizedBox(height: 20),
            _buildConfigField(
              'Presupuesto Máximo (S/)',
              _presupuestoMaximoController,
              (value) => provider.actualizarConfiguracion(presupuestoMaximo: double.tryParse(value) ?? 10000.0),
                              icon: UniconsLine.money_bill,
              tooltip: 'Límite de presupuesto para el inventario',
            ),
            const SizedBox(height: 20),
            _buildConfigField(
              'Número Máximo de Pedidos',
              _numeroMaximoPedidosController,
              (value) => provider.actualizarConfiguracion(numeroMaximoPedidos: double.tryParse(value) ?? 100.0),
                              icon: UniconsLine.box,
              tooltip: 'Cantidad máxima de pedidos permitidos',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MDSJColors.infoBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: MDSJColors.infoBorder),
              ),
              child: Row(
                children: [
                  const Icon(UniconsLine.info_circle, size: 16, color: MDSJColors.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Estos valores afectan los cálculos del modelo QR y las restricciones del sistema.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: MDSJColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _mostrarConfirmacion(context);
          },
          child: Text(
            'Guardar',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildConfigField(
    String label,
    TextEditingController controller,
    Function(String) onChanged, {
    IconData? icon,
    String? tooltip,
  }) {
    final focusNode = FocusNode();
    
    // Seleccionar todo el texto al obtener el foco
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
      }
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: MDSJColors.primary),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: MDSJColors.textPrimary,
                ),
              ),
            ),
            if (tooltip != null) ...[
              const SizedBox(width: 4),
                              const Icon(UniconsLine.info_circle, size: 14, color: MDSJColors.textSecondary),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Ingrese un valor',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: MDSJColors.primary, width: 2),
            ),
          ),
        ),
        if (tooltip != null) ...[
          const SizedBox(height: 4),
          Text(
            tooltip,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: MDSJColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  void _mostrarConfirmacion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
                            const Icon(UniconsLine.check_circle, color: MDSJColors.success),
            const SizedBox(width: 8),
            Text(
              'Configuración Guardada',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Los cambios se han aplicado correctamente.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Aceptar',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// Función helper para mostrar el diálogo de restricciones
void mostrarDialogoRestricciones(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const RestriccionDialog(),
  );
}
