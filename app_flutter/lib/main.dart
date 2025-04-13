import 'package:flutter/material.dart';

void main() {
  runApp(ToonStoreApp());
}

class ToonStoreApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TOONSTORE',
      theme: ThemeData(primarySwatch: Colors.green),
      home: Scaffold(body: Center(child: Text('TOONSTORE Flutter App'))),
    );
  }
}