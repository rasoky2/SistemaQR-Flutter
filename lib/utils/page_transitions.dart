import 'package:flutter/material.dart';

/// Animación de transición con efecto slider hacia la derecha
class SlideRightRoute extends PageRouteBuilder {
  final Widget page;
  
  SlideRightRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(-1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            
            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            
            var offsetAnimation = animation.drive(tween);
            
            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
}

/// Animación de transición con efecto slider hacia la izquierda
class SlideLeftRoute extends PageRouteBuilder {
  final Widget page;
  
  SlideLeftRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            
            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            
            var offsetAnimation = animation.drive(tween);
            
            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
}

/// Animación de transición con efecto fade y slide
class FadeSlideRoute extends PageRouteBuilder {
  final Widget page;
  
  FadeSlideRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 0.3);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;
            
            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            
            var offsetAnimation = animation.drive(tween);
            var fadeAnimation = animation.drive(
              Tween(begin: 0.0, end: 1.0).chain(
                CurveTween(curve: curve),
              ),
            );
            
            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: offsetAnimation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        );
}

/// Animación de transición con efecto scale y fade
class ScaleFadeRoute extends PageRouteBuilder {
  final Widget page;
  
  ScaleFadeRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = 0.8;
            const end = 1.0;
            const curve = Curves.easeOutCubic;
            
            var scaleAnimation = animation.drive(
              Tween(begin: begin, end: end).chain(
                CurveTween(curve: curve),
              ),
            );
            
            var fadeAnimation = animation.drive(
              Tween(begin: 0.0, end: 1.0).chain(
                CurveTween(curve: curve),
              ),
            );
            
            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
}

/// Animación de transición con efecto slide desde abajo
class SlideUpRoute extends PageRouteBuilder {
  final Widget page;
  
  SlideUpRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;
            
            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            
            var offsetAnimation = animation.drive(tween);
            
            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
}

/// Helper para navegación con animaciones personalizadas
class NavigationHelper {
  /// Navegar a una nueva pantalla con animación slide hacia la derecha
  static Future<T?> pushSlideRight<T extends Object?>(
    BuildContext context,
    Widget page,
  ) {
    return Navigator.push<T>(
      context,
      SlideRightRoute(page: page) as Route<T>,
    );
  }
  
  /// Navegar a una nueva pantalla con animación slide hacia la izquierda
  static Future<T?> pushSlideLeft<T extends Object?>(
    BuildContext context,
    Widget page,
  ) {
    return Navigator.push<T>(
      context,
      SlideLeftRoute(page: page) as Route<T>,
    );
  }
  
  /// Navegar a una nueva pantalla con animación fade y slide
  static Future<T?> pushFadeSlide<T extends Object?>(
    BuildContext context,
    Widget page,
  ) {
    return Navigator.push<T>(
      context,
      FadeSlideRoute(page: page) as Route<T>,
    );
  }
  
  /// Navegar a una nueva pantalla con animación scale y fade
  static Future<T?> pushScaleFade<T extends Object?>(
    BuildContext context,
    Widget page,
  ) {
    return Navigator.push<T>(
      context,
      ScaleFadeRoute(page: page) as Route<T>,
    );
  }
  
  /// Navegar a una nueva pantalla con animación slide desde abajo
  static Future<T?> pushSlideUp<T extends Object?>(
    BuildContext context,
    Widget page,
  ) {
    return Navigator.push<T>(
      context,
      SlideUpRoute(page: page) as Route<T>,
    );
  }
} 