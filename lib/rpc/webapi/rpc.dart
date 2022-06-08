import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

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
  Token.fromJson(Map<String, dynamic> json)
      : access = json["access"],
        refresh = json["refresh"],
        accessDeadline = _parseInt(json["accessDeadline"]),
        refreshDeadline = _parseInt(json["refreshDeadline"]),
        deadline = _parseInt(json["deadline"]);
}

class SiginResponse {
  Token token;
  SiginResponse.fromJson(Map<String, dynamic> json)
      : token = Token.fromJson(json["token"]);
}

abstract class RpcClient {
  final Dio dio;
  final String name;
  final String password;
  RpcClient({
    required this.dio,
    required this.name,
    required this.password,
  });
  Token? _token;
  Completer<Token>? _siginCompleter;
  Future<Token> sigin({CancelToken? cancelToken}) async {
    var completer = _siginCompleter;
    if (completer != null) {
      return completer.future;
    }
    completer = Completer<Token>();
    _siginCompleter = completer;
    try {
      final token = await _sigin(cancelToken: cancelToken);
      _token = token;
      completer.complete(token);
    } catch (e) {
      _siginCompleter = null;
      completer.completeError(e);
    }
    return completer.future;
  }

  Future<Token> _sigin({CancelToken? cancelToken}) async {
    try {
      debugPrint('${DateTime.now()}');
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
      return SiginResponse.fromJson(jsonDecode(resp.data)).token;
    } on DioError catch (e) {
      throw Exception('${e.message} ${e.response?.data}');
    }
  }

  // Future<Token> get token async {
  //   var val = _token;
  //   if (val != null) {
  //     return val;
  //   }
  // }
}
