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

  Future<String> download(
    int device,
    String root,
    String path, {
    CancelToken? cancelToken,
  }) async {
    final token = await getToken();
    return _download(token, device, root, path, cancelToken: cancelToken);
  }

  Future<String> _download(
    Token token,
    int device,
    String root,
    String path, {
    CancelToken? cancelToken,
    bool retry = true,
  }) async {
    try {
      final resp = await dio.get(
        'api/forward/v1/fs/download',
        queryParameters: {
          'slave_id': device,
          'root': root,
          'path': path,
        },
        cancelToken: cancelToken,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${token.access}',
          },
          responseType: ResponseType.plain,
        ),
      );
      return resp.data;
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
