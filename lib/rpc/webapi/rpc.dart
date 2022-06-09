import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class Token {
  static int _parseInt(dynamic val) {
    if (val is int) {
      return val;
    } else if (val is String) {
      return int.parse(val);
    }
    return 0;
  }

  String access;
  String refresh;
  int accessDeadline;
  int refreshDeadline;
  int deadline;
  bool deleted = false;
  Token.fromJson(Map<String, dynamic> json)
      : access = json["access"],
        refresh = json["refresh"],
        accessDeadline = _parseInt(json["accessDeadline"]),
        refreshDeadline = _parseInt(json["refreshDeadline"]),
        deadline = _parseInt(json["deadline"]) {
    debugPrint("Token.access: $access");
    debugPrint("Token.refresh: $access");
  }
}

class SiginResponse {
  Token token;
  SiginResponse.fromJson(Map<String, dynamic> json)
      : token = Token.fromJson(json["token"]);
}

class RefreshResponse {
  Token token;
  RefreshResponse.fromJson(Map<String, dynamic> json)
      : token = Token.fromJson(json["token"]);
}

abstract class RpcClient {
  final Dio dio;
  final String name;
  final String password;
  final List<int> devices;
  RpcClient({
    required this.dio,
    required this.name,
    required this.password,
    required this.devices,
  });
  Token? _token;
  Future<Token> sigin({CancelToken? cancelToken}) async {
    final token = await _sigin(cancelToken: cancelToken);
    _token = token;
    return token;
  }

  Future<Token> _sigin({CancelToken? cancelToken}) async {
    try {
      final platform = Platform.operatingSystem;
      final unix = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      var pwd = md5.convert(utf8.encode(password)).toString();
      pwd = md5.convert(utf8.encode('$platform.$pwd.$unix')).toString();
      final resp = await dio.post(
        'api/v1/sessions',
        data: <String, dynamic>{
          'platform': platform,
          'name': name,
          'password': pwd,
          'unix': unix,
        },
        cancelToken: cancelToken,
      );
      return SiginResponse.fromJson(resp.data).token;
    } on DioError catch (e) {
      throw Exception('${e.message} ${e.response?.data}');
    }
  }

  Future<Token> refresh(Token token) async {
    try {
      final resp = await dio.post(
        'api/v1/sessions/refresh',
        data: <String, dynamic>{
          'access': token.access,
          'refresh': token.refresh,
        },
      );
      return RefreshResponse.fromJson(resp.data).token;
    } on DioError catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode == 401) {
        return await sigin();
      } else {
        throw Exception('${e.message} ${e.response?.data}');
      }
    }
  }

  Completer<Token>? _completer;
  Future<Token> refreshToken({Token? token}) async {
    var completer = _completer;
    if (completer != null) {
      return completer.future;
    }
    completer = Completer<Token>();
    _completer = completer;
    try {
      if (token == null) {
        final result = await sigin();
        _token = result;
        _completer = null;
        completer.complete(result);
      } else {
        final result = await refresh(token);
        _token = result;
        _completer = null;
        completer.complete(result);
      }
    } catch (e) {
      _completer = null;
      completer.completeError(e);
    }
    return completer.future;
  }

  Future<Token> token() async {
    var completer = _completer;
    if (completer != null) {
      return completer.future;
    }

    var result = _token;
    if (result == null) {
      throw Exception('token null');
    } else if (result.deleted) {
      return refreshToken();
    }
    final deadline = DateTime.now()
            .add(const Duration(minutes: -5))
            .millisecondsSinceEpoch ~/
        1000;
    if (result.accessDeadline < deadline) {
      if (result.refreshDeadline < deadline) {
        if (result.deadline != 0 && result.deadline < deadline) {
          result = await refreshToken(token: result);
        } else {
          result = await refreshToken();
        }
      } else {
        result = await refreshToken();
      }
    }
    return result;
  }
}
