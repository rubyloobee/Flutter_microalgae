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
      await Future.wait([
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
}
