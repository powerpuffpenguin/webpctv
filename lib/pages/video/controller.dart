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
    this.onChangedPlayMode,
    this.onChangedPlayList,
    this.onChangedLocked,
    this.onChangedCaption,
    this.onChangedFontsize,
    this.onChangedSeek,
    this.onChangeProgress,
  }) : super(key: key);
  final UI ui;
  final VideoPlayerController playerController;
  final VoidCallback? onChangedPlayMode;
  final ValueChanged<int>? onChangedPlayList;
  final VoidCallback? onChangedLocked;
  final ValueChanged<int>? onChangedCaption;
  final VoidCallback? onChangedFontsize;
  final ValueChanged<bool>? onChangedSeek;
  final VoidCallback? onChangeProgress;
  @override
  _MyControllerWidgetState createState() => _MyControllerWidgetState();
}

class _MyControllerWidgetState extends State<MyControllerWidget> {
  UI get ui => widget.ui;
  VideoPlayerController get controller => widget.playerController;
  bool _closed = false;
  @override
  void dispose() {
    _closed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!ui.show) {
      return Container();
    }
    final children = <Widget>[];
    final value = controller.value;
    children.addAll(
      <Widget>[
        ui.locked
            ? Container()
            : Container(
                padding: const EdgeInsets.only(top: 10, left: 10),
                alignment: Alignment.topLeft,
                child: MyLabelWidget(
                  label: ui.mode.name,
                  onTab: () {
                    setState(() {
                      ui.changeMode(true);
                    });
                  },
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
        Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 10),
          child: MyIconWidget(
            icon: ui.locked ? Icons.lock : Icons.lock_open_sharp,
            fontSize: 32,
            onTab: widget.onChangedLocked,
          ),
        ),
      ],
    );
    if (!ui.locked) {
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
        case Mode.fontsize:
          children.add(_buildFontsize(context));
          break;
        case Mode.play:
          children.add(
            Container(
              padding: const EdgeInsets.only(top: 60, left: 40),
              alignment: Alignment.topLeft,
              child: MyLabelWidget(
                label: ui.play.name,
                onTab: widget.onChangedPlayMode,
              ),
            ),
          );
          break;
        case Mode.progress:
          children.add(_buildProgress(context));
          break;
      }
    }

    if (value.isInitialized) {
      children.add(
        Container(
          padding: const EdgeInsets.only(bottom: 10, right: 10),
          alignment: Alignment.bottomRight,
          child: MyLabelWidget(
            label:
                '${durationToString(value.position)} / ${durationToString(value.duration)}',
            fontSize: 18,
          ),
        ),
      );
      if (ui.phone && !ui.locked) {
        children.addAll(
          <Widget>[
            Center(
              child: Transform.translate(
                offset: const Offset(-120, 0),
                child: MyIconWidget(
                  icon: Icons.keyboard_arrow_left,
                  fontSize: 58,
                  onTab: widget.onChangedSeek == null
                      ? null
                      : () => widget.onChangedSeek!(false),
                ),
              ),
            ),
            Center(
              child: value.isPlaying
                  ? MyIconWidget(
                      icon: Icons.pause,
                      fontSize: 72,
                      onTab: () => controller.pause().then((value) {
                        if (!_closed) {
                          setState(() {});
                        }
                      }),
                    )
                  : MyIconWidget(
                      icon: Icons.play_arrow,
                      fontSize: 72,
                      onTab: () => controller.play().then((value) {
                        if (!_closed) {
                          setState(() {});
                        }
                      }),
                    ),
            ),
            Center(
              child: Transform.translate(
                offset: const Offset(120, 0),
                child: MyIconWidget(
                  icon: Icons.keyboard_arrow_right,
                  fontSize: 58,
                  onTab: widget.onChangedSeek == null
                      ? null
                      : () => widget.onChangedSeek!(true),
                ),
              ),
            ),
          ],
        );
      }
    }
    return Stack(
      children: children,
    );
  }

  Widget _buildFontsize(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
      alignment: Alignment.topLeft,
      child: Wrap(
        clipBehavior: Clip.hardEdge,
        children: <Widget>[
          MyIconWidget(
            icon: Icons.keyboard_arrow_left_sharp,
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            onTab: () {
              if (ui.fontSizeSelected > UI.minFontSize) {
                setState(() {
                  ui.fontSizeSelected--;
                });
              }
            },
          ),
          Container(
            padding: const EdgeInsets.only(left: 4, top: 1, right: 4),
            child: MyLabelWidget(
              fontSize: 28,
              label: '${ui.fontSizeSelected}',
              onTab: widget.onChangedFontsize,
            ),
          ),
          MyIconWidget(
            icon: Icons.keyboard_arrow_right_sharp,
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            onTab: () {
              if (ui.fontSizeSelected < UI.maxFontSize) {
                setState(() {
                  ui.fontSizeSelected++;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCaption(BuildContext context, int i, bool selected) {
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

    return MyLabelWidget(
      label: name,
      fontSize: 24,
      color: selected ? Theme.of(context).primaryColor : null,
      onTab: widget.onChangedCaption == null
          ? null
          : () => widget.onChangedCaption!(i),
    );
  }

  Widget _buildCaptions(BuildContext context) {
    const padding = EdgeInsets.only(top: 60, left: 40);
    const fontSize = 24.0;
    var i = ui.caption;
    if (i > ui.source.captions.length) {
      i = ui.source.captions.length - 1;
    }
    if (ui.phone) {
      final children = <Widget>[];
      children.add(
        MyLabelWidget(
          label: 'close',
          fontSize: fontSize,
          color: i < 0 ? Theme.of(context).primaryColor : null,
          onTab: widget.onChangedCaption == null
              ? null
              : () {
                  widget.onChangedCaption!(-1);
                },
        ),
      );
      for (var index = 0; index < ui.source.captions.length; index++) {
        children.add(_buildCaption(context, index, i == index));
      }
      return Container(
        padding: padding,
        alignment: Alignment.topLeft,
        child: Wrap(
          clipBehavior: Clip.hardEdge,
          children: children,
        ),
      );
    }

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
        onTab: () {
          if (i != ui.selected) {
            setState(() {
              ui.selected = i;
            });
          } else {
            if (widget.onChangedPlayList != null) {
              widget.onChangedPlayList!(i);
            }
          }
        },
      ));
    }
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
      alignment: Alignment.topCenter,
      child: Wrap(
        alignment: WrapAlignment.center,
        clipBehavior: Clip.hardEdge,
        children: children,
      ),
    );
  }

  Widget _buildProgress(BuildContext context) {
    final value = controller.value;
    if (!value.isInitialized) {
      return Container();
    }
    const padding = EdgeInsets.only(top: 60, left: 40);
    var text = '0/10 00:00';
    const values = Progress.values;
    for (var i = 1; i < values.length; i++) {
      if (ui.progress == values[i]) {
        text = '$i/10 ${durationToString(value.duration * i ~/ 10)}';
        break;
      }
    }
    if (ui.phone) {
      return Container(
        padding: padding,
        alignment: Alignment.topLeft,
        child: Wrap(
          clipBehavior: Clip.hardEdge,
          children: <Widget>[
            MyIconWidget(
              icon: Icons.keyboard_arrow_left_sharp,
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              onTab: () {
                setState(() {
                  ui.changeProgress(false);
                });
              },
            ),
            Container(
              padding: const EdgeInsets.only(left: 4, top: 1, right: 4),
              child: MyLabelWidget(
                label: text,
                fontSize: 28,
                onTab: widget.onChangeProgress,
              ),
            ),
            MyIconWidget(
              icon: Icons.keyboard_arrow_right_sharp,
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              onTab: () {
                setState(() {
                  ui.changeProgress(true);
                });
              },
            ),
          ],
        ),
      );
    }
    return Container(
      padding: padding,
      alignment: Alignment.topLeft,
      child: MyLabelWidget(
        label: text,
        fontSize: 28,
      ),
    );
  }
}
