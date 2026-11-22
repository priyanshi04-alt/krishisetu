import '../models/sensor_telemetry.dart';
import 'sensor_repository.dart';

class SensorData {
  final double temperature;
  final double humidity;
  final double soilPercent;
  final double ldrRaw;
  final double ph;
  final bool waterLevel;
  final bool relay;
  final bool autoMode;
  final bool isLive;
  final DateTime timestamp;

  const SensorData({
    required this.temperature,
    required this.humidity,
    required this.soilPercent,
    required this.ldrRaw,
    required this.ph,
    required this.waterLevel,
    required this.relay,
    required this.autoMode,
    this.isLive = false,
    required this.timestamp,
  });

  factory SensorData.fromTelemetry(SensorTelemetry t) {
    return SensorData(
      temperature: t.temperature,
      humidity: t.humidity,
      soilPercent: t.soilMoisture,
      ldrRaw: t.sunlight,
      ph: t.soilPH,
      waterLevel: t.waterLevel,
      relay: t.pumpStatus,
      autoMode: t.autoMode,
      isLive: t.isLive,
      timestamp: t.timestamp,
    );
  }
}

class SensorService {
  static final SensorRepository _repo = SensorRepository();

  static Future<SensorData> fetchData() async {
    return SensorData.fromTelemetry(_repo.currentTelemetry);
  }

  static Future<void> pumpOn() async {
    await _repo.setPump(true);
  }

  static Future<void> pumpOff() async {
    await _repo.setPump(false);
  }
}
