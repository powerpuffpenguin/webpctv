import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock/wakelock.dart';

class WakelockService {
  static WakelockService? _instance;
  static WakelockService get instance => _instance ??= WakelockService._();
  WakelockService._();
  bool? _work;

  /// https://pub.dev/packages/wakelock
  bool get isSupported =>
      Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isMacOS ||
      Platform.isWindows;
  int _count = 0;
  bool _enable = false;
  void enable() {
    if (isSupported) {
      _count++;
      if (_count > 0) {
        _work = true;
      }
      _run();
    }
  }

  void disable() {
    if (isSupported) {
      _count--;
      if (_count < 1) {
        _work = false;
      }
      _run();
    }
  }

  final _mutex = Mutex();
  _run() async {
    bool lock = _mutex.tryLock();
    if (!lock) {
      return false;
    }
    try {
      while (_work != null) {
        final work = _work!;
        _work = null;
        if (work) {
          if (!_enable) {
            SystemChrome.setEnabledSystemUIMode(
              SystemUiMode.manual,
              overlays: [SystemUiOverlay.bottom],
            );
            _enable = true;
            await Wakelock.enable();
          }
        } else {
          if (_enable) {
            SystemChrome.setEnabledSystemUIMode(
              SystemUiMode.edgeToEdge,
            );
            _enable = false;
            await Wakelock.disable();
          }
        }
      }
    } finally {
      _mutex.unlock();
    }
  }
}

class Mutex {
  Completer<void>? _completer;
  Future<void> lock() async {
    if (_completer != null) {
      await _completer!.future;
    }
    _completer = Completer<void>();
  }

  bool tryLock() {
    if (_completer != null) {
      return false;
    }
    _completer = Completer<void>();
    return true;
  }

  void unlock() {
    final completer = _completer!;
    _completer = null;
    completer.complete();
  }
}
