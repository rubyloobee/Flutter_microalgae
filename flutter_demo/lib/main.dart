// essential line for building a standard Flutter application
import 'package:flutter/material.dart';
import 'loading_screen.dart';
import 'notification_service.dart';

void main() async {
  // 1. Ensure Flutter is ready to call native code (needed for Firebase)
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Notification Service
  final notificationService = NotificationService();
  await notificationService.initForegroundNotifications();

  // 3. runApp: Sets the widget tree's root.
  runApp(const SimpleGreetingApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 2. The main app container (StatelessWidget)
class SimpleGreetingApp extends StatelessWidget {
  // creates a new widget which describes a piece of the user interface
  // that does not change after it is built
  const SimpleGreetingApp({
    super.key,
  }); // constructor, super.key is used by Flutter internally to identify widgets efficiently

  @override // replaces a method inherited from StatelessWidget parent class
  Widget build(BuildContext context) {
    // 3. MaterialApp: Provides Material Design styling and navigation services.
    return MaterialApp(
      navigatorKey: navigatorKey,
      // returns a widget (blueprint of what should be drawn on the screen)
      // wrapper for whole application
      title:
          'Microalgae System', // title which appears in the operating system's task switcher
      theme: ThemeData(
        // define the overall visual aesthetic for all widgets in the app
        // sets the primary colours, fonts and default button styles
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
        ), // sets a range of related shades based on the colour teal
        useMaterial3:
            true, // latest generation of Google's open source design system
        visualDensity: VisualDensity
            .adaptivePlatformDensity, // visualDensity determines the size and spacing of interactive UI elements
        // makes it smart, Flutter dynamically adjust density based on the device
      ),
      home:
          const LoadingScreen(), // specifies the initial screen or widget that should appear when the application first starts up
    );
  }
}
