import 'package:flutter/material.dart';

class StatsTab extends StatelessWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Text("📊 Stats Coming Soon", style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
