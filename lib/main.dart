import 'package:flutter/material.dart';
import 'screens/catalog_screen.dart';

void main() {
  runApp(const CamoPreciosApp());
}

/// Widget raíz de la aplicación
/// Configura el tema visual (Material 3), colores y la pantalla inicial
class CamoPreciosApp extends StatelessWidget {
  const CamoPreciosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camo Precios',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Color primario elegante en tono azul ultramar / índigo para apps comerciales
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E56A0),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E56A0),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      themeMode: ThemeMode.system, // Se adapta al modo oscuro/claro del teléfono
      home: const CatalogScreen(),
    );
  }
}
