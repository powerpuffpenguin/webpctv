import 'package:flutter/services.dart';

typedef KeyUpListener = void Function(KeyEvent);

/// 全局鍵盤 用於 快捷鍵 和 適配電視
class KeyEventService {
  static KeyEventService? _instance;
  static KeyEventService get instance => _instance ??= KeyEventService._();
  KeyEventService._();

  void add(KeyEvent evt) {
    if (evt is KeyUpEvent) {
      if (_keyUplisteners.isNotEmpty) {
        _keyUplisteners.last(evt);
      }
    }
  }

  final _keyUplisteners = <KeyUpListener>[];
  void addKeyUpListener(KeyUpListener listener) {
    _keyUplisteners.add(listener);
  }

  void removeKeyUpListener(KeyUpListener listener) {
    _keyUplisteners.remove(listener);
  }
}
