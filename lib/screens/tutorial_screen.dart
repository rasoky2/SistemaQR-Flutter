import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inventario_qr/utils/theme_colors.dart';
import 'package:unicons/unicons.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayuda y Tutorial'),
        leading: IconButton(
          icon: const Icon(UniconsLine.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('¿Qué datos debo ingresar?'),
            _infoCard(children: const [
              _Bullet('Nombre del Artículo: identificación libre.'),
              _Bullet('Demanda Anual (D): unidades requeridas por año.'),
              _Bullet('Costo por Pedido (S): costo fijo por cada pedido.'),
              _Bullet('Costo Mantenimiento (H): costo anual por unidad almacenada.'),
              _Bullet('Costo por Faltante (opcional): costo por unidad no atendida.'),
              _Bullet('Costo Unitario: precio por unidad del artículo.'),
              _Bullet('Espacio por Unidad (m²): área ocupada por cada unidad.'),
              _Bullet('Desviación Estándar Diaria (σd): variabilidad de la demanda diaria.'),
              _Bullet('Punto de Reorden (R): nivel de inventario a partir del cual se emite un pedido.'),
              _Bullet('Tamaño de Lote (Q): cantidad de unidades por pedido.'),
            ]),

            const SizedBox(height: 24),
            _sectionTitle('Fórmulas usadas (Modelo EOQ y Punto de Reorden)'),
            _infoCard(children: [
              const _Formula('Tamaño de lote óptimo (EOQ):', r"Q^* = \sqrt{\frac{2\,D\,S}{H}}"),
              const SizedBox(height: 8),
              const _Formula('Demanda diaria promedio (d):', r"d = \frac{D}{365}"),
              const _Formula('Desviación durante el lead time (σL):', r"\sigma_L = \sigma_d\,\sqrt{L}"),
              const _Formula('Punto de reorden (R):', r"R = d\,L + z\,\sigma_L"),
              const SizedBox(height: 8),
              const _Plain('Donde:'),
              const _Bullet('D: demanda anual (unidades/año).'),
              const _Bullet('S: costo por pedido.'),
              const _Bullet('H: costo anual de mantenimiento por unidad.'),
              const _Bullet('L: lead time (días) configurado en Restricciones.'),
              const _Bullet('σd: desviación estándar diaria.'),
              const _Bullet('z: factor de servicio (derivado del nivel de servicio objetivo).'),
            ]),

            const SizedBox(height: 24),
            _sectionTitle('Componentes de costo (política Q,R con backorders)'),
            _infoCard(children: const [
              _Formula('Inventario promedio anual:', r"\bar{I} = \frac{Q}{2} + \max(0, R - \mu_L) - E[BO]"),
              SizedBox(height: 8),
              _Formula('Costo de mantenimiento anual:', r"C_h = H \cdot \bar{I}"),
              _Formula('Costo de faltante anual:', r"C_p = p \cdot \frac{D}{Q} \cdot E[BO]"),
              _Formula('Costo de pedidos anual:', r"C_K = \frac{D}{Q} \cdot S"),
              SizedBox(height: 8),
              _Formula('Costo total anual:', r"C = C_K + C_h + C_p"),
              SizedBox(height: 8),
              _Plain('Notas:'),
              _Bullet('μL: demanda esperada durante el lead time (μL = D · L/365).'),
              _Bullet('E[BO]: backorders esperados (usando la función de pérdida normal estándar).'),
            ]),

            const SizedBox(height: 24),
            _sectionTitle('Restricciones del sistema'),
            _infoCard(children: const [
              _Bullet('Espacio Máximo (m²): límite disponible en almacén.'),
              _Bullet('Presupuesto Máximo: límite de inversión total.'),
              _Bullet('Número Máximo de Pedidos: tope anual de órdenes.'),
              _Bullet('Lead Time (días): tiempo promedio de reposición.'),
            ]),

            const SizedBox(height: 24),
            _sectionTitle('Información del programa'),
            _infoCard(children: [
              _versionInfo(),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: MDSJColors.textPrimary,
        ),
      ),
    );
  }

  Widget _infoCard({required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _versionInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Plain('Versión actual:'),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              UniconsLine.info_circle,
              color: MDSJColors.textSecondary,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'v1.0.2',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: MDSJColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Sistema de inventario multi-artículo bajo modelo QR con restricciones',
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: MDSJColors.textSecondary.withValues(alpha: 0.7),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final sepIndex = text.indexOf(':');
    final hasPrefix = sepIndex > 0; // hay prefijo antes de ':'
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14, height: 1.4)),
          Expanded(
            child: hasPrefix
                ? RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(fontSize: 14, height: 1.4, color: MDSJColors.textPrimary),
                      children: [
                        TextSpan(
                          text: '${text.substring(0, sepIndex + 1)} ',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: text.substring(sepIndex + 2)),
                      ],
                    ),
                  )
                : Text(
                    text,
                    style: GoogleFonts.poppins(fontSize: 14, height: 1.4),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('text', text));
  }
}
class _Plain extends StatelessWidget {
  const _Plain(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(fontSize: 14),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('text', text));
  }
}

class _Formula extends StatelessWidget {
  const _Formula(this.label, this.latex);
  final String label;
  final String latex;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: MDSJColors.infoBorder),
          ),
          child: Math.tex(
            latex,
            textStyle: GoogleFonts.poppins(fontSize: 20, color: MDSJColors.textPrimary),
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(StringProperty('label', label))
    ..add(StringProperty('latex', latex));
  }
}


