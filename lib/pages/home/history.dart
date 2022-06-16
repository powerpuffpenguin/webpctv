import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webpctv/db/data/history.dart';
import 'package:webpctv/db/db.dart';
import 'package:webpctv/db/settings.dart';
import 'package:webpctv/pages/error.dart';
import 'package:webpctv/pages/video/values.dart';
import 'package:webpctv/pages/video/video.dart';
import 'package:webpctv/rpc/webapi/client.dart';
import 'package:webpctv/rpc/webapi/fs.dart';
import 'package:webpctv/widget/confirmation_dialog.dart';
import 'package:webpctv/widget/state.dart';

class _FocuesID {
  _FocuesID._();
  static const clearHistory = 'clear_history';
  static const clearProgress = 'clear_progress';
}

class MyHistoryPage extends StatefulWidget {
  const MyHistoryPage({
    Key? key,
    required this.client,
  }) : super(key: key);
  final Client client;

  @override
  _MyHistoryPageState createState() => _MyHistoryPageState();
}

abstract class _State extends MyState<MyHistoryPage> {
  final source = <History>[];
  final cancelToken = CancelToken();
  @override
  void dispose() {
    cancelToken.cancel();
    super.dispose();
  }

  _openHistory(History history) async {
    setState(() {
      disabled = true;
    });
    try {
      final resp = await widget.client.list(
        history.device,
        history.root,
        history.path,
        cancelToken: cancelToken,
      );
      checkAlive();
      final videos = <Source>[];
      final keys = <String, Source>{};
      for (var item in resp.items) {
        if (item.isVideo) {
          final node = Source(fileInfo: item, captions: <FileInfo>[]);
          keys[item.name] = node;
          videos.add(node);
        }
      }
      videos.sort(Source.compare);
      for (var s in videos) {
        s.addCaptions(resp.items);
      }
      if (videos.isEmpty) {
        throw Exception("not found any video");
      }

      Source? source;
      for (var item in videos) {
        source ??= item;
        if (history.name == item.name) {
          source = item;
          break;
        }
      }
      await _openSource(
        history: history,
        source: source!,
        videos: videos,
      );
    } catch (e) {
      if (isNotClosed) {
        BotToast.showText(text: "$e");
      }
    } finally {
      aliveSetState(() {
        disabled = false;
      });
    }
  }

  Future<void> _openSource({
    required History history,
    required Source source,
    required List<Source> videos,
  }) async {
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

    final access = await widget.client
        .downloadAccess(history.device, cancelToken: cancelToken);
    checkAlive();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MyVideoPage(
          client: widget.client,
          device: history.device,
          root: history.root,
          path: history.path,
          source: source,
          videos: videos,
          access: access,
          mode: mode,
          caption: caption,
          playMode: playMode,
          locked: false,
        ),
      ),
    );
  }

  _clearHistory() async {
    setState(() {
      disabled = true;
    });
    try {
      final ok = await showConfirmationDialog(
        context,
        const Text('clear history'),
        const Text('Are you sure you want to clear history?'),
      );
      checkAlive();
      if (!ok) {
        return;
      }
      final helpers = await DB.helpers;
      checkAlive();
      await helpers.history.clear();
      aliveSetState(() {
        BotToast.showText(text: 'clear history success');
        source.clear();
      });
    } catch (e) {
      if (isNotClosed) {
        BotToast.showText(text: '$e');
      }
    } finally {
      aliveSetState(() {
        disabled = false;
      });
    }
  }

  _clearProgress() async {
    setState(() {
      disabled = true;
    });
    try {
      final ok = await showConfirmationDialog(
        context,
        const Text('clear play progress'),
        const Text('Are you sure you want to clear play progress?'),
      );
      checkAlive();
      if (!ok) {
        return;
      }
      final helpers = await DB.helpers;
      checkAlive();
      await helpers.seek.clear();
      BotToast.showText(text: 'clear play progress success');
    } catch (e) {
      if (isNotClosed) {
        BotToast.showText(text: '$e');
      }
    } finally {
      aliveSetState(() {
        disabled = false;
      });
    }
  }
}

class _MyHistoryPageState extends _State with _KeyboardComponent {
  @override
  void initState() {
    super.initState();

    listenKeyUp(onKeyUp);
    Future.value().then((value) {
      if (isNotClosed) {
        _load();
      }
    });
  }

  _load() async {
    try {
      final helpers = await DB.helpers;
      checkAlive();
      final items = await helpers.history.list();
      checkAlive();
      if (items != null && items.isNotEmpty) {
        setState(() {
          source.addAll(items);
        });
      }
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
        leading: Container(),
        leadingWidth: 0,
        title: const Text('Play History'),
        actions: [
          FocusScope(
            node: focusScopeNode,
            child: IconButton(
              focusNode: createFocusNode(_FocuesID.clearHistory),
              icon: const Icon(Icons.delete_forever),
              tooltip: 'clear history',
              onPressed: disabled ? null : _clearHistory,
            ),
          ),
          FocusScope(
            node: focusScopeNode,
            child: IconButton(
              focusNode: createFocusNode(_FocuesID.clearProgress),
              icon: const Icon(Icons.auto_delete_outlined),
              tooltip: 'clear progress',
              onPressed: disabled ? null : _clearProgress,
            ),
          ),
        ],
      ),
      body: ListView.builder(
          itemCount: source.length,
          itemBuilder: (context, i) {
            final item = source[i];
            return FocusScope(
              node: focusScopeNode,
              child: ListTile(
                focusNode: createFocusNode('index_$i', data: item),
                leading: const Icon(Icons.play_circle),
                title: Text(item.name),
                subtitle: Text(
                  '${item.device} ${item.path}',
                ),
                onTap: disabled
                    ? null
                    : () {
                        _openHistory(item);
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
    } else if (evt.logicalKey == LogicalKeyboardKey.arrowLeft ||
        evt.logicalKey == LogicalKeyboardKey.arrowRight) {
      final focused = focusedNode();
      final id = focused?.id ?? '';
      if (id.startsWith('index_')) {
        setFocus(_FocuesID.clearProgress);
      }
    }
  }

  _selectFocused(MyFocusNode focused) {
    final id = focused.id;
    if (enabled) {
      if (id == _FocuesID.clearHistory) {
        _clearHistory();
      } else if (id == _FocuesID.clearProgress) {
        _clearProgress();
      } else if (id.startsWith('index_') && focused.data is History) {
        _openHistory(focused.data);
      }
    }
  }
}
