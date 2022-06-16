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
  progress,
}
enum PlayMode {
  list,
  loop,
  single,
}
enum Progress {
  v0,
  v10,
  v20,
  v30,
  v40,
  v50,
  v60,
  v70,
  v80,
  v90,
}

class UI {
  bool _show;
  bool get show => _show;
  bool phone = false;
  bool locked = false;
  set show(bool v) {
    if (!v) {
      phone = false;
    }
    if (v == _show) {
      return;
    }
    _show = v;
    if (v) {
      resetSelected();
      progress = Progress.v0;
    }
  }

  Mode _mode = Mode.none;
  set mode(Mode mode) => _mode = mode;
  Mode get mode {
    final m = _mode;
    if (phone) {
      if (m == Mode.none || m == Mode.progress) {
        return Mode.playlist;
      }
    }
    return m;
  }

  PlayMode play = PlayMode.list;
  Progress progress = Progress.v0;
  final List<Source> videos;
  int caption = 0;
  final Source source;
  int selected = 0;
  UI({
    required bool show,
    required this.source,
    required this.videos,
  }) : _show = show {
    resetSelected();
  }
  void resetSelected() {
    for (var i = 0; i < videos.length; i++) {
      if (videos[i] == source) {
        selected = i;
      }
    }
  }

  void changeProgress(bool right) {
    const values = Progress.values;
    final last = values.length - 1;
    if (right) {
      for (var i = 0; i < last; i++) {
        if (progress == values[i]) {
          progress = values[i + 1];
          return;
        }
      }
      progress = values[0];
    } else {
      for (var i = last; i > 0; i--) {
        if (progress == values[i]) {
          progress = values[i - 1];
          return;
        }
      }
      progress = values[last];
    }
  }

  bool changeSelected(bool right) {
    if (right) {
      final max = videos.length - 1;
      if (selected < max) {
        selected++;
      }
      return true;
    } else if (selected > 0) {
      selected--;
      return true;
    }
    return false;
  }

  int changeMode(bool down) {
    const values = Mode.values;
    final last = phone ? values.length - 2 : values.length - 1;
    final min = phone ? 1 : 0;
    if (down) {
      for (var i = min; i < last; i++) {
        if (mode == values[i]) {
          mode = values[i + 1];
          return i + 1;
        }
      }
      mode = values[min];
      return min;
    } else {
      for (var i = last; i > min; i--) {
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
          caption = -1;
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

String durationToString(Duration duration) {
  final hours = duration.inDays * 24 + duration.inHours;
  final ms =
      '${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  if (hours > 0) {
    return '$hours:$ms';
  }
  return ms;
}
