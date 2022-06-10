import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webpctv/rpc/webapi/client.dart';
import 'package:webpctv/rpc/webapi/fs.dart';
import 'package:webpctv/widget/spin.dart';
import 'package:webpctv/widget/state.dart';
import 'package:path/path.dart' as path;

class MyVideoPage extends StatefulWidget {
  const MyVideoPage({
    Key? key,
    required this.client,
    required this.device,
    required this.root,
    required this.path,
    required this.name,
    required this.videos,
    required this.access,
  }) : super(key: key);
  final Client client;
  final int device;
  final String root;
  final String path;
  final String name;
  final List<Source> videos;
  final String access;

  @override
  _MyVideoPageState createState() => _MyVideoPageState();
}

class Source {
  bool get isDir => fileInfo.isDir;
  String get name => fileInfo.name;
  final FileInfo fileInfo;
  final List<FileInfo> captions;
  Source({required this.fileInfo, required this.captions});
  static int compare(Source l, Source r) =>
      FileInfo.compare(l.fileInfo, r.fileInfo);

  addCaptions(List<FileInfo> items) {
    final prefix = path.basenameWithoutExtension(fileInfo.name);
    for (var item in items) {
      if (item.isCaption && item.name.startsWith(prefix)) {
        captions.add(item);
      }
    }
    captions.sort(FileInfo.compare);
  }
}

abstract class _State extends MyState<MyVideoPage> {
  Client get client => widget.client;
  int get device => widget.device;
  String get root => widget.root;
  String get fullpath => widget.path;
  String get name => widget.name;
  List<Source> get videos => widget.videos;
  String get access => widget.access;
  final cancelToken = CancelToken();
  @override
  void dispose() {
    cancelToken.cancel();
    super.dispose();
  }

  getPath(String name) {
    return fullpath.endsWith('/') ? '$fullpath$name' : '$fullpath/$name';
  }
}

class _MyVideoPageState extends _State with _KeyboardComponent {
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

  _load() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: backOfAppBar(context),
        title: Text('$device $root $fullpath'),
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
  }
}
