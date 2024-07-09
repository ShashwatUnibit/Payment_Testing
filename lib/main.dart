import 'package:flutter/material.dart';
import 'home.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Web Views',
      theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: "Arial",
          textTheme: const TextTheme(labelLarge: TextStyle(color: Colors.white, fontSize: 18.0), titleMedium: TextStyle(color: Colors.red))),
      home: Home(),
    );
  }
}
