import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_telemetry.dart';

class SensorRepository {
  static final SensorRepository _instance = SensorRepository._internal();
  factory SensorRepository() => _instance;
  SensorRepository._internal();

  static const String baseUrl = 'https://krishisetu.api.serverpod.space';
  static const Duration requestTimeout = Duration(seconds: 4);
  static const Duration telemetryFreshnessWindow = Duration(seconds: 15);

  final StreamController<SensorTelemetry> _streamController =
      StreamController<SensorTelemetry>.broadcast();
  Stream<SensorTelemetry> get telemetryStream => _streamController.stream;

  SensorTelemetry _currentTelemetry = SensorTelemetry.demo();
  SensorTelemetry get currentTelemetry => _currentTelemetry;

  bool _isESP32Online = false;
  bool get isESP32Online => _isESP32Online;

  DateTime? _lastLiveTelemetryTime;
  DateTime? get lastLiveTelemetryTime => _lastLiveTelemetryTime;

  bool _simulatedPumpState = false;
  Timer? _pollingTimer;
  int _consecutiveFailures = 0;

  void start() {
    _pollingTimer?.cancel();
    _poll();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  void stop() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _poll() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/data'))
          .timeout(requestTimeout);

      if (res.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(res.body);
        if (body.containsKey('temperature') || body.containsKey('soilPercent')) {
          _consecutiveFailures = 0;
          _isESP32Online = true;
          _lastLiveTelemetryTime = DateTime.now();

          _currentTelemetry = SensorTelemetry.fromLiveJson(body);
          _streamController.add(_currentTelemetry);
          return;
        }
      }
      _handleFailure();
    } catch (_) {
      _handleFailure();
    }
  }

  void _handleFailure() {
    _consecutiveFailures++;

    final bool isStale = _lastLiveTelemetryTime == null ||
        DateTime.now().difference(_lastLiveTelemetryTime!) >
            telemetryFreshnessWindow;

    if (isStale) {
      _isESP32Online = false;
      _currentTelemetry = SensorTelemetry.demo(pumpStatus: _simulatedPumpState);
      _streamController.add(_currentTelemetry);
    }
  }

  Future<bool> setPump(bool targetState) async {
    _simulatedPumpState = targetState;

    if (_isESP32Online) {
      final endpoint = targetState ? 'on' : 'off';
      try {
        final res = await http
            .get(Uri.parse('$baseUrl/api/$endpoint'))
            .timeout(requestTimeout);
        if (res.statusCode == 200) {
          _currentTelemetry = _currentTelemetry.copyWith(pumpStatus: targetState);
          _streamController.add(_currentTelemetry);
          return true;
        }
      } catch (_) {
        // Fall back to simulation if physical command fails
      }
    }

    // Demo/Simulated pump execution
    _currentTelemetry = _currentTelemetry.copyWith(
      pumpStatus: targetState,
      source: _isESP32Online ? TelemetrySource.live : TelemetrySource.demo,
    );
    _streamController.add(_currentTelemetry);
    return true;
  }

  void dispose() {
    stop();
    _streamController.close();
  }
}
