import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webpctv/pages/home/history.dart';
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
  _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MyHistoryPage(
          client: client,
        ),
      ),
    );
  }

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
      body: ListView.builder(
          itemCount: client.devices.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return FocusScope(
                node: focusScopeNode,
                child: ListTile(
                  focusNode: createFocusNode('history'),
                  leading: const Icon(Icons.play_circle),
                  title: const Text('play history'),
                  onTap: () {
                    _openHistory();
                  },
                ),
              );
            }
            final device = client.devices[i - 1];
            return FocusScope(
              node: focusScopeNode,
              child: ListTile(
                focusNode: createFocusNode('device_$device'),
                leading: const Icon(Icons.star),
                title: Text('$device'),
                onTap: () {
                  _openDevice(device);
                },
              ),
            );
          }),
    );
  }
}

mixin _KeyboardComponent on _State {
  void onKeyUp(KeyEvent evt) {
    if (evt.logicalKey == LogicalKeyboardKey.select) {
      final focused = focusedNode();
      if (focused != null) {
        _selectFocused(focused);
      }
    }
  }

  _selectFocused(MyFocusNode focused) {
    final id = focused.id;
    if (id == MyFocusNode.openDrawer) {
      openDrawer();
      return;
    } else if (id == 'history') {
      _openHistory();
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
