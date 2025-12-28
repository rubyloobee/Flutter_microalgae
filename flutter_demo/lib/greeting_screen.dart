import 'package:flutter/material.dart';

// ----------------------------------------------------
// MAIN PAGE
// ----------------------------------------------------
// StatelessWidget: text and appearance of the greeting won't change when viewed by user
class GreetingScreen extends StatelessWidget {
  // StatelessWidget: text and appearance of the greeting won't change when viewed by user
  const GreetingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 5. Scaffold: Provides the basic structure for the visual interface (App Bar, Body, etc.)
    // fundamental, blank canvas for any Material Design screen
    // handles safe area, background colour, structure
    return Scaffold(
      // slot in Scaffold which sits on top of the screen
      appBar: AppBar(
        title: const Text('Microalgae System Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white, // Ensures title text is white
      ),
      // 6. Body: The main content area of the screen.
      // large central area of screen below AppBar
      // Center widget places its child in the middle of the screen
      body: const Center(
        // takes a list of children and arranges that vertically
        child: Column(
          mainAxisAlignment: MainAxisAlignment
              .center, // center all of the children along its main axis
          // list of widgets inside Column
          children: <Widget>[
            Text(
              'Hello, IoT Microalgae System!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10), // spacer widget that takes up 10 px
            Text(
              'Your foundation is set.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
