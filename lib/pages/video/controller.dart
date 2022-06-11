import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import './values.dart';
import 'package:path/path.dart' as path;

class MyControllerWidget extends StatefulWidget {
  const MyControllerWidget({
    Key? key,
    required this.playerController,
    required this.ui,
  }) : super(key: key);
  final UI ui;
  final VideoPlayerController playerController;
  @override
  _MyControllerWidgetState createState() => _MyControllerWidgetState();
}

class _MyControllerWidgetState extends State<MyControllerWidget> {
  UI get ui => widget.ui;
  VideoPlayerController get controller => widget.playerController;
  @override
  Widget build(BuildContext context) {
    if (!ui.show) {
      return Container();
    }
    final children = <Widget>[];
    final value = controller.value;

    children.add(
      Container(
        padding: const EdgeInsets.only(top: 10, left: 10),
        alignment: Alignment.topLeft,
        child: Text(
          ui.mode.name,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
    switch (ui.mode) {
      case Mode.none:
        break;
      case Mode.playlist:
        break;
      case Mode.caption:
        if (ui.source.captions.isNotEmpty) {
          children.add(_buildCaptions(context));
        }
        break;
      case Mode.play:
        children.add(
          Container(
            padding: const EdgeInsets.only(top: 40, left: 20),
            alignment: Alignment.topLeft,
            child: Text(
              ui.play.name,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        );
        break;
    }

    if (value.isInitialized) {
      children.addAll(<Widget>[
        Container(
          padding: const EdgeInsets.only(bottom: 10, right: 10),
          alignment: Alignment.bottomRight,
          child: Text(
            '${durationToString(value.position)} / ${durationToString(value.duration)}',
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ]);
    }
    return Stack(
      children: children,
    );
  }

  Widget _buildCaptions(BuildContext context) {
    if (ui.caption < 0) {
      return Container(
        padding: const EdgeInsets.only(top: 40, left: 20),
        alignment: Alignment.topLeft,
        child: const Text(
          'close',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      );
    }
    var i = ui.caption;
    if (i > ui.source.captions.length) {
      i = ui.source.captions.length - 1;
    }
    final item = ui.source.captions[i];
    var name = path.basenameWithoutExtension(item.name);
    final prefix = path.basenameWithoutExtension(ui.source.name);
    if (name.startsWith(prefix)) {
      name = name.substring(prefix.length);
      if (name.startsWith('.')) {
        name = name.substring(1);
      }
      if (name == '') {
        name = '$i';
      }
    } else {
      name = '$i';
    }
    return Container(
      padding: const EdgeInsets.only(top: 40, left: 20),
      alignment: Alignment.topLeft,
      child: Text(
        name,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
    );
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
