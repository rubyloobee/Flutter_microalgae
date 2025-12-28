// Asyncrhonous programming, features needed: StreamController, Timer
import 'dart:async';
// Mathematical utilities, feature needed: Random
import 'dart:math';

// 1. Data Model: Defines the structure of the sensor readings (no change here)
class SensorData {
  final String systemId;
  // double: floating point number
  // final: - once a SensorData object is created,the values for its properties cannot be changed
  //        - generate a new object every time the data changes
  final double temperature;
  final double pH;
  final double waterLevel;
  final double lightIntensity;
  final double conductivity;
  final double turbidity;
  final double color;

  // Constructor, create/instantiate new SensorData object
  SensorData({
    // required: must provide a value for every property listed, else will have an error
    // this. refers to class's own instance variable
    required this.systemId,
    required this.temperature,
    required this.pH,
    required this.waterLevel,
    required this.lightIntensity,
    required this.conductivity,
    required this.turbidity,
    required this.color,
  });
}

// 2. Data Service: Provides a stream of highly volatile dummy sensor data updates
class SensorService {
  // --- Setup for the Stream ---
  // Push new SensorData objects into the stream
  // Use .broadcast() to allow multiple listeners
  final _controller = StreamController<SensorData>.broadcast();
  // Reference to the repeating timer
  // late: value will be set later (in the constructor) before it's first used
  late Timer _timer;
  // Create instance of Random class
  final _random = Random();

  // Public interface: allow external widgets to access raw data stream from private controller
  Stream<SensorData> get sensorDataStream => _controller.stream;

  // Stores current readings for both System 1 and 2
  final Map<String, SensorData> _currentReadings = {
    // Initial State for System 1 (Full System)
    'System 1': SensorData(
      systemId: 'System 1',
      temperature: 25.0,
      pH: 7.0,
      waterLevel: 90.0,
      lightIntensity: 1000.0,
      conductivity: 1.5,
      turbidity: 75.0,
      color: 400.0,
    ),
    // Initial State for System 2 (Temperature sensor only)
    'System 2': SensorData(
      systemId: 'System 2',
      temperature: 20.0, // Initial temperature for System 2
      pH: 0.0, // Inactive/Zero
      waterLevel: 0.0, // Inactive/Zero
      lightIntensity: 0.0, // Inactive/Zero
      conductivity: 0.0, // Inactive/Zero
      turbidity: 0.0, // Inactive/Zero
      color: 0.0, // Inactive/Zero
    ),
  };

  // Runs as soon as an instance of the service is created in dashboard.dart
  SensorService() {
    _startMockDataGeneration();
  }

  //// Helper function to calculate a new value using a pure random walk.
  // Takes current reading + 3 limits to control the next random movement
  double _calculateNextValue({
    required double currentValue,
    required double min,
    required double max,
    required double maxStep,
  }) {
    // Pure random walk step: Wiggles the value up or down by up to maxStep.
    // This is the only driver, making values very volatile.
    // _random.nextDouble(): random number between 0.0 and 1.0
    double step = (_random.nextDouble() * 2 * maxStep) - maxStep;

    double newValue = currentValue + step;

    // Clamp: Ensures the value never goes outside the physical min/max bounds.
    return newValue.clamp(min, max);
  }

  // --- Mock Data Generation Logic (Highly Volatile Ranges) ---
  // _ makes the function private, only SensorService class can call it
  void _startMockDataGeneration() {
    // Generates new sensor data every 2 seconds
    // Timer.periodic(): static method that creates a timer that runs repeatedly
    // (timer) {} that executes on every tick of the timer
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      // Iterate through all systems using the .entries property
      for (final entry in _currentReadings.entries) {
        final systemId = entry.key; // Explicitly get the key (System ID)
        final currentData =
            entry.value; // Explicitly get the value (SensorData)

        // Generate data based on system capabilities
        final newReading = (systemId == 'System 1')
            ? _generateFullSystemData(currentData)
            : _generateTempOnlyData(currentData);

        // Update state and push to stream
        _currentReadings[systemId] = newReading;
        // Pushes data to the stream
        // .sink: input end of the stream
        // .add(newReading): publishes the data, below are executed
        //                   - newReading object is pushed out onto sensorDataStream
        //                   - dashboard's StreamBuilder receives this update
        //                   - StreamBuilder runs its builder function again, using newReading object
        _controller.sink.add(newReading);
      }
    });
  }

  // Helper for System 1: All Sensors Active
  SensorData _generateFullSystemData(SensorData currentData) {
    return SensorData(
      systemId: 'System 1',
      // 1. Temperature
      temperature: _calculateNextValue(
        currentValue: currentData.temperature,
        min: 18.0,
        max: 30.0,
        maxStep: 0.8,
      ),
      // 2. pH
      pH: _calculateNextValue(
        currentValue: currentData.pH,
        min: 6.0,
        max: 8.0,
        maxStep: 0.2,
      ),
      // 3. Water Level
      waterLevel: _calculateNextValue(
        currentValue: currentData.waterLevel,
        min: 50.0,
        max: 80.0,
        maxStep: 3.0,
      ),
      // 4. Light Intensity
      lightIntensity: _calculateNextValue(
        currentValue: currentData.lightIntensity,
        min: 0.0,
        max: 3000.0,
        maxStep: 100.0,
      ),
      // 5. Conductivity
      conductivity: _calculateNextValue(
        currentValue: currentData.conductivity,
        min: 0.5,
        max: 3.0,
        maxStep: 0.3,
      ),
      // 6. Turbidity
      turbidity: _calculateNextValue(
        currentValue: currentData.turbidity,
        min: 50.0,
        max: 150.0,
        maxStep: 15.0,
      ),
      // 7. Color Density
      color: _calculateNextValue(
        currentValue: currentData.color,
        min: 200.0,
        max: 600.0,
        maxStep: 50.0,
      ),
    );
  }

  // Helper for System 2: Only Temperature Active
  SensorData _generateTempOnlyData(SensorData currentData) {
    return SensorData(
      systemId: 'System 2',
      // 1. Temperature (Only actively mocked sensor)
      temperature: _calculateNextValue(
        currentValue: currentData.temperature,
        min: 20.0,
        max: 28.0,
        maxStep: 0.1,
      ),
      // All other sensors are set to 0.0 (inactive/broken/off)
      pH: 0.0,
      waterLevel: 0.0,
      lightIntensity: 0.0,
      conductivity: 0.0,
      turbidity: 0.0,
      color: 0.0,
    );
  }

  // Mandatory clean-up function
  void dispose() {
    // If timer is not cancel when service is not needed, running it in the background will
    // consume CPU resources, push data to a non-existence stream, leading to errors
    _timer.cancel();
    // If controller is not closed, stream remains open and unnecessarily consum memory
    _controller.close();
  }
}
