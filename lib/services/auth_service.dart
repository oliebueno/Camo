import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para gestionar la contraseña y seguridad del panel de administración
class AuthService {
  static const String _adminPasswordKey = 'camo_admin_password';
  static const String _defaultPassword = '1234'; // Contraseña inicial por defecto

  /// Obtiene la contraseña actual de administración
  static Future<String> getAdminPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_adminPasswordKey) ?? _defaultPassword;
  }

  /// Verifica si la contraseña ingresada es correcta
  static Future<bool> verifyPassword(String input) async {
    final currentPassword = await getAdminPassword();
    return input.trim() == currentPassword.trim();
  }

  /// Cambia la contraseña de administración
  static Future<void> changeAdminPassword(String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminPasswordKey, newPassword.trim());
  }
}
