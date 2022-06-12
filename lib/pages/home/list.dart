import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webpctv/db/settings.dart';
import 'package:webpctv/pages/error.dart';
import 'package:webpctv/pages/video/values.dart';
import 'package:webpctv/pages/video/video.dart';
import 'package:webpctv/rpc/webapi/client.dart';
import 'package:webpctv/rpc/webapi/fs.dart';
import 'package:webpctv/widget/spin.dart';
import 'package:webpctv/widget/state.dart';

class MyListPage extends StatefulWidget {
  const MyListPage({
    Key? key,
    required this.client,
    required this.device,
    required this.root,
    required this.path,
  }) : super(key: key);
  final Client client;
  final int device;
  final String root;
  final String path;

  @override
  _MyListPageState createState() => _MyListPageState();
}

abstract class _State extends MyState<MyListPage> {
  Client get client => widget.client;
  int get device => widget.device;
  String get root => widget.root;
  String get fullpath => widget.path;
  final cancelToken = CancelToken();
  final keys = <String, Source>{};
  final source = <Source>[];
  final videos = <Source>[];
  @override
  void dispose() {
    cancelToken.cancel();
    super.dispose();
  }

  getPath(String name) {
    return fullpath.endsWith('/') ? '$fullpath$name' : '$fullpath/$name';
  }

  _openList(String name) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MyListPage(
          client: client,
          device: device,
          root: root,
          path: getPath(name),
        ),
      ),
    );
  }

  _openVide(String name) async {
    Source? source;
    for (var item in videos) {
      if (item.name == name) {
        source = item;
        break;
      }
    }
    if (source == null) {
      return;
    }
    setState(() {
      disabled = true;
    });
    try {
      final settings = MySettings.instance;
      var i = await settings.getMode();
      var mode = Mode.none;
      if (i < Mode.values.length) {
        mode = Mode.values[i];
      }
      checkAlive();
      final caption = await settings.getCaption();
      checkAlive();
      i = await settings.getPlayMode();
      var playMode = PlayMode.list;
      if (i < PlayMode.values.length) {
        playMode = PlayMode.values[i];
      }
      checkAlive();

      final access =
          await client.downloadAccess(device, cancelToken: cancelToken);
      aliveSetState(() {
        debugPrint('access $access');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MyVideoPage(
              client: client,
              device: device,
              root: root,
              path: fullpath,
              source: source!,
              videos: videos,
              access: access,
              mode: mode,
              caption: caption,
              playMode: playMode,
            ),
          ),
        );
        disabled = false;
      });
    } catch (e) {
      if (isNotClosed) {
        BotToast.showText(text: '$e');
      }
    }
  }
}

class _MyListPageState extends _State with _KeyboardComponent {
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
      final resp =
          await client.list(device, root, fullpath, cancelToken: cancelToken);
      checkAlive();
      setState(() {
        for (var item in resp.items) {
          if (item.isDir) {
            source.add(Source(fileInfo: item, captions: const <FileInfo>[]));
            continue;
          } else if (item.isVideo) {
            final node = Source(fileInfo: item, captions: <FileInfo>[]);
            keys[item.name] = node;
            source.add(node);
          }
        }
        source.sort(Source.compare);
        for (var s in source) {
          if (!s.isDir) {
            s.addCaptions(resp.items);
            videos.add(s);
          }
        }
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
        title: Text('$device $root $fullpath'),
      ),
      body: ListView(
        children: source
            .map(
              (item) => FocusScope(
                node: focusScopeNode,
                child: ListTile(
                  focusNode: createFocusNode(
                      '${item.isDir ? 'dir' : 'video'}_${item.name}'),
                  leading: item.isDir
                      ? const Icon(Icons.folder)
                      : const Icon(Icons.video_collection),
                  title: Text(item.name),
                  onTap: disabled
                      ? null
                      : () {
                          if (item.isDir) {
                            _openList(item.name);
                          } else {
                            _openVide(item.name);
                          }
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
    if (enabled) {
      if (id.startsWith('dir_')) {
        _openList(id.substring('dir_'.length));
      } else if (id.startsWith('video_')) {
        _openVide(id.substring('video_'.length));
      }
    }
  }
}
