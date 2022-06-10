import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:webpctv/rpc/webapi/rpc.dart';

mixin Session on RpcClient {
  Future<String> downloadAccess(int device, {CancelToken? cancelToken}) async {
    final token = await getToken();
    return _downloadAccess(token, device, cancelToken: cancelToken);
  }

  Future<String> _downloadAccess(
    Token token,
    int device, {
    CancelToken? cancelToken,
    bool retry = true,
  }) async {
    try {
      final resp = await dio.post(
        'api/v1/sessions/download_access',
        cancelToken: cancelToken,
        options: Options(headers: {
          'Authorization': 'Bearer ${token.access}',
        }),
      );
      return resp.data["access"];
    } on DioError catch (e) {
      if (retry && (e.response?.statusCode ?? 0) == 401) {
        try {
          token = await refreshToken(token: token);
          return _downloadAccess(
            token,
            device,
            cancelToken: cancelToken,
            retry: false,
          );
        } catch (err) {
          debugPrint("retry $err");
          throw e;
        }
      }
      rethrow;
    }
  }
}
