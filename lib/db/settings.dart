import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MySettings {
  static MySettings? _instance;
  static MySettings get instance {
    return _instance ??= MySettings._();
  }

  MySettings._();

  Future<String> getString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString('settings.$key');
      if (v is String) {
        return v;
      }
    } catch (e) {
      debugPrint('get string $key error: $e');
    }
    return '';
  }

  Future<void> setString(String key, String val) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('settings.$key', val);
    } catch (e) {
      debugPrint('set string $key error: $e');
    }
  }

  Future<int> getInt(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getInt('settings.$key');
      if (v is int) {
        return v;
      }
    } catch (e) {
      debugPrint('get int $key error: $e');
    }
    return 0;
  }

  Future<void> setInt(String key, int val) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('settings.$key', val);
    } catch (e) {
      debugPrint('set int $key error: $e');
    }
  }

  Future<int> getMode() => getInt('mode');
  Future<void> setMode(int val) => setInt('mode', val);
  Future<int> getCaption() => getInt('caption');
  Future<void> setCaption(int val) => setInt('caption', val);
  Future<int> getPlayMode() => getInt('playMode');
  Future<void> setPlayMode(int val) => setInt('playMode', val);
}
