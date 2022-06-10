import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:webpctv/rpc/webapi/client.dart';
import 'package:webpctv/rpc/webapi/fs.dart';
import 'package:webpctv/widget/state.dart';
import 'package:path/path.dart' as path;

enum Mode {
  None,
}

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
  late VideoPlayerController playerController;
  Mode mode = Mode.None;
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

  bool showController = false;
  @override
  void initState() {
    super.initState();

    playerController = VideoPlayerController.network(
      getURL(name),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
      ),
    )
      ..initialize().then((_) {
        playerController.play();
      })
      ..addListener(() {
        if (isNotClosed) {
          _listener();
        }
      });
  }

  _listener() {
    setState(() {});
  }

  @override
  void dispose() {
    cancelToken.cancel();
    playerController.dispose();
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
    return WillPopScope(
      onWillPop: () async {
        if (showController && playerController.value.isInitialized) {
          setState(() {
            showController = false;
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
            showController
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
      if (value.isInitialized) {
        _selected(value);
      }
    } else if (evt.logicalKey == LogicalKeyboardKey.arrowDown ||
        evt.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (playerController.value.isInitialized) {
        if (showController) {
        } else {
          setState(() {
            showController = true;
          });
        }
      }
    }
  }

  _selected(VideoPlayerValue value) {
    if (!showController) {
      if (value.isPlaying) {
        playerController.pause();
      } else {
        playerController.play();
      }
      return;
    }
    switch (mode) {
      case Mode.None:
        if (value.isPlaying) {
          playerController.pause();
        } else {
          playerController.play();
        }
        break;
    }
  }
}
