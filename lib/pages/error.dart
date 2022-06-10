import 'package:flutter/material.dart';
import 'package:webpctv/environment.dart';

Future<void> pushErrorStringsPage(BuildContext context, List<String> body) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => MyErrorStringsPage(
        body: body,
      ),
    ),
  );
}

Future<void> pushReplacementErrorStringsPage(
    BuildContext context, List<String> body) {
  return Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (context) => MyErrorStringsPage(
        body: body,
      ),
    ),
  );
}

Future<void> pushErrorStringPage(BuildContext context, String body) {
  return pushErrorStringsPage(context, <String>[body]);
}

Future<void> pushReplacementErrorStringPage(BuildContext context, String body) {
  return pushReplacementErrorStringsPage(context, <String>[body]);
}

class MyErrorStringsPage extends StatelessWidget {
  const MyErrorStringsPage({
    Key? key,
    required this.body,
  }) : super(key: key);
  final List<String> body;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(),
        leadingWidth: 0,
        title: const Text('Error'),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MyEnvironment.viewPadding),
      child: ListView.builder(
        itemCount: body.length,
        itemBuilder: (context, i) {
          final v = body[i];
          return Text(
            v,
            style: TextStyle(color: Theme.of(context).errorColor),
          );
        },
      ),
    );
  }
}
