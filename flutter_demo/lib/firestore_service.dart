import 'package:cloud_firestore/cloud_firestore.dart';
import 'control_settings.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Updates the light intensity and other control setpoints in Firestore
  Future<void> updateSystemControls(
      String systemId, ControlSettings settings) async {
    // Normalize "System X" to "system_X"
    final String docId = systemId.toLowerCase().replaceAll(' ', '_');
    try {
      // dedicated collection for system control and logging interval
      // Fure.wait: parallel execution
      // merge: true ensures we don't overwrite unrelated fields
      await Future.wait<void>([
        // 1. Actuators
        _db.collection('system_controls').doc(docId).set({
          'target_light_intensity': settings.lightIntensity,
          'target_light_duration': settings.lightDuration,
          'target_water_level': settings.targetWaterLevel,
          'target_stirring_speed': settings.stirringSpeed,
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),

        // 2. Logging Intervals
        _db.collection('log_interval').doc(docId).set({
          'primary_log_interval': settings.primaryLogInterval,
          'sampling_log_interval': settings.samplingLogInterval,
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),

        // 3. Data Threholds & FCM Token
        _db.collection('data_thresholds').doc(docId).set({
          'temp_min': settings.tempMin,
          'temp_max': settings.tempMax,
          'ph_min': settings.phMin,
          'ph_max': settings.phMax,
          'ec_min': settings.ecMin,
          'ec_max': settings.ecMax,
          // In a real app, you'd fetch this token from the FirebaseMessaging package
          'fcmToken': settings.fcmToken,
          'last_updated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
      ]);

      print("Firestore: Actuators and Logging synced for $systemId");
    } catch (e) {
      print("Firestore Error: $e");
      // Shows error message to user in UI
      rethrow;
    }
  }

  Future<ControlSettings?> fetchSystemSettings(String systemId) async {
    final String docId = systemId.toLowerCase().replaceAll(' ', '_');
    try {
      // 1. Fetch all three documents at once
      final snapshots = await Future.wait([
        _db.collection('system_controls').doc(docId).get(),
        _db.collection('log_interval').doc(docId).get(),
        _db.collection('data_thresholds').doc(docId).get(),
      ]);

      // 2. Extract data (return null if documents don't exist yet)
      final controls = snapshots[0].data();
      final logs = snapshots[1].data();
      final thresholds = snapshots[2].data();

      if (controls == null || logs == null || thresholds == null) return null;

      // 3. Map Firestore types (usually num/int) to Dart doubles
      return ControlSettings(
        lightIntensity: (controls['target_light_intensity'] as num).toDouble(),
        lightDuration: (controls['target_light_duration'] as num).toDouble(),
        targetWaterLevel: (controls['target_water_level'] as num).toDouble(),
        stirringSpeed: (controls['target_stirring_speed'] as num).toDouble(),
        primaryLogInterval: (logs['primary_log_interval'] as num).toDouble(),
        samplingLogInterval: (logs['sampling_log_interval'] as num).toDouble(),
        tempMin: (thresholds['temp_min'] as num).toDouble(),
        tempMax: (thresholds['temp_max'] as num).toDouble(),
        phMin: (thresholds['ph_min'] as num).toDouble(),
        phMax: (thresholds['ph_max'] as num).toDouble(),
        ecMin: (thresholds['ec_min'] as num).toDouble(),
        ecMax: (thresholds['ec_max'] as num).toDouble(),
        fcmToken: thresholds['fcmToken'] ?? "initial_token_placeholder",
      );
    } catch (e) {
      print("Fetch error: $e");
      return null;
    }
  }
}
