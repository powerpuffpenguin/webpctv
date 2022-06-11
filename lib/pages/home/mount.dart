import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webpctv/pages/error.dart';
import 'package:webpctv/pages/home/list.dart';
import 'package:webpctv/rpc/webapi/client.dart';
import 'package:webpctv/widget/spin.dart';
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
  final cancelToken = CancelToken();
  final source = <String>[];
  @override
  void dispose() {
    cancelToken.cancel();
    super.dispose();
  }

  _openRoot(String root) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MyListPage(
          client: client,
          device: device,
          root: root,
          path: '/',
        ),
      ),
    );
  }
}

class _MyMountPageState extends _State with _KeyboardComponent {
  @override
  void initState() {
    super.initState();
    Future.value().then((value) {
      if (isNotClosed) {
        _load();
      }
    });
    listenKeyUp(onKeyUp);
  }

  _load() async {
    setState(() {
      disabled = true;
    });
    try {
      final resp = await client.mount(device, cancelToken: cancelToken);
      checkAlive();
      setState(() {
        source.addAll(resp.name);
        disabled = false;
      });
    } catch (e) {
      if (isNotClosed) {
        pushReplacementErrorStringPage(context, '$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // leading: backOfAppBar(context),
        leading: Container(),
        leadingWidth: 0,
        title: Text('$device'),
      ),
      body: ListView(
        children: source
            .map(
              (item) => FocusScope(
                node: focusScopeNode,
                child: ListTile(
                  focusNode: createFocusNode('root_$item'),
                  leading: const Icon(Icons.star),
                  title: Text(item),
                  onTap: () {
                    _openRoot(item);
                  },
                ),
              ),
            )
            .toList(),
      ),
      floatingActionButton: enabled ? null : createSpinFloating(),
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
    if (id == MyFocusNode.arrowBack) {
      Navigator.of(context).pop();
      return;
    }
    if (id.startsWith('root_')) {
      _openRoot(id.substring('root_'.length));
    }
  }
}
