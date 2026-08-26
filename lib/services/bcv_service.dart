import 'dart:convert';
import 'package:http/http.dart' as http;

/// Resultado de la consulta de la tasa del BCV
class BcvRateResult {
  final double rate;
  final String date;
  final bool isSuccess;
  final String? errorMessage;

  const BcvRateResult({
    required this.rate,
    required this.date,
    required this.isSuccess,
    this.errorMessage,
  });
}

/// Servicio para consultar la tasa oficial del Banco Central de Venezuela (BCV)
class BcvService {
  // API pública y confiable de la tasa oficial del BCV (DolarApi Venezuela)
  static const String _primaryApiUrl = 'https://ve.dolarapi.com/v1/dolares/oficial';
  static const String _fallbackApiUrl = 'https://pydolarvenezuela-api.vercel.app/api/v1/dollar?page=bcv';

  /// Obtiene la tasa oficial del BCV en tiempo real mediante HTTP
  /// (Equivalente a fetch() / axios en React o HttpClient en Java)
  static Future<BcvRateResult> fetchOfficialRate() async {
    try {
      // 1. Intento con la API principal
      final response = await http
          .get(Uri.parse(_primaryApiUrl))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        
        // En DolarApi el campo se llama 'promedio' o 'precio'
        final double rate = (data['promedio'] ?? data['precio'] as num).toDouble();
        final String date = data['fechaActualizacion']?.toString() ?? 'Hoy';

        return BcvRateResult(
          rate: rate,
          date: _formatDate(date),
          isSuccess: true,
        );
      }
    } catch (_) {
      // Si falla la principal, intentamos con la secundaria
    }

    try {
      // 2. Intento de respaldo (Fallback)
      final response = await http
          .get(Uri.parse(_fallbackApiUrl))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final monitors = data['monitors'] as Map<String, dynamic>?;
        final usd = monitors?['usd'] as Map<String, dynamic>?;
        final double rate = (usd?['price'] as num).toDouble();
        final String date = usd?['last_update']?.toString() ?? 'Hoy';

        return BcvRateResult(
          rate: rate,
          date: date,
          isSuccess: true,
        );
      }
    } catch (e) {
      return BcvRateResult(
        rate: 36.50, // Tasa de respaldo offline
        date: 'Sin conexión',
        isSuccess: false,
        errorMessage: 'No se pudo conectar con el BCV: $e',
      );
    }

    return const BcvRateResult(
      rate: 36.50,
      date: 'Sin conexión',
      isSuccess: false,
      errorMessage: 'Error en la respuesta del servidor',
    );
  }

  static String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }
}
