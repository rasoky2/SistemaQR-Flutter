import 'package:fluent_ui/fluent_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inventario_qr/providers/inventario.provider.dart';
import 'package:provider/provider.dart';

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
    
    return ContentDialog(
      title: Row(
        children: [
          Icon(FluentIcons.settings, color: Colors.blue),
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
              icon: FluentIcons.clock,
              tooltip: 'Tiempo promedio de entrega de pedidos',
            ),
            const SizedBox(height: 20),
            _buildConfigField(
              'Espacio Máximo (m²)',
              _espacioMaximoController,
              (value) => provider.actualizarConfiguracion(espacioMaximo: double.tryParse(value) ?? 150.0),
              icon: FluentIcons.database,
              tooltip: 'Capacidad máxima de almacenamiento',
            ),
            const SizedBox(height: 20),
            _buildConfigField(
              'Presupuesto Máximo (S/)',
              _presupuestoMaximoController,
              (value) => provider.actualizarConfiguracion(presupuestoMaximo: double.tryParse(value) ?? 10000.0),
              icon: FluentIcons.money,
              tooltip: 'Límite de presupuesto para el inventario',
            ),
            const SizedBox(height: 20),
            _buildConfigField(
              'Número Máximo de Pedidos',
              _numeroMaximoPedidosController,
              (value) => provider.actualizarConfiguracion(numeroMaximoPedidos: double.tryParse(value) ?? 100.0),
              icon: FluentIcons.package,
              tooltip: 'Cantidad máxima de pedidos permitidos',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(FluentIcons.info, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Estos valores afectan los cálculos del modelo QR y las restricciones del sistema.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.blue,
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
        Button(
          child: Text(
            'Cancelar',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        Button(
          child: Text(
            'Guardar',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          onPressed: () {
            Navigator.pop(context);
            _mostrarConfirmacion(context);
          },
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
              Icon(icon, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            if (tooltip != null) ...[
              const SizedBox(width: 4),
              const Icon(FluentIcons.info, size: 14, color: Colors.grey),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormBox(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          placeholder: 'Ingrese un valor',
          decoration: WidgetStateProperty.all(BoxDecoration(
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(4),
          )),
        ),
        if (tooltip != null) ...[
          const SizedBox(height: 4),
          Text(
            tooltip,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ],
    );
  }

  void _mostrarConfirmacion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Row(
          children: [
            Icon(FluentIcons.check_mark, color: Colors.green),
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
          Button(
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
