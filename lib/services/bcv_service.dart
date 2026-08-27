import 'dart:convert';
import 'package:http/http.dart' as http;

/// Resultado de la consulta de la tasa del BCV
class BcvRateResult {
  final double rate;
  final String date;
  final bool isSuccess;
  final String? source;
  final String? errorMessage;

  const BcvRateResult({
    required this.rate,
    required this.date,
    required this.isSuccess,
    this.source,
    this.errorMessage,
  });
}

/// Servicio de alta precisión para consultar la tasa oficial del BCV en tiempo real
class BcvService {
  // 1. API en tiempo real que captura la tasa inmediatamente cuando el BCV publica en la tarde (~4:30 PM - 5:30 PM)
  static const String _realtimeBcvApi = 'https://rates.dolarvzla.com/bcv/current.json';

  // 2. API de respaldo (DolarApi)
  static const String _backupBcvApi = 'https://ve.dolarapi.com/v1/dolares/oficial';

  /// Obtiene la tasa oficial del BCV en tiempo real con fallback inteligente
  static Future<BcvRateResult> fetchOfficialRate() async {
    // 1. Primer intento: API en tiempo real (actualización inmediata al publicarse en la tarde)
    try {
      final response = await http
          .get(Uri.parse(_realtimeBcvApi))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final current = data['current'] as Map<String, dynamic>?;

        if (current != null && current['usd'] != null) {
          final double rate = (current['usd'] as num).toDouble();
          final String dateStr = current['date']?.toString() ?? 'Hoy';

          if (rate > 0) {
            return BcvRateResult(
              rate: rate,
              date: _formatDate(dateStr),
              isSuccess: true,
              source: 'BCV Oficial (En vivo)',
            );
          }
        }
      }
    } catch (_) {
      // Fallback si la primera API no responde
    }

    // 2. Segundo intento: DolarApi Venezuela
    try {
      final response = await http
          .get(Uri.parse(_backupBcvApi))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final double rate = (data['promedio'] ?? data['precio'] as num).toDouble();
        final String date = data['fechaActualizacion']?.toString() ?? 'Hoy';

        if (rate > 0) {
          return BcvRateResult(
            rate: rate,
            date: _formatDate(date),
            isSuccess: true,
            source: 'BCV DolarApi',
          );
        }
      }
    } catch (_) {
      // Fallback a tasa de seguridad
    }

    return const BcvRateResult(
      rate: 36.50,
      date: 'Sin conexión',
      isSuccess: false,
      errorMessage: 'No se pudo conectar a los servidores del BCV',
    );
  }

  static String _formatDate(String dateStr) {
    try {
      // Formato YYYY-MM-DD o ISO
      final cleanDate = dateStr.contains('T') ? dateStr.split('T').first : dateStr;
      final parts = cleanDate.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
      return dateStr;
    } catch (_) {
      return dateStr;
    }
  }
}
