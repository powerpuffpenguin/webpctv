import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webpctv/db/data/history.dart';
import 'package:webpctv/db/db.dart';

class Record {
  final int device;
  final String root;
  final String path;
  final String name;
  final String _seek;
  bool _closed = false;
  bool get isClosed => _closed;
  bool get isNotClosed => _closed;
  Record({
    required this.device,
    required this.root,
    required this.path,
    required this.name,
  }) : _seek = Uri(queryParameters: <String, dynamic>{
          'slave_id': device.toString(),
          'root': root,
          'path': path,
        }).query;
  void close() {
    _closed = true;
  }

  Future<Duration?> getSeek() async {
    try {
      final helpers = await DB.helpers;
      if (isClosed) {
        return null;
      }
      final helper = helpers.seek;
      final duration = await helper.get(_seek, name);
      if (isClosed) {
        return null;
      }
      if (duration != null && duration > const Duration(seconds: 10)) {
        return duration;
      }
    } catch (e) {
      debugPrint("getSeek error: $e");
    }
    return null;
  }

  Duration _seekTo = Duration.zero;
  Duration _lastTo = Duration.zero;
  bool _seeking = false;
  FutureOr<void> setSeek(Duration duration) async {
    if (duration < const Duration(seconds: 10)) {
      return;
    }
    final diff = duration - _lastTo;
    if (diff > const Duration(seconds: -2) &&
        diff < const Duration(seconds: 2)) {
      return;
    }
    if (_seeking) {
      _seekTo = duration;
      return;
    }
    _seeking = true;
    _seekTo = Duration.zero;
    try {
      final helpers = await DB.helpers;
      if (isClosed) {
        return null;
      }
      final helper = helpers.seek;
      await helper.put(_seek, name, duration);
      _lastTo = duration;
    } catch (e) {
      debugPrint("setSeek error: $e");
    } finally {
      if (isNotClosed) {
        if (_seekTo == Duration.zero) {
          _seeking = false;
        } else {
          _seeking = false;
          setSeek(_seekTo);
        }
      }
    }
  }

  Future<void> setHistory() async {
    try {
      final helpers = await DB.helpers;
      if (isClosed) {
        return;
      }
      final helper = helpers.history;
      await helper.put(History(
        name: name,
        device: device,
        root: root,
        path: path,
      ));
    } catch (e) {
      debugPrint("setHistory error: $e");
    }
  }
}
