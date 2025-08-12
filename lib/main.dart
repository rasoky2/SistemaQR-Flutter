import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inventario_qr/providers/inventario.provider.dart';
import 'package:inventario_qr/screens/home_screen.dart';
import 'package:inventario_qr/screens/ingresar_datos_screen.dart';
import 'package:inventario_qr/screens/resultados_screen.dart';
import 'package:inventario_qr/utils/page_transitions.dart';
import 'package:inventario_qr/utils/theme_colors.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => InventarioProvider(),
      child: MaterialApp(
        title: 'Sistema de Inventario MDSJ',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // Paleta de colores basada en el diseño MDSJ
          primaryColor: MDSJColors.primary,
          colorScheme: ColorScheme.fromSeed(
            seedColor: MDSJColors.primary,
            primary: MDSJColors.primary,
            secondary: MDSJColors.secondary,
            surface: MDSJColors.surface,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: MDSJColors.textPrimary,
          ),
          
          // Tipografía Poppins
          textTheme: GoogleFonts.poppinsTextTheme(
            Theme.of(context).textTheme,
          ),
          
          // Configuración de componentes Material
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: MDSJColors.primary,
              foregroundColor: Colors.white,
              textStyle: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: MDSJColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: MDSJColors.border),
            ),
            focusedBorder: const OutlineInputBorder(
            ),
            hintStyle: GoogleFonts.poppins(
              color: MDSJColors.textSecondary,
              fontSize: 14,
            ),
            labelStyle: GoogleFonts.poppins(
              color: MDSJColors.textPrimary,
              fontSize: 14,
            ),
          ),
          
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
          ),
          
          appBarTheme: AppBarTheme(
            backgroundColor: MDSJColors.primary,
            foregroundColor: Colors.white,
            titleTextStyle: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            elevation: 0,
          ),
        ),
        home: const HomeScreen(),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/ingresar-datos':
              return SlideLeftRoute(page: const IngresarDatosScreen());
            case '/resultados':
              return SlideLeftRoute(page: const ResultadosScreen());
            default:
              return null;
          }
        },
      ),
    );
  }
}
