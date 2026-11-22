import 'package:flutter/foundation.dart';

enum TelemetrySource { live, demo }

@immutable
class SensorTelemetry {
  final double temperature;
  final double humidity;
  final double soilMoisture;
  final double sunlight;
  final double soilPH;
  final bool waterLevel;
  final bool pumpStatus;
  final bool autoMode;
  final DateTime timestamp;
  final String deviceId;
  final TelemetrySource source;

  const SensorTelemetry({
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.sunlight,
    required this.soilPH,
    required this.waterLevel,
    required this.pumpStatus,
    required this.autoMode,
    required this.timestamp,
    this.deviceId = 'ESP32-KRISHISETU-01',
    required this.source,
  });

  bool get isLive => source == TelemetrySource.live;
  bool get isDemo => source == TelemetrySource.demo;

  /// Deterministic realistic baseline demonstration readings (Illustrative)
  factory SensorTelemetry.demo({bool pumpStatus = false}) {
    return SensorTelemetry(
      temperature: 28.5,
      humidity: 67.0,
      soilMoisture: 42.0,
      sunlight: 12500.0,
      soilPH: 6.5,
      waterLevel: true, // 78% adequate tank level
      pumpStatus: pumpStatus,
      autoMode: true,
      timestamp: DateTime.now(),
      deviceId: 'DEMO-SIMULATOR',
      source: TelemetrySource.demo,
    );
  }

  factory SensorTelemetry.fromLiveJson(Map<String, dynamic> json) {
    return SensorTelemetry(
      temperature: _toDouble(json['temperature'], 28.5),
      humidity: _toDouble(json['humidity'], 67.0),
      soilMoisture: _toDouble(json['soilPercent'] ?? json['soilMoisture'], 42.0),
      sunlight: _toDouble(json['ldrRaw'] ?? json['sunlight'], 12500.0),
      soilPH: _toDouble(json['ph'] ?? json['soilPH'], 6.5),
      waterLevel: _toBool(json['waterLevel']),
      pumpStatus: _toBool(json['relay'] ?? json['pumpStatus']),
      autoMode: _toBool(json['autoMode']),
      timestamp: DateTime.now(),
      deviceId: json['deviceId']?.toString() ?? 'ESP32-KRISHISETU-01',
      source: TelemetrySource.live,
    );
  }

  SensorTelemetry copyWith({
    double? temperature,
    double? humidity,
    double? soilMoisture,
    double? sunlight,
    double? soilPH,
    bool? waterLevel,
    bool? pumpStatus,
    bool? autoMode,
    DateTime? timestamp,
    String? deviceId,
    TelemetrySource? source,
  }) {
    return SensorTelemetry(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      soilMoisture: soilMoisture ?? this.soilMoisture,
      sunlight: sunlight ?? this.sunlight,
      soilPH: soilPH ?? this.soilPH,
      waterLevel: waterLevel ?? this.waterLevel,
      pumpStatus: pumpStatus ?? this.pumpStatus,
      autoMode: autoMode ?? this.autoMode,
      timestamp: timestamp ?? this.timestamp,
      deviceId: deviceId ?? this.deviceId,
      source: source ?? this.source,
    );
  }

  static double _toDouble(dynamic v, double fallback) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  static bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return false;
  }
}
