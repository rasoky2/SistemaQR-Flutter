import 'package:fluent_ui/fluent_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inventario_qr/providers/inventario.provider.dart';
import 'package:inventario_qr/screens/home_screen.dart';
import 'package:inventario_qr/screens/ingresar_datos_screen.dart';
import 'package:inventario_qr/screens/resultados_screen.dart';
import 'package:provider/provider.dart';

void main() {
  // Configurar ClearType para mejor renderizado de fuentes en Windows
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const InventarioApp());
}

class InventarioApp extends StatelessWidget {
  const InventarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => InventarioProvider(),
      child: FluentApp(
        title: 'Sistema QR de Inventario',
        debugShowCheckedModeBanner: false,
        theme: FluentThemeData(
          brightness: Brightness.light,
          accentColor: Colors.blue,
          scaffoldBackgroundColor: Colors.grey[50],
          typography: Typography.raw(
            titleLarge: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
            bodyLarge: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        home: const HomeScreen(),
        routes: {
          '/resultados': (context) => const ResultadosScreen(),
          '/ingresar-datos': (context) => const IngresarDatosScreen(),
        },
      ),
    );
  }
}
