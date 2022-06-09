import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webpctv/pages/home/mount.dart';
import 'package:webpctv/rpc/webapi/client.dart';
import 'package:webpctv/widget/drawer.dart';
import 'package:webpctv/widget/state.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
    required this.client,
  }) : super(key: key);
  final Client client;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

abstract class _State extends MyState<MyHomePage> {
  Client get client => widget.client;
  _openDevice(int id) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MyMountPage(
          client: client,
          device: id,
        ),
      ),
    );
  }
}

class _MyHomePageState extends _State with _KeyboardComponent {
  @override
  void initState() {
    super.initState();

    listenKeyUp(onKeyUp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: openDrawerOfAppBar(
          context,
        ),
        title: const Text('WebPC TV'),
      ),
      drawer: MyDrawerView(
        client: client,
      ),
      body: ListView(
        children: client.devices
            .map(
              (e) => FocusScope(
                node: focusScopeNode,
                child: ListTile(
                  focusNode: createFocusNode('device_$e'),
                  leading: const Icon(Icons.star),
                  title: Text('$e'),
                  onTap: () {
                    _openDevice(e);
                  },
                ),
              ),
            )
            .toList(),
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
    if (id == MyFocusNode.openDrawer) {
      openDrawer();
      return;
    }
    if (id.startsWith('device_')) {
      try {
        final device = int.parse(id.substring('device_'.length));
        _openDevice(device);
      } catch (_) {}
    }
  }
}
