import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

// Web: use 127.0.0.1 (localhost can fail in some browsers due to CORS quirks)
// Mobile/device: use your machine's LAN IP
String get _baseUrl => 'https://krishisetu.api.serverpod.space';

class SensorData {
  final double temperature;
  final double humidity;
  final double soilPercent;
  final double ldrRaw;
  final double ph;
  final bool waterLevel;
  final bool relay;
  final bool autoMode;

  const SensorData({
    required this.temperature,
    required this.humidity,
    required this.soilPercent,
    required this.ldrRaw,
    required this.ph,
    required this.waterLevel,
    required this.relay,
    required this.autoMode,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: _toDouble(json['temperature']),
      humidity:    _toDouble(json['humidity']),
      soilPercent: _toDouble(json['soilPercent']),
      ldrRaw:      _toDouble(json['ldrRaw']),
      ph:          _toDouble(json['ph']),
      // ESP32 may send booleans as true/false OR as 1/0 integers
      waterLevel:  _toBool(json['waterLevel']),
      relay:       _toBool(json['relay']),
      autoMode:    _toBool(json['autoMode']),
    );
  }

  /// Safely convert num → double regardless of whether JSON gives int or double
  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    return (v as num).toDouble();
  }

  /// Safely convert bool OR int (0/1) → bool
  static bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return false;
  }
}

class SensorService {
  static const _timeout = Duration(seconds: 5);
  static bool _simulatedPump = false;

  static Future<SensorData> fetchData() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/api/data'))
          .timeout(_timeout);

      if (res.statusCode == 200) {
        return SensorData.fromJson(jsonDecode(res.body));
      }
      return _fallbackData();
    } catch (e) {
      // Fallback sensor demo values for live web preview
      return _fallbackData();
    }
  }

  static SensorData _fallbackData() {
    return SensorData(
      temperature: 28.4,
      humidity: 65.0,
      soilPercent: 54.0,
      ldrRaw: 720.0,
      ph: 6.8,
      waterLevel: true,
      relay: _simulatedPump,
      autoMode: true,
    );
  }

  static Future<void> pumpOn() async {
    _simulatedPump = true;
    try {
      await http.get(Uri.parse('$_baseUrl/api/on')).timeout(_timeout);
    } catch (_) {}
  }

  static Future<void> pumpOff() async {
    _simulatedPump = false;
    try {
      await http.get(Uri.parse('$_baseUrl/api/off')).timeout(_timeout);
    } catch (_) {}
  }
}

class DeviceOfflineException implements Exception {
  @override
  String toString() => 'Device not connected';
}
