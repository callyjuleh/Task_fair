import 'package:flutter/material.dart';
import 'login_page.dart';

void main() => runApp(const TaskFairApp());

class TaskFairApp extends StatelessWidget {
  const TaskFairApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'TaskFair',
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}
