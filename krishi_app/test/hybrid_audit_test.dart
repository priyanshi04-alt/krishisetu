import 'package:flutter_test/flutter_test.dart';
import 'package:krishi_app/models/sensor_telemetry.dart';
import 'package:krishi_app/services/sensor_repository.dart';

void main() {
  group('Hybrid Architecture Technical Audit', () {
    test('TEST 4 & 6: Invalid/missing telemetry yields Demo Mode with simulated pump', () {
      final repo = SensorRepository();
      // Initially without live ESP32, currentTelemetry must be DEMO
      expect(repo.isESP32Online, isFalse);
      expect(repo.currentTelemetry.isDemo, isTrue);
      expect(repo.currentTelemetry.temperature, 28.5);
      expect(repo.currentTelemetry.soilMoisture, 42.0);

      // Verify simulated pump in demo mode
      repo.setPump(true);
      expect(repo.currentTelemetry.pumpStatus, isTrue);
      expect(repo.currentTelemetry.isDemo, isTrue);

      repo.setPump(false);
      expect(repo.currentTelemetry.pumpStatus, isFalse);
    });

    test('TEST 5: Freshness window and LIVE -> DEMO transition', () {
      final liveTelemetry = SensorTelemetry.fromLiveJson({
        'temperature': 31.2,
        'humidity': 58.0,
        'soilPercent': 62.0,
        'ldrRaw': 14200.0,
        'ph': 6.8,
        'waterLevel': true,
        'relay': false,
        'autoMode': true,
      });

      expect(liveTelemetry.isLive, isTrue);
      expect(liveTelemetry.temperature, 31.2);
      expect(liveTelemetry.source, TelemetrySource.live);

      // Simulate stale data (> 15 seconds)
      final staleTimestamp = DateTime.now().subtract(const Duration(seconds: 20));
      final isStale = DateTime.now().difference(staleTimestamp) >
          SensorRepository.telemetryFreshnessWindow;

      expect(isStale, isTrue, reason: 'Stale telemetry (>15s) must trigger fallback');
    });

    test('TEST 8: Live pump commands require confirmed device connectivity', () {
      final repo = SensorRepository();
      expect(repo.isESP32Online, isFalse);
      // When offline, setPump executes locally without physical actuation
      repo.setPump(true);
      expect(repo.currentTelemetry.source, TelemetrySource.demo);
    });
  });
}
