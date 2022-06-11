import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:webpctv/pages/video/label.dart';
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
    children.addAll(
      <Widget>[
        Container(
          padding: const EdgeInsets.only(top: 10, left: 10),
          alignment: Alignment.topLeft,
          child: MyLabelWidget(
            label: ui.mode.name,
          ),
        ),
        Container(
          padding: const EdgeInsets.only(top: 10, left: 10),
          alignment: Alignment.topRight,
          child: MyLabelWidget(
            label: ui.source.name,
            fontSize: 24,
          ),
        ),
      ],
    );
    switch (ui.mode) {
      case Mode.none:
        break;
      case Mode.playlist:
        children.add(_buildPlaylist(context));
        break;
      case Mode.caption:
        if (ui.source.captions.isNotEmpty) {
          children.add(_buildCaptions(context));
        }
        break;
      case Mode.play:
        children.add(
          Container(
            padding: const EdgeInsets.only(top: 60, left: 40),
            alignment: Alignment.topLeft,
            child: MyLabelWidget(label: ui.play.name),
          ),
        );
        break;
    }

    if (value.isInitialized) {
      children.addAll(<Widget>[
        Container(
          padding: const EdgeInsets.only(bottom: 10, right: 10),
          alignment: Alignment.bottomRight,
          child: MyLabelWidget(
            label:
                '${durationToString(value.position)} / ${durationToString(value.duration)}',
            fontSize: 18,
          ),
        ),
      ]);
    }
    return Stack(
      children: children,
    );
  }

  Widget _buildCaptions(BuildContext context) {
    const padding = EdgeInsets.only(top: 60, left: 40);
    const fontSize = 24.0;
    if (ui.caption < 0) {
      return Container(
        padding: padding,
        alignment: Alignment.topLeft,
        child: const MyLabelWidget(
          label: 'close',
          fontSize: fontSize,
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
      padding: padding,
      alignment: Alignment.topLeft,
      child: MyLabelWidget(
        label: name,
        fontSize: fontSize,
      ),
    );
  }

  Widget _buildPlaylist(BuildContext context) {
    var start = ui.selected;
    var size = 1;
    final max = ui.videos.length - 1;
    var end = start;
    while (size != 3) {
      if (start > 0) {
        start--;
        size++;
        if (size == 3) {
          break;
        }
      }
      if (end < max) {
        end++;
        size++;
      }
    }

    final children = <Widget>[];
    for (var i = start; i <= end; i++) {
      children.add(MyLabelWidget(
        label: path.basenameWithoutExtension(ui.videos[i].name),
        fontSize: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        color: i != ui.selected ? null : Theme.of(context).primaryColor,
      ));
    }
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: 34,
        child: Wrap(
          alignment: WrapAlignment.center,
          clipBehavior: Clip.hardEdge,
          children: children,
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
