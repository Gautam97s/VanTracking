import 'package:flutter/material.dart';

import 'driver_screen.dart';
import 'user_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Van Tracker"),
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            ElevatedButton(

              onPressed: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DriverScreen(),
                  ),
                );
              },

              child: const Text("Driver"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(

              onPressed: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UserScreen(),
                  ),
                );
              },

              child: const Text("User"),
            ),
          ],
        ),
      ),
    );
  }
}