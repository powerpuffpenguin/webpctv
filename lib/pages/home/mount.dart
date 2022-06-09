import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webpctv/rpc/webapi/client.dart';
import 'package:webpctv/widget/state.dart';

class MyMountPage extends StatefulWidget {
  const MyMountPage({
    Key? key,
    required this.client,
    required this.device,
  }) : super(key: key);
  final Client client;
  final int device;

  @override
  _MyMountPageState createState() => _MyMountPageState();
}

abstract class _State extends MyState<MyMountPage> {
  Client get client => widget.client;
  int get device => widget.device;
}

class _MyMountPageState extends _State with _KeyboardComponent {
  @override
  void initState() {
    super.initState();

    listenKeyUp(onKeyUp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: backOfAppBar(context),
        title: Text('$device'),
      ),
    );
  }
}

mixin _KeyboardComponent on _State {
  void onKeyUp(KeyEvent evt) {
    if (evt.logicalKey == LogicalKeyboardKey.select) {
      if (enabled) {
        final focused = focusedNode();
        if (focused != null) {
          _selectFocused(focused);
        }
      }
    }
  }

  _selectFocused(MyFocusNode focused) {
    final id = focused.id;
    if (id == MyFocusNode.arrowBack) {
      Navigator.of(context).pop();
      return;
    }
  }
}
