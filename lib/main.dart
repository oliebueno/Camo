import 'package:flutter/material.dart';
import 'screens/catalog_screen.dart';
import 'services/supabase_service.dart';

void main() async {
  // Asegura la inicialización de los bindings de Flutter para llamadas asíncronas
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa la conexión con Supabase
  try {
    await SupabaseService.initialize();
  } catch (e) {
    // Si falla (ej. sin internet al primer arranque), la app sigue funcionando con cache
  }

  runApp(const CamoPreciosApp());
}

/// Widget raíz de la aplicación
class CamoPreciosApp extends StatelessWidget {
  const CamoPreciosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camo Precios',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
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
      themeMode: ThemeMode.system,
      home: const CatalogScreen(),
    );
  }
}
