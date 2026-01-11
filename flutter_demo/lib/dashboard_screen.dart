import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'data_service.dart';
import 'control_settings.dart';
import 'notification_service.dart';
import 'firestore_service.dart';

// Scaffold (Screen Structure)
// └── appBar (Title Bar)
//     └── Text ('Real-Time Sensor Monitoring')

// └── body (Main Content Area)
//     └── StreamBuilder<SensorData> (Listens to _sensorService.sensorDataStream)

//         ├── (State: waiting)  -> Center
//         │                       └── CircularProgressIndicator
//         │
//         ├── (State: hasError) -> Center
//         │                       └── Text ('Error...')
//         │
//         └── (State: hasData)  -> SingleChildScrollView (Enables Scrolling)
//             └── Padding (16px Margin)
//                 └── Column (Vertical Stack)
//                     ├── Text ('Current Cultivation Conditions')
//                     ├── Divider

//                     // --- REPEATED SENSOR CARD STRUCTURE (7 TIMES) ---
//                     ├── _buildSensorCard (e.g., Temperature Card)
//                     │   └── Card (Rounded Borders, Dynamic Color)
//                     │       └── Padding (16px Inner Spacing)
//                     │           └── Column (Vertical Layout: spaceBetween)
//                     │
//                     │               // 1. TOP HEADER ROW
//                     │               ├── Row (Horizontal Layout)
//                     │               │   ├── CircleAvatar (Radius 14, Background)
//                     │               │   │   └── Icon (Size 18, Symbol)
//                     │               │   ├── SizedBox (8px Spacer)
//                     │               │   └── Expanded
//                     │               │       └── Text (Title: 'Temperature')
//                     │               │
//                     │               // 2. BOTTOM VALUE ALIGNMENT
//                     │               └── Align (Position: bottomRight)
//                     │                   └── Text (Value: 25.0 °C)
//                     │
//                     └── SizedBox (16px Spacer)

//                     ├── _buildSensorCard (pH Level Card)
//                     └── SizedBox (16px Spacer)
//                     // ... 5 more cards ...

// // --- Create a singleton instance of the service ---
// // final: makes reference constant
// final SensorService _sensorService = SensorService();

// Create and manage accompanying state object _MonitoringScreenState
class MonitoringScreen extends StatefulWidget {
  final String systemId;
  const MonitoringScreen({required this.systemId, super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  // Hold single instance of data service
  late final SensorService _sensorService;

  @override
  void initState() {
    // Call parent class's implementation of initState
    super.initState();
    // Initialise the service and start the timer when the screen is created
    _sensorService = SensorService();
  }

  @override
  void dispose() {
    // Call parent class's implementation of dispose
    super.dispose();
  }

  @override
  // Called to build the UI whenever needed
  Widget build(BuildContext context) {
    // The Scaffold here is now bare, it only provides the body to the
    // MainNavigationScreen, which supplies the actual AppBar
    return Scaffold(
      // Pass the managed instance to the dashboard widget
      body: MonitoringDashboard(
          sensorService: _sensorService, systemId: widget.systemId),
    );
  }
}

class MonitoringDashboard extends StatefulWidget {
  final SensorService sensorService;
  final String systemId;

  // MonitoringDashboard: constructor's name
  // super.key: forwards optional key parameter up to its parent class
  const MonitoringDashboard({
    required this.sensorService,
    required this.systemId,
    super.key,
  });

  @override
  State<MonitoringDashboard> createState() => _MonitoringDashboardState();
}

// StatelessWidget: widget's appearance and behaviour are fixed once it is created
class _MonitoringDashboardState extends State<MonitoringDashboard> {
  final ControlSettingsManager _settingsManager = ControlSettingsManager();

  final FirestoreService _firestoreService = FirestoreService();

  // Reference to the specific camera document
  late DocumentReference _cameraDoc;

  late Stream<QuerySnapshot> _activityStream;

  @override
  void initState() {
    super.initState();
    _initializeCameraRef();
    _syncNotificationToken();
    _activityStream = _firestoreService.getSystemActivity(widget.systemId);
  }

  // If user switches between "System 1" and "System 2"
  @override
  void didUpdateWidget(MonitoringDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.systemId != oldWidget.systemId) {
      _initializeCameraRef();
      _syncNotificationToken();
      // Re-initialize if the system ID changes
      setState(() {
        _activityStream = _firestoreService.getSystemActivity(widget.systemId);
      });
    }
  }

  void _initializeCameraRef() {
    // Converts "System 1" to "system_1" to match Firestore document ID
    String docId = widget.systemId.toLowerCase().replaceAll(' ', '_');
    _cameraDoc = FirebaseFirestore.instance.collection('camera').doc(docId);
  }

  void _syncNotificationToken() {
    NotificationService().initialize(widget.systemId);
  }

  // Triggers the Raspberry Pi by updating Firestore request
  Future<void> _triggerCapture() async {
    try {
      await _cameraDoc.update({'isCaptureRequested': true});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  //determine if a sensor is active/present for the current system.
  bool _isSensorActive(String sensorName, SensorData data) {
    if (widget.systemId == 'System 1')
      return true; // All sensors active on System 1

    // For System 2, only temperature is active
    if (sensorName == 'Temperature') {
      return data.temperature != 0.0;
    }
    // All other sensors are inactiveSystem 2
    return false;
  }

  // Helper method to build the individual sensor cards
  Widget _buildSensorCard({
    // required parameters: define all dynamic data needed to construct the card
    required String title,
    required String value,
    required IconData icon,
    // flag which triggers red colour warning in UI
    required Color color,
    bool isCritical = false,
    // check if sensor is active
    required bool isActive,
  }) {
    // If sensor is not active, set the critical flag and adjust display
    //final effectiveCritical = isCritical || !isActive;
    final displayTitle = isActive ? title : '$title (Inactive)';
    final displayValue = isActive ? value : 'N/A';
    // Determine background color based on criticality
    final cardColor = isCritical ? Colors.red.shade800 : color;
    // Determine value text style
    final valueStyle = TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w900,
      // Value text colour based on criticality
      color: isCritical ? Colors.white : Colors.teal.shade900,
    );

    // Determine icon color, same colour regardless of criticality
    final iconColor = isCritical ? Colors.white : Colors.white;

    // Determine title text style
    final titleStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      // Title text colour based on criticality
      color: isCritical ? Colors.white : Colors.grey.shade700,
    );

    // Constant size for an icon
    const double iconSize = 18;
    // Radius of colored circular background
    const double avatarRadius = 14;

    return Card(
      // Colour of card when not critical
      color: isCritical ? cardColor : Colors.white,
      // Size of shadow cast by the card
      elevation: 5,
      shape: RoundedRectangleBorder(
        // Rounded corners with a radius of 15 pixels
        borderRadius: BorderRadius.circular(15),
        // Continuous border around the card
        side: BorderSide(
          color: isCritical ? Colors.red.shade900 : Colors.teal.shade200,
          width: 2,
        ),
      ),
      child: Padding(
        // Space around the contents of the card, prevent content from touching card edges
        padding: const EdgeInsets.all(16.0),
        // Widget stacks its children vertically
        child: Column(
          // Aligns all children to the left edge of card
          crossAxisAlignment: CrossAxisAlignment.start,
          // Pushes the first and last children to top and bottom, evenly distributing vertical space in between
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            // Arranges children horizontally (icon, space, title)
            Row(
              children: [
                // Circle to frame the sensor icon
                CircleAvatar(
                  backgroundColor: cardColor,
                  radius: avatarRadius,
                  // Places sensor icon inside the circle
                  child: Icon(icon, color: iconColor, size: iconSize),
                ),
                // Horizontal space between icon circle and title text
                const SizedBox(width: 8),
                // Forces title to take up all the remaining horizontal space in the row
                Expanded(
                  child: Text(
                    displayTitle,
                    style: titleStyle,
                    // If the title is too long to fit, it will be cut off and replaced with "..."
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Precise positioning of a single child widget within its available space
            Align(
              // Position to bottom right corner of Align widget
              alignment: Alignment.bottomRight,
              child: Text(displayValue, style: valueStyle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraSection() {
    // System 2: Camera is not available
    if (widget.systemId == 'System 2') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Center(
          child: Text(
            'Camera Feature Not Available for ${widget.systemId}',
            style: TextStyle(
                fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ),
      );
    }

    // System 1 logic: Camera is available
    // Creates live connection to Firestore document
    return StreamBuilder<DocumentSnapshot>(
      stream: _cameraDoc.snapshots(),
      // Rebuilds UI everytime the document is updated by Pi
      builder: (context, snapshot) {
        // No internet
        if (snapshot.hasError) return const Text("Camera sync error");
        // Waiting period to obtain data from cloud when app is first opened
        if (!snapshot.hasData) return const LinearProgressIndicator();

        // Extract actual fields from "camera" document
        // as Map<String, dynamic>? : convert those fields into a Map format
        var data = snapshot.data!.data() as Map<String, dynamic>?;
        bool isBusy = data?['isCaptureRequested'] ?? false;
        String? imageUrl = data?['last_image_url'];

        // Extract the timestamp and convert it to a readable String
        final dynamic timestampRaw = data?['last_capture_time'];
        String timeLabel = "Never captured";

        if (timestampRaw != null && timestampRaw is Timestamp) {
          DateTime dt = timestampRaw
              .toDate()
              .toLocal(); // Convert UTC to phone local time
          timeLabel =
              "${dt.day}/${dt.month}/${dt.year} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(
              'Live System Image',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700),
            ),
            const Divider(height: 20, thickness: 1),

            // Image Container
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.shade100, width: 2),
              ),
              child: isBusy
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.teal),
                          SizedBox(height: 12),
                          Text("Pi is capturing image...",
                              style: TextStyle(
                                  color: Colors.teal,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  : (imageUrl != null
                      ? Image.network(
                          imageUrl,
                          key: ValueKey(imageUrl),
                          fit: BoxFit.cover,
                          // Checks image downloading progress
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                                child: CircularProgressIndicator());
                          },
                          // eg. phone loses internet mid-download, image was deleted from the bucket
                          errorBuilder: (context, error, stack) => const Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey),
                        )
                      : const Center(child: Text("No image available"))),
            ),
            const SizedBox(height: 12),

            // Timestamp Label
            Center(
              child: Text(
                "Last captured: $timeLabel",
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Renew Button
            ElevatedButton.icon(
              onPressed: isBusy ? null : _triggerCapture,
              icon: Icon(isBusy ? Icons.hourglass_top : Icons.camera_alt),
              label: Text(isBusy ? 'Capturing...' : 'Renew System Image'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        );
      },
    );
  }

  // understand code below
  Widget _buildActivityLogItem(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final String type = data['type'] ?? 'Unknown';
    final String trigger = data['trigger'] ?? 'auto';
    final Map<String, dynamic>? values =
        data['value_at_event'] as Map<String, dynamic>?;

    // Use the document ID as the display time since the field is missing
    final String displayTime = doc.id;

    return Card(
      key: ValueKey(doc.id),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(
          type == 'Harvest' ? Icons.eco : Icons.opacity,
          color: Colors.teal,
        ),
        title: Text('$type ($trigger)',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (values != null)
              Text(
                  'EC: ${values['ec']} | RGB: ${values['rgb']} | Turb: ${values['turbidity']}'),
            Text(displayTime,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //return Scaffold(
    //  // slot in Scaffold which sits on top of the screen
    //  appBar: AppBar(
    //    title: const Text('Real-Time Sensor Monitoring'),
    //    // Sets the background colour of bar to main primary colour of the app
    //    backgroundColor: Theme.of(context).colorScheme.primary,
    //    // Colour for all elements on the app bar
    //    foregroundColor: Colors.white,
    //    // Shadow beneath the app bar
    //    elevation: 4,
    //  ),

    // Get current control settings
    final controlSettings = _settingsManager.getSettings(widget.systemId);

    // StreamBuilder listens to the data stream and rebuilds on every update
    return StreamBuilder<SensorData>(
      // The data stream from the mock service
      // Filter the stream to only show data for the currently selected systemId
      stream: widget.sensorService.sensorDataStream
          .where((data) => data.systemId == widget.systemId),
      // responsible for building UI based on the latest data or state of stream
      // context: widget's location in the tree
      // snapshot: key object, latest information received from the stream
      builder: (context, snapshot) {
        // 1. Loading State
        // If the stream connection is still setting up
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Display a spinning circle centered on the screen
          return const Center(child: CircularProgressIndicator());
        }

        // 2. Error State
        // If the stream has encountered error during transmission
        if (snapshot.hasError) {
          // Display error message
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        // 3. Data Loaded State
        // If the stream connection is active and snapshot object received a valid piece of data
        if (snapshot.hasData) {
          // Latest SensorData object from the stream
          final data = snapshot.data!;

          // Ensure the dashboard is fully responsive and usable on different screen sizes
          // Enable vertical scrolling if content exceed heigh of device screen
          return SingleChildScrollView(
            // Margin space between content and screen edges
            padding: const EdgeInsets.all(16.0),
            // Stacks subsequent UI elements vertically
            child: Column(
              // Aligns all children within the coloumn to left edge of the screen
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header for the dashboard
                Text(
                  widget.systemId,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),

                // Thin horizontal line
                // Vertical space consumed by divider, 10 px above + 10 px below
                const Divider(height: 20, thickness: 1),

                // Display sensor cards vertically in a Column
                _buildSensorCard(
                  title: 'Temperature',
                  // Live SensorData object extracted from StreamBuilder snapshot
                  // toStringAsFixed(1): formats the floating-point number to display only 1 decimal place
                  value: '${data.temperature.toStringAsFixed(1)} °C',
                  icon: Icons.thermostat_outlined,
                  color: Colors.red.shade300,
                  isActive: _isSensorActive('Temperature', data),
                  // isCritical flag turns true when data falls outside safe range
                  isCritical: data.temperature > controlSettings.tempMax ||
                      data.temperature < controlSettings.tempMin,
                ),

                // Separation between two sensor cards
                const SizedBox(height: 16),

                _buildSensorCard(
                  title: 'pH Level',
                  value: data.pH.toStringAsFixed(2),
                  icon: Icons.science_outlined,
                  color: Colors.green.shade300,
                  isActive: _isSensorActive('pH Level', data),
                  isCritical: _isSensorActive('pH Level', data) &&
                      (data.pH > controlSettings.phMax ||
                          data.pH < controlSettings.phMin),
                ),
                const SizedBox(height: 16),

                _buildSensorCard(
                  title: 'Water Level',
                  value: '${data.waterLevel.toStringAsFixed(1)}%',
                  icon: Icons.water_drop_outlined,
                  color: Colors.blue.shade300,
                  isActive: _isSensorActive('Water Level', data),
                ),
                const SizedBox(height: 16),

                _buildSensorCard(
                  title: 'Conductivity',
                  value: '${data.conductivity.toStringAsFixed(2)} mS/cm',
                  icon: Icons.scatter_plot_outlined,
                  color: Colors.purple.shade300,
                  isActive: _isSensorActive('Conductivity', data),
                  isCritical: _isSensorActive('Conductivity', data) &&
                      (data.conductivity > controlSettings.ecMax ||
                          data.conductivity < controlSettings.ecMin),
                ),

                _buildSensorCard(
                  title: 'Light Intensity',
                  value: '${data.lightIntensity.toStringAsFixed(0)} lux',
                  icon: Icons.lightbulb_outline,
                  color: Colors.amber.shade300,
                  isActive: _isSensorActive('Light Intensity', data),
                ),
                const SizedBox(height: 16),

                _buildSensorCard(
                  title: 'Turbidity',
                  value: '${data.turbidity.toStringAsFixed(1)} NTU',
                  icon: Icons.opacity_outlined,
                  color: Colors.brown.shade300,
                  isActive: _isSensorActive('Turbidity', data),
                ),
                const SizedBox(height: 16),

                _buildSensorCard(
                  title: 'Colour Density',
                  value: '${data.color.toStringAsFixed(0)} value',
                  icon: Icons.color_lens_outlined,
                  color: Colors.lime.shade300,
                  isActive: _isSensorActive('Colour Density', data),
                ),
                const SizedBox(height: 16),

                _buildCameraSection(),
                const SizedBox(height: 32),

                // understand code below
                Text(
                  'System Activity History',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade700),
                ),
                const Divider(),

                StreamBuilder<QuerySnapshot>(
                  stream: _activityStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError)
                      return Text("Error: ${snapshot.error}");
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final logs = snapshot.data?.docs ?? [];

                    if (logs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text("No activity logs found for this system."),
                      );
                    }

                    return Column(
                      children: logs
                          .map((doc) => _buildActivityLogItem(doc))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          );
        }

        // Fallback occurs when
        // - StreamBuilder finished its initial setup
        // - snapshot has no data and no error
        return const Center(child: Text('No sensor data available.'));
      },
      //  ),
    );
  }
}
