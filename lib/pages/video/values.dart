import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:webpctv/rpc/webapi/client.dart';
import 'package:webpctv/rpc/webapi/fs.dart';
import 'package:path/path.dart' as path;

enum Mode {
  none,
  playlist,
  caption,
  // list loop single
  play,
}
enum PlayMode {
  list,
  loop,
  single,
}

class UI {
  bool show;
  Mode mode = Mode.none;
  PlayMode play = PlayMode.list;
  final List<Source> videos;
  int caption = 0;
  final Source source;

  UI({
    required this.show,
    required this.source,
    required this.videos,
  });
  int changeMode(bool down) {
    const values = Mode.values;
    final last = values.length - 1;
    if (down) {
      for (var i = 0; i < last; i++) {
        if (mode == values[i]) {
          mode = values[i + 1];
          return i + 1;
        }
      }
      mode = values[0];
      return 0;
    } else {
      for (var i = last; i > 0; i--) {
        if (mode == values[i]) {
          mode = values[i - 1];
          return i - 1;
        }
      }
      mode = values[last];
      return last;
    }
  }

  int changePlayMode(bool right) {
    const values = PlayMode.values;
    final last = values.length - 1;
    if (right) {
      for (var i = 0; i < last; i++) {
        if (play == values[i]) {
          play = values[i + 1];
          return i + 1;
        }
      }
      play = values[0];
      return 0;
    } else {
      for (var i = last; i > 0; i--) {
        if (play == values[i]) {
          play = values[i - 1];
          return i - 1;
        }
      }
      play = values[last];
      return last;
    }
  }

  int changeCaption(bool right) {
    if (source.captions.isEmpty) {
      return caption;
    }
    if (right) {
      if (caption < 0) {
        caption = 0;
      } else {
        final val = caption + 1;
        if (val >= source.captions.length) {
          return caption;
        }
        caption = val;
        return val;
      }
    } else {
      if (caption < 0) {
        return caption;
      }
      final max = source.captions.length - 1;
      if (caption >= max) {
        caption = max - 1;
      } else {
        caption--;
      }
    }
    return caption;
  }

  FileInfo? getCaption() {
    if (source.captions.isEmpty || caption < 0) {
      return null;
    }
    var i = caption;
    final max = source.captions.length;
    if (i >= max) {
      i = max;
    }
    return source.captions[i];
  }
}

class Source {
  bool get isDir => fileInfo.isDir;
  String get name => fileInfo.name;
  final FileInfo fileInfo;
  final List<FileInfo> captions;
  final keys = <FileInfo, CaptionLoader>{};
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

class CaptionLoader {
  final Client client;
  final int device;
  final String root;
  final String path;
  CaptionLoader({
    required this.client,
    required this.device,
    required this.root,
    required this.path,
  });

  Completer<ClosedCaptionFile>? _completer;
  Future<ClosedCaptionFile> load() async {
    if (_completer != null) {
      return _completer!.future;
    }
    final completer = Completer<ClosedCaptionFile>();
    _completer = completer;
    try {
      final text = await client.download(device, root, path);
      final result = WebVTTCaptionFile(text);
      completer.complete(result);
    } catch (e) {
      debugPrint("CaptionLoader $e");
      _completer = null;
      completer.completeError(e);
    }
    return completer.future;
  }
}
