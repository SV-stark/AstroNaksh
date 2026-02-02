import 'package:flutter/material.dart';
import 'styles.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AstroNaksh"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Settings
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.nightlight_round,
              size: 80,
              color: AppStyles.accentColor,
            ),
            const SizedBox(height: 16),
            Text(
              "Welcome to AstroNaksh",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              "No charts saved yet.",
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/input');
        },
        icon: const Icon(Icons.add),
        label: const Text("New Chart"),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: AppStyles.white,
      ),
    );
  }
}
