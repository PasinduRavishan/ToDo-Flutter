import 'package:flutter/material.dart';
import 'package:todo/screens/todopage.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter To-Do',
      home: TodoPage(),
    );
  }
}

