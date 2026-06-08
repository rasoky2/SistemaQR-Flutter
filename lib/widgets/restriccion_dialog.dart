import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inventario_qr/providers/inventario.provider.dart';
import 'package:inventario_qr/utils/math_utils.dart';
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

  // Controladores para configuraciones de redondeo
  late String _tipoRedondeoPuntoReorden;
  late String _tipoRedondeoTamanoLote;
  late int _decimalesPuntoReorden;
  late int _decimalesTamanoLote;
  late bool _redondeosVinculados;
  late String _formatoSeparadores;

  // Valores originales del provider para control de cambios
  late double _originalLeadTime;
  late double _originalEspacioMaximo;
  late double _originalPresupuestoMaximo;
  late double _originalNumeroMaximoPedidos;
  late String _originalTipoRedondeoPuntoReorden;
  late String _originalTipoRedondeoTamanoLote;
  late int _originalDecimalesPuntoReorden;
  late int _originalDecimalesTamanoLote;
  late bool _originalRedondeosVinculados;
  late String _originalFormatoSeparadores;

  // Referencia persistente al provider para el dispose
  late InventarioProvider _provider;

  @override
  void initState() {
    super.initState();
    final provider = context.read<InventarioProvider>();
    _provider = provider;

    // Guardar valores originales
    _originalLeadTime = MathUtils.redondearInteligente(provider.leadTimeDias, tipo: 'dias');
    _originalEspacioMaximo = MathUtils.redondearInteligente(provider.espacioMaximo, tipo: 'espacio');
    _originalPresupuestoMaximo = MathUtils.redondearInteligente(provider.presupuestoMaximo, tipo: 'moneda');
    _originalNumeroMaximoPedidos = MathUtils.redondearInteligente(provider.numeroMaximoPedidos, tipo: 'pedidos');
    _originalTipoRedondeoPuntoReorden = provider.tipoRedondeoPuntoReorden;
    _originalTipoRedondeoTamanoLote = provider.tipoRedondeoTamanoLote;
    _originalDecimalesPuntoReorden = provider.decimalesPuntoReorden;
    _originalDecimalesTamanoLote = provider.decimalesTamanoLote;
    _originalRedondeosVinculados = provider.redondeosVinculados;
    _originalFormatoSeparadores = provider.formatoSeparadores;

    // Usar valores redondeados para mejor presentación y aplicar formato regional
    _leadTimeController = TextEditingController(
        text: MathUtils.formatearConDecimales(_originalLeadTime, 1));
    _espacioMaximoController = TextEditingController(
        text: MathUtils.formatearConDecimales(_originalEspacioMaximo, 1));
    _presupuestoMaximoController = TextEditingController(
        text: MathUtils.formatearConDecimales(_originalPresupuestoMaximo, 2));
    _numeroMaximoPedidosController = TextEditingController(
        text: MathUtils.formatearConDecimales(_originalNumeroMaximoPedidos, 0));

    // Inicializar configuraciones de redondeo
    _tipoRedondeoPuntoReorden = _originalTipoRedondeoPuntoReorden;
    _tipoRedondeoTamanoLote = _originalTipoRedondeoTamanoLote;
    _decimalesPuntoReorden = _originalDecimalesPuntoReorden;
    _decimalesTamanoLote = _originalDecimalesTamanoLote;
    _redondeosVinculados = _originalRedondeosVinculados;
    _formatoSeparadores = _originalFormatoSeparadores;

    // Registrar listeners para refrescar el estado del boton guardar
    _leadTimeController.addListener(_onFieldChanged);
    _espacioMaximoController.addListener(_onFieldChanged);
    _presupuestoMaximoController.addListener(_onFieldChanged);
    _numeroMaximoPedidosController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  bool _tieneCambios() {
    final currentLeadTime = MathUtils.validarYRedondearEntrada(
        _leadTimeController.text,
        tipo: 'dias',
        valorPorDefecto: _originalLeadTime);
    final currentEspacio = MathUtils.validarYRedondearEntrada(
        _espacioMaximoController.text,
        tipo: 'espacio',
        valorPorDefecto: _originalEspacioMaximo);
    final currentPresupuesto = MathUtils.validarYRedondearEntrada(
        _presupuestoMaximoController.text,
        tipo: 'moneda',
        valorPorDefecto: _originalPresupuestoMaximo);
    final currentPedidos = MathUtils.validarYRedondearEntrada(
        _numeroMaximoPedidosController.text,
        tipo: 'pedidos',
        valorPorDefecto: _originalNumeroMaximoPedidos);

    final hasTextChanges = currentLeadTime != _originalLeadTime ||
        currentEspacio != _originalEspacioMaximo ||
        currentPresupuesto != _originalPresupuestoMaximo ||
        currentPedidos != _originalNumeroMaximoPedidos;

    final hasConfigChanges =
        _tipoRedondeoPuntoReorden != _originalTipoRedondeoPuntoReorden ||
            _tipoRedondeoTamanoLote != _originalTipoRedondeoTamanoLote ||
            _decimalesPuntoReorden != _originalDecimalesPuntoReorden ||
            _decimalesTamanoLote != _originalDecimalesTamanoLote ||
            _redondeosVinculados != _originalRedondeosVinculados ||
            _formatoSeparadores != _originalFormatoSeparadores;

    return hasTextChanges || hasConfigChanges;
  }

  @override
  void dispose() {
    // Asegurar que el formato de MathUtils quede sincronizado con el provider al cerrar el diálogo
    MathUtils.formatoNumeroUI = _provider.formatoSeparadores;

    _leadTimeController.removeListener(_onFieldChanged);
    _espacioMaximoController.removeListener(_onFieldChanged);
    _presupuestoMaximoController.removeListener(_onFieldChanged);
    _numeroMaximoPedidosController.removeListener(_onFieldChanged);

    _leadTimeController.dispose();
    _espacioMaximoController.dispose();
    _presupuestoMaximoController.dispose();
    _numeroMaximoPedidosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<InventarioProvider>();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header del diálogo
                Row(
                  children: [
                    const Icon(UniconsLine.setting, color: MDSJColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Configurar Restricciones',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Contenido del diálogo en 2 columnas
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // COLUMNA IZQUIERDA: Configuraciones principales
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildConfigField(
                            'Lead Time (días)',
                            _leadTimeController,
                            (value) => setState(() {}),
                            icon: UniconsLine.clock,
                            tooltip: 'Tiempo promedio de entrega de pedidos',
                          ),
                          const SizedBox(height: 20),
                          _buildConfigField(
                            'Espacio Máximo (m²)',
                            _espacioMaximoController,
                            (value) => setState(() {}),
                            icon: UniconsLine.store,
                            tooltip: 'Capacidad máxima de almacenamiento',
                          ),
                          const SizedBox(height: 20),
                          _buildConfigField(
                            'Presupuesto Máximo (S/)',
                            _presupuestoMaximoController,
                            (value) => setState(() {}),
                            icon: UniconsLine.money_bill,
                            tooltip: 'Límite de presupuesto para el inventario',
                          ),
                          const SizedBox(height: 20),
                          _buildConfigField(
                            'Número Máximo de Pedidos',
                            _numeroMaximoPedidosController,
                            (value) => setState(() {}),
                            icon: UniconsLine.box,
                            tooltip: 'Cantidad máxima de pedidos permitidos',
                            allowDecimal: false,
                          ),
                        ],
                      ),
                    ),

                    // SEPARADOR VERTICAL
                    Container(
                      width: 1,
                      height: 220,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),

                    // COLUMNA DERECHA: Configuraciones de redondeo
                    Expanded(
                      child: _buildRedondeoSection(),
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
                      child: Text(
                        'Cancelar',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _tieneCambios()
                          ? () {
                              // ✅ Validar y formatear inputs antes de guardar
                              final leadTimeVal = MathUtils.validarYRedondearEntrada(
                                  _leadTimeController.text,
                                  tipo: 'dias',
                                  valorPorDefecto: 36.5);
                              final espacioMaxVal = MathUtils.validarYRedondearEntrada(
                                  _espacioMaximoController.text,
                                  tipo: 'espacio',
                                  valorPorDefecto: 150.0);
                              final presupuestoMaxVal = MathUtils.validarYRedondearEntrada(
                                  _presupuestoMaximoController.text,
                                  tipo: 'moneda',
                                  valorPorDefecto: 10000.0);
                              final numeroMaxPedidosVal = MathUtils.validarYRedondearEntrada(
                                  _numeroMaximoPedidosController.text,
                                  tipo: 'pedidos',
                                  valorPorDefecto: 100.0);

                              // ✅ Guardar configuraciones y enviar al provider
                              provider.actualizarConfiguracion(
                                leadTimeDias: leadTimeVal,
                                espacioMaximo: espacioMaxVal,
                                presupuestoMaximo: presupuestoMaxVal,
                                numeroMaximoPedidos: numeroMaxPedidosVal,
                                tipoRedondeoPuntoReorden: _tipoRedondeoPuntoReorden,
                                tipoRedondeoTamanoLote: _tipoRedondeoTamanoLote,
                                decimalesPuntoReorden: _decimalesPuntoReorden,
                                decimalesTamanoLote: _decimalesTamanoLote,
                                redondeosVinculados: _redondeosVinculados,
                                formatoSeparadores: _formatoSeparadores,
                              );

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(UniconsLine.check_circle,
                                          color: Colors.white, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Configuración guardada',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: MDSJColors.primary,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(milliseconds: 1500),
                                  width: 240,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              );
                            }
                          : null, // Desactivado si no hay cambios
                      child: Text(
                        'Guardar',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
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

  Widget _buildConfigField(
    String label,
    TextEditingController controller,
    Function(String) onChanged, {
    IconData? icon,
    String? tooltip,
    bool allowDecimal = true,
  }) {
    final focusNode = FocusNode();

    // Seleccionar todo el texto al obtener el foco
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        controller.selection =
            TextSelection(baseOffset: 0, extentOffset: controller.text.length);
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
              Tooltip(
                message: tooltip,
                preferBelow: false,
                triggerMode: TooltipTriggerMode.tap,
                child: const Icon(UniconsLine.info_circle,
                    size: 14, color: MDSJColors.textSecondary),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: MathUtils.getInputFormatters(allowDecimal: allowDecimal),
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

  /// Construye la sección de configuraciones de redondeo
  Widget _buildRedondeoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de la sección
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: MDSJColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(UniconsLine.calculator,
                  size: 18, color: MDSJColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Configuración de Redondeo',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: MDSJColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Botón de vinculación
        _buildVinculacionButton(),

        const SizedBox(height: 20),

        // Configuración de Punto de Reorden
        _buildRedondeoField(
          'Punto de Reorden',
          _tipoRedondeoPuntoReorden,
          _decimalesPuntoReorden,
          (tipo, decimales) {
            setState(() {
              _tipoRedondeoPuntoReorden = tipo;
              _decimalesPuntoReorden = decimales;

              // Si están vinculados, actualizar también el tamaño de lote
              if (_redondeosVinculados) {
                _tipoRedondeoTamanoLote = tipo;
                _decimalesTamanoLote = decimales;
              }
            });
          },
        ),

        const SizedBox(height: 20),

        // Configuración de Tamaño de Lote
        _buildRedondeoField(
          'Tamaño de Lote',
          _tipoRedondeoTamanoLote,
          _decimalesTamanoLote,
          (tipo, decimales) {
            setState(() {
              _tipoRedondeoTamanoLote = tipo;
              _decimalesTamanoLote = decimales;

              // Si están vinculados, actualizar también el punto de reorden
              if (_redondeosVinculados) {
                _tipoRedondeoPuntoReorden = tipo;
                _decimalesPuntoReorden = decimales;
              }
            });
          },
        ),
        const SizedBox(height: 20),
        _buildSeparadoresSelector(),
      ],
    );
  }

  /// Construye el selector del formato de separador de miles
  Widget _buildSeparadoresSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Separador de Miles',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: MDSJColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSeparadorOption(
                '1.250,00',
                'punto_coma',
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildSeparadorOption(
                '1,250.00',
                'coma_punto',
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildSeparadorOption(
                '1\'250.00',
                'comilla_punto',
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _actualizarFormatoControladores(String nuevoFormato) {
    final provider = context.read<InventarioProvider>();
    
    // 1. Obtener los valores numéricos actuales de los inputs
    final leadTimeVal = MathUtils.parseDouble(_leadTimeController.text) ?? provider.leadTimeDias;
    final espacioMaxVal = MathUtils.parseDouble(_espacioMaximoController.text) ?? provider.espacioMaximo;
    final presupuestoMaxVal = MathUtils.parseDouble(_presupuestoMaximoController.text) ?? provider.presupuestoMaximo;
    final numeroMaxPedidosVal = MathUtils.parseDouble(_numeroMaximoPedidosController.text) ?? provider.numeroMaximoPedidos;

    // 2. Cambiar la configuración global temporalmente
    MathUtils.formatoNumeroUI = nuevoFormato;

    // 3. Re-formatear y asignar a los controladores
    _leadTimeController.text = MathUtils.formatearConDecimales(leadTimeVal, 1);
    _espacioMaximoController.text = MathUtils.formatearConDecimales(espacioMaxVal, 1);
    _presupuestoMaximoController.text = MathUtils.formatearConDecimales(presupuestoMaxVal, 2);
    _numeroMaximoPedidosController.text = MathUtils.formatearConDecimales(numeroMaxPedidosVal, 0);
  }

  /// Construye una opción de separador de miles
  Widget _buildSeparadorOption(String label, String value) {
    final isSelected = _formatoSeparadores == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _formatoSeparadores = value;
          _actualizarFormatoControladores(value);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? MDSJColors.primary
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? MDSJColors.primary
                : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : MDSJColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Construye un campo de configuración de redondeo
  Widget _buildRedondeoField(
    String label,
    String tipoActual,
    int decimalesActual,
    Function(String tipo, int decimales) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: MDSJColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        // Selector de tipo de redondeo
        Row(
          children: [
            Expanded(
              child: _buildRedondeoOption(
                'Números Enteros',
                'unidades',
                tipoActual,
                () => onChanged('unidades', 0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRedondeoOption(
                'Con Decimales',
                'decimales',
                tipoActual,
                () => onChanged('decimales', decimalesActual),
              ),
            ),
          ],
        ),

        // Selector de decimales (solo si está en modo decimales)
        if (tipoActual == 'decimales') ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Decimales: ',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: MDSJColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) {
                    final decimales = index;
                    return Flexible(
                      child: _buildDecimalOption(
                        decimales.toString(),
                        decimales,
                        decimalesActual,
                        () => onChanged('decimales', decimales),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Construye una opción de redondeo
  Widget _buildRedondeoOption(
      String label, String value, String selected, VoidCallback onTap) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? MDSJColors.primary
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? MDSJColors.primary
                : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : MDSJColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Construye una opción de decimales
  Widget _buildDecimalOption(
      String label, int value, int selected, VoidCallback onTap) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 28, maxWidth: 36),
        height: 28,
        decoration: BoxDecoration(
          color: isSelected
              ? MDSJColors.primary
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? MDSJColors.primary
                : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : MDSJColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  /// Construye el botón de vinculación
  Widget _buildVinculacionButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _redondeosVinculados
            ? MDSJColors.primary.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _redondeosVinculados
              ? MDSJColors.primary
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _redondeosVinculados ? UniconsLine.link : UniconsLine.link_broken,
            size: 16,
            color: _redondeosVinculados ? MDSJColors.primary : Colors.grey,
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _redondeosVinculados = !_redondeosVinculados;
              });
            },
            child: Text(
              _redondeosVinculados
                  ? 'Redondeos Vinculados'
                  : 'Redondeos Independientes',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _redondeosVinculados ? MDSJColors.primary : Colors.grey,
              ),
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
