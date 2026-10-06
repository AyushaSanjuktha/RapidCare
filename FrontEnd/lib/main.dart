import 'package:flutter/material.dart';
import 'utils/theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const RapidCareApp());
}

class RapidCareApp extends StatelessWidget {
  const RapidCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RapidCare',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomeScreen(),
    );
  }
}
