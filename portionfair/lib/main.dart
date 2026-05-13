import 'package:flutter/material.dart';
import 'login_page.dart';

void main() => runApp(const TaskFairApp());

class TaskFairApp extends StatelessWidget {
  const TaskFairApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskFair',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0F0A),
        colorScheme: const ColorScheme.dark(primary: Color(0xFF22C55E)),
      ),
      home: const LoginPage(),
    );
  }
}
