import 'package:flutter/material.dart';
import 'package:webpctv/rpc/webapi/client.dart';

class MyDevPage extends StatefulWidget {
  const MyDevPage({
    Key? key,
    required this.client,
  }) : super(key: key);
  final Client client;
  @override
  _MyDevPageState createState() => _MyDevPageState();
}

class _MyDevPageState extends State<MyDevPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('測試頁面'),
      ),
      body: ListView(
        children: [
          TextButton(
            child: const Text('test'),
            onPressed: () {
              debugPrint("test button");
            },
          ),
        ],
      ),
    );
  }
}
