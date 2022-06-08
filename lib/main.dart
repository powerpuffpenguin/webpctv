import 'package:flutter/material.dart';
import 'package:webpctv/pages/load/load.dart';
import 'package:webpctv/service/key_event_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _focusNode = FocusNode();
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (evt) => KeyEventService.instance.add(evt),
      child: MaterialApp(
        title: 'webpctv',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyLoadPage(),
      ),
    );
  }
}
