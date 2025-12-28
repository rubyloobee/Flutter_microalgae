import 'package:flutter/material.dart';

// 1. Data Model for Control Settings
// Moved here from control_screen.dart
class ControlSettings {
  final double targetWaterLevel;
  final double stirringSpeed;
  final double lightIntensity;
  final double lightDuration;

  final double primaryLogInterval; // Tier 1 (1-3 hours in seconds)
  final double samplingLogInterval; // Tier 2 (1-3 times/day in seconds)

  // Alert threshold
  final double tempMin;
  final double tempMax;
  final double phMin;
  final double phMax;
  final double ecMin;
  final double ecMax;
  final String fcmToken;

  ControlSettings({
    required this.targetWaterLevel,
    required this.stirringSpeed,
    required this.lightIntensity,
    required this.lightDuration,
    required this.primaryLogInterval,
    required this.samplingLogInterval,
    required this.tempMin,
    required this.tempMax,
    required this.phMin,
    required this.phMax,
    required this.ecMin,
    required this.ecMax,
    required this.fcmToken,
  });

  // Factory method to create a new instance from an existing one
  ControlSettings copyWith({
    double? targetWaterLevel,
    double? stirringSpeed,
    double? lightIntensity,
    double? lightDuration,
    double? primaryLogInterval,
    double? samplingLogInterval,
    double? tempMin,
    double? tempMax,
    double? phMin,
    double? phMax,
    double? ecMin,
    double? ecMax,
    String? fcmToken,
  }) {
    return ControlSettings(
      targetWaterLevel: targetWaterLevel ?? this.targetWaterLevel,
      stirringSpeed: stirringSpeed ?? this.stirringSpeed,
      lightIntensity: lightIntensity ?? this.lightIntensity,
      lightDuration: lightDuration ?? this.lightDuration,
      primaryLogInterval: primaryLogInterval ?? this.primaryLogInterval,
      samplingLogInterval: samplingLogInterval ?? this.samplingLogInterval,
      tempMin: tempMin ?? this.tempMin,
      tempMax: tempMax ?? this.tempMax,
      phMin: phMin ?? this.phMin,
      phMax: phMax ?? this.phMax,
      ecMin: ecMin ?? this.ecMin,
      ecMax: ecMax ?? this.ecMax,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  @override
  String toString() {
    return '--- Control Settings Manager State ---\n'
        'Primary Log Interval: ${primaryLogInterval.toStringAsFixed(0)} s\n'
        'Sampling Log Interval: ${samplingLogInterval.toStringAsFixed(0)} s\n'
        'LED intensity: ${lightIntensity.toStringAsFixed(0)}\n'
        'Photoperiod: ${lightDuration.toStringAsFixed(0)}h\n'
        'Water Level Target: ${targetWaterLevel.toStringAsFixed(0)}%\n'
        'Stirring Speed: ${stirringSpeed.toStringAsFixed(0)} RPM\n'
        'Temp Thresholds: ${tempMin.toStringAsFixed(1)}°C - ${tempMax.toStringAsFixed(1)}°C\n'
        'pH Thresholds: ${phMin.toStringAsFixed(1)} - ${phMax.toStringAsFixed(1)} pH\n'
        'EC Thresholds: ${ecMin.toStringAsFixed(1)} - ${ecMax.toStringAsFixed(1)} ms/cm\n';
  }
}

// 2. Singleton Manager Class
// This instance will persist across screen changes.
class ControlSettingsManager {
  // Static instance of the manager (Singleton pattern)
  static final ControlSettingsManager _instance =
      ControlSettingsManager._internal();

  // Factory constructor returns the same instance every time
  factory ControlSettingsManager() {
    return _instance;
  }

  // Private constructor
  ControlSettingsManager._internal();

  // // Internal state holding the latest settings (Initialized with default values)
  final Map<String, ControlSettings> _settingsMap = {
    'System 1': ControlSettings(
      targetWaterLevel: 70.0,
      stirringSpeed: 100.0,
      lightIntensity: 700,
      lightDuration: 12,
      // primaryLogInterval: 7200.0, // Default 2 hours
      // samplingLogInterval: 43200.0, // Default 12 hours
      primaryLogInterval: 5,
      samplingLogInterval: 10,
      tempMin: 20.0,
      tempMax: 28.0,
      phMin: 6.5,
      phMax: 8.0,
      ecMin: 0.5,
      ecMax: 2.5,
      fcmToken: "initial_token_placeholder",
    ),
    'System 2': ControlSettings(
      targetWaterLevel: 60.0,
      stirringSpeed: 50.0,
      lightIntensity: 0,
      lightDuration: 0,
      // primaryLogInterval: 3600.0,
      // samplingLogInterval: 86400.0,
      primaryLogInterval: 5,
      samplingLogInterval: 10,
      tempMin: 20.0,
      tempMax: 28.0,
      phMin: 6.5,
      phMax: 8.0,
      ecMin: 0.5,
      ecMax: 2.5,
      fcmToken: "initial_token_placeholder",
    ),
  };

  // Getter for the current settings
  ControlSettings getSettings(String systemId) {
    // Returns settings for the given ID, or System 1's settings as a fallback
    return _settingsMap[systemId] ?? _settingsMap['System 1']!;
  }

  // Setter method to update all settings for a specific system
  void updateSettings(String systemId, ControlSettings newSettings) {
    _settingsMap[systemId] = newSettings;
    // Log the change for debugging
    debugPrint('Settings updated for $systemId:');
    debugPrint(_settingsMap[systemId].toString());

    // NOTE: If this were connected to Firebase, the write operation would happen here.
  }

  // Setter functions accept a systemId
  void _updateSpecificSetting(
      String systemId, ControlSettings Function(ControlSettings) copyFunction) {
    final current = getSettings(systemId);
    final updated = copyFunction(current);
    _settingsMap[systemId] = updated;
  }

  // Setter for individual slider values (used by the ControlScreen sliders)
  void setWaterLevel(String systemId, double level) {
    _updateSpecificSetting(
        systemId, (c) => c.copyWith(targetWaterLevel: level));
  }

  void setStirringSpeed(String systemId, double speed) {
    _updateSpecificSetting(systemId, (c) => c.copyWith(stirringSpeed: speed));
  }

  void setLightIntensity(String systemId, double lightIntensity) {
    _updateSpecificSetting(
        systemId, (c) => c.copyWith(lightIntensity: lightIntensity));
  }

  void setLightDuration(String systemId, double lightDuration) {
    _updateSpecificSetting(
        systemId, (c) => c.copyWith(lightDuration: lightDuration));
  }

  void setPrimaryLogInterval(String systemId, double interval) {
    _updateSpecificSetting(
        systemId, (c) => c.copyWith(primaryLogInterval: interval));
  }

  void setSamplingLogInterval(String systemId, double interval) {
    _updateSpecificSetting(
        systemId, (c) => c.copyWith(samplingLogInterval: interval));
  }

  // NOTE: Text field changes are handled by TextEditingController,
  // so we only update the manager when the final 'Save' button is pressed.
}
