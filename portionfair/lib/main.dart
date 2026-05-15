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
      theme: ThemeData(
        fontFamily: 'Nunito',
        scaffoldBackgroundColor: const Color(0xFFFFF8F0),
        colorScheme: const ColorScheme.light(primary: Color(0xFFFF8C69)),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}