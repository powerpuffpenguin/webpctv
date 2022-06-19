import 'dart:async';
import 'dart:io';

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
  void enable() {
    if (isSupported) {
      _work = true;
      _run();
    }
  }

  void disable() {
    if (isSupported) {
      _work = false;
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
          await Wakelock.enable();
        } else {
          await Wakelock.disable();
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
