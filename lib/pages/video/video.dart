import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:webpctv/db/settings.dart';
import 'package:webpctv/rpc/webapi/client.dart';
import 'package:webpctv/widget/state.dart';
import './controller.dart';
import './values.dart';

class MyVideoPage extends StatefulWidget {
  const MyVideoPage({
    Key? key,
    required this.client,
    required this.device,
    required this.root,
    required this.path,
    required this.source,
    required this.videos,
    required this.access,
    this.showController = false,
    required this.mode,
    required this.caption,
    required this.playMode,
  }) : super(key: key);
  final Client client;
  final int device;
  final String root;
  final String path;
  final Source source;
  final List<Source> videos;
  final String access;
  final bool showController;

  final Mode mode;
  final int caption;
  final PlayMode playMode;

  @override
  _MyVideoPageState createState() => _MyVideoPageState();
}

abstract class _State extends MyState<MyVideoPage> {
  Client get client => widget.client;
  int get device => widget.device;
  String get root => widget.root;
  String get fullpath => widget.path;
  Source get source => widget.source;
  List<Source> get videos => widget.videos;
  String get access => widget.access;
  final cancelToken = CancelToken();
  late VideoPlayerController playerController;
  getURL(String name) {
    final baseUrl = client.dio.options.baseUrl;
    final query = Uri(queryParameters: <String, dynamic>{
      'slave_id': device.toString(),
      'root': root,
      'path': getPath(name),
      'access_token': access,
    }).query;
    return '${baseUrl}api/forward/v1/fs/download_access?$query';
  }

  UI? _ui;
  UI get ui {
    var m = _ui;
    if (m == null) {
      m = UI(
        show: widget.showController,
        source: source,
        videos: videos,
      );
      m.mode = widget.mode;
      m.caption = widget.caption;
      m.play = widget.playMode;

      _ui = m;
    }
    return m;
  }

  @override
  void initState() {
    super.initState();

    playerController = VideoPlayerController.network(
      getURL(source.name),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
      ),
    )
      ..initialize().then((_) {
        playerController.play();
        setCaption();
      })
      ..addListener(() {
        if (isNotClosed) {
          _listener();
        }
      });
  }

  void setCaption() {
    if (!playerController.value.isInitialized) {
      return;
    }
    final fileinfo = ui.getCaption();
    if (fileinfo == null) {
      playerController.setClosedCaptionFile(null);
    } else {
      var loader = source.keys[fileinfo];
      if (loader == null) {
        loader = CaptionLoader(
          client: client,
          device: device,
          root: root,
          path: getPath(fileinfo.name),
        );
        source.keys[fileinfo] = loader;
      }
      playerController.setClosedCaptionFile(loader.load());
    }
  }

  bool _replay = false;
  _listener() {
    var value = playerController.value;
    if (!value.isInitialized || value.isPlaying) {
      setState(() {});
      return;
    }
    if (value.position == value.duration) {
      switch (ui.play) {
        case PlayMode.single:
          break;
        case PlayMode.loop:
          _playMore();
          break;
        case PlayMode.list:
          _playNext();
          break;
      }
    }
  }

  _playMore() async {
    if (_replay) {
      return;
    }
    _replay = true;
    try {
      await playerController.seekTo(const Duration());
      await playerController.play();
    } catch (e) {
      debugPrint("playMore err: $e");
    } finally {
      _replay = false;
    }
  }

  _playIndex(int i) async {
    if (_replay) {
      return;
    }
    _replay = true;
    try {
      if (i >= 0 && i < videos.length) {
        final source = videos[i];
        if (source != ui.source) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => MyVideoPage(
                client: client,
                device: device,
                root: root,
                path: fullpath,
                source: source,
                videos: videos,
                access: access,
                showController: ui.show,
                mode: ui.mode,
                caption: ui.caption,
                playMode: ui.play,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("_playIndex $i err: $e");
    } finally {
      _replay = false;
    }
  }

  _playNext() async {
    if (_replay) {
      return;
    }
    _replay = true;
    try {
      for (var i = 0; i < videos.length - 1; i++) {
        if (source == videos[i]) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => MyVideoPage(
                client: client,
                device: device,
                root: root,
                path: fullpath,
                source: videos[i + 1],
                videos: videos,
                access: access,
                showController: ui.show,
                mode: ui.mode,
                caption: ui.caption,
                playMode: ui.play,
              ),
            ),
          );
          return;
        }
      }
    } catch (e) {
      debugPrint("_playNext err: $e");
    } finally {
      _replay = false;
    }
  }

  @override
  void dispose() {
    cancelToken.cancel();
    playerController.dispose();
    super.dispose();
  }

  String getPath(String name) {
    return fullpath.endsWith('/') ? '$fullpath$name' : '$fullpath/$name';
  }

  togglePlay() {
    final value = playerController.value;
    if (value.isInitialized) {
      if (value.isPlaying) {
        playerController.pause();
      } else {
        playerController.play();
      }
    }
  }

  Duration _seekTo = Duration.zero;
  bool _seeking = false;
  void seekPlay(bool right) {
    final value = playerController.value;
    if (!value.isInitialized) {
      return;
    }
    if (right) {
      _seekTo += const Duration(seconds: 10);
    } else {
      _seekTo -= const Duration(seconds: 10);
    }
    if (_seeking || _seekTo == Duration.zero) {
      return;
    }
    final position = value.position;
    final to = position + _seekTo;
    _seekTo = Duration.zero;
    _seekToDuration(to);
  }

  void _seekToDuration(Duration to) async {
    _seeking = true;
    try {
      final value = playerController.value;
      if (to < Duration.zero) {
        to = Duration.zero;
      } else if (to > value.duration) {
        to = value.duration;
      }
      final diff = to - value.position;
      if (diff < const Duration(seconds: 1) &&
          diff > const Duration(seconds: -1)) {
        return;
      }
      await playerController.seekTo(to);
    } catch (e) {
      if (isNotClosed) {
        debugPrint("seekTo $e");
      }
    } finally {
      if (isNotClosed) {
        if (_seekTo == Duration.zero) {
          _seeking = false;
        } else {
          final position = playerController.value.position;
          final to = position + _seekTo;
          _seekTo = Duration.zero;
          _seekToDuration(to);
        }
      }
    }
  }
}

class _MyVideoPageState extends _State with _KeyboardComponent {
  @override
  void initState() {
    super.initState();

    listenKeyUp(onKeyUp);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (ui.show) {
          setState(() {
            ui.show = false;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: Container(
          alignment: Alignment.center,
          color: Colors.black,
          child: playerController.value.isInitialized
              ? _buildVideo(context)
              : _buildLoading(context),
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return const Center(
      child: SizedBox(
        height: 60,
        child: FittedBox(
          child: CupertinoActivityIndicator(),
        ),
      ),
    );
  }

  Widget _buildVideo(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: Colors.black,
      child: AspectRatio(
        aspectRatio: playerController.value.aspectRatio,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            VideoPlayer(playerController),
            MyControllerWidget(playerController: playerController, ui: ui),
            ClosedCaption(
              text: playerController.value.caption.text,
            ),
            ui.show
                ? VideoProgressIndicator(playerController, allowScrubbing: true)
                : Container(),
          ],
        ),
      ),
    );
  }
}

mixin _KeyboardComponent on _State {
  void onKeyUp(KeyEvent evt) {
    final value = playerController.value;
    if (evt.logicalKey == LogicalKeyboardKey.select) {
      _selected(value);
    } else if (evt.logicalKey == LogicalKeyboardKey.arrowDown ||
        evt.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (ui.show) {
        setState(() {
          final val =
              ui.changeMode(evt.logicalKey == LogicalKeyboardKey.arrowDown);
          MySettings.instance.setMode(val);
        });
      } else {
        setState(() {
          ui.show = true;
        });
      }
    } else if (evt.logicalKey == LogicalKeyboardKey.arrowLeft ||
        evt.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (ui.show) {
        _changeValue(evt.logicalKey == LogicalKeyboardKey.arrowRight);
      } else {
        seekPlay(evt.logicalKey == LogicalKeyboardKey.arrowRight);
      }
    }
  }

  _selected(VideoPlayerValue value) {
    if (!ui.show) {
      togglePlay();
      return;
    }
    // controller
    switch (ui.mode) {
      case Mode.none:
        togglePlay();
        break;
      case Mode.playlist:
        _playIndex(ui.selected);
        break;
      case Mode.play:
        break;
      case Mode.caption:
        break;
    }
  }

  _changeValue(bool right) {
    switch (ui.mode) {
      case Mode.none:
        seekPlay(right);
        break;
      case Mode.playlist:
        if (ui.changeSelected(right)) {
          setState(() {});
        }
        break;
      case Mode.play:
        setState(() {
          final val = ui.changePlayMode(right);
          MySettings.instance.setPlayMode(val);
        });
        break;
      case Mode.caption:
        _changeCaption(right);
        break;
    }
  }

  _changeCaption(bool right) {
    final old = ui.caption;
    final val = ui.changeCaption(right);
    if (old != val) {
      setState(() {
        setCaption();
        MySettings.instance.setCaption(val);
      });
    }
  }
}
