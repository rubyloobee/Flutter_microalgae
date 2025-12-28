import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'main_navigation.dart';

// LoadingScreen (StatefulWidget)
// └── Scaffold (Basic Screen Structure)
//     └── backgroundColor: Colors.white
//     └── body (The main content area)
//         └── Center (Centers its child both horizontally and vertically)
//             └── Column (Stacks children vertically)
//                 └── mainAxisAlignment: center (Centers the whole column vertically)
//                 └── children: [

//                     ├── Icon (Icons.waves, size 80, color Teal)
//                     │
//                     ├── SizedBox (20px Vertical Spacer)
//                     │
//                     ├── Text ('Initialising System Data...')
//                     │
//                     ├── SizedBox (40px Vertical Spacer)
//                     │
//                     └── CircularProgressIndicator (color Teal)
//                 ]

// ----------------------------------------------------
// LOADING PAGE
// ----------------------------------------------------
// StatefulWidget: appearance needs to change over time
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  // mandatory for all StatefulWidget
  // create and instance of corresponding class to manage changing of data
  State<LoadingScreen> createState() => _LoadingScreenState();
}

// defines a state object, _ makes it private to the main.dart file
class _LoadingScreenState extends State<LoadingScreen> {
  @override
  // called once when State object is first created
  void initState() {
    // Calls parent State class's initialization method
    super.initState();
    // Start connecting to Firebase as soon as this screen appears
    _initialiseSystem();
  }

  Future<void> _initialiseSystem() async {
    try {
      // 1. Initialize Firebase ('Asynchronous Gap')
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("Firebase Connected");

      // 2. Add a tiny delay (1s) so the user can actually see the brand icon
      await Future.delayed(const Duration(seconds: 1));

      // 3. Move to the main app
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    } catch (e) {
      print("Initialization Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // This screen uses Scaffold but OMITs the 'appBar' property.
    return const Scaffold(
      backgroundColor: Colors.white, // Clean white background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Use an icon to represent loading
            Icon(Icons.waves, size: 80, color: Colors.teal),
            SizedBox(height: 20),
            Text(
              'Initialising System Data...',
              style: TextStyle(fontSize: 18, color: Colors.teal),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Colors.teal),
          ],
        ),
      ),
    );
  }
}
