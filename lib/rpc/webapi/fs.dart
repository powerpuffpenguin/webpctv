import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:webpctv/rpc/webapi/rpc.dart';
import 'package:path/path.dart' as path;

List<String> parseStrings(dynamic val) {
  if (val is List) {
    return val.map((e) => '$e').toList();
  }
  return <String>[];
}

class MountResponse {
  List<String> name;
  MountResponse.fromJson(Map<String, dynamic> json)
      : name = parseStrings(json["name"]);
}

class FileInfo {
  String name;
  bool isDir;
  FileInfo.fromJson(Map<String, dynamic> json)
      : name = json["name"],
        isDir = json["isDir"];
  @override
  String toString() {
    return "${isDir ? 'd' : '-'} $name";
  }

  static int compare(FileInfo l, FileInfo r) {
    final d0 = l.isDir ? 0 : 1;
    final d1 = r.isDir ? 0 : 1;
    final v = d0 - d1;
    if (v != 0) {
      return v;
    }
    return l.name.compareTo(r.name);
  }

  bool get isCaption {
    if (isDir) {
      return false;
    }
    final ext = path.extension(name).toLowerCase();
    return ext == '.vtt';
  }

  bool get isVideo {
    if (isDir) {
      return false;
    }
    final ext = path.extension(name).toLowerCase();
    return ext == '.webm' ||
        ext == '.mp4' ||
        ext == '.m4v' ||
        ext == '.mov' ||
        ext == '.avi' ||
        ext == '.flv' ||
        ext == '.wmv' ||
        ext == '.asf' ||
        ext == '.mpeg' ||
        ext == '.mpg' ||
        ext == '.vob' ||
        ext == '.mkv' ||
        ext == '.rm' ||
        ext == '.rmvb';
  }
}

class ListResponse {
  static List<FileInfo> _parseItems(dynamic v) {
    if (v is List) {
      return v.map((e) => FileInfo.fromJson(e)).toList();
    }
    return <FileInfo>[];
  }

  List<FileInfo> items;
  ListResponse.fromJson(Map<String, dynamic> json)
      : items = _parseItems(json["items"]);
}

mixin FileSystem on RpcClient {
  Future<MountResponse> mount(int device, {CancelToken? cancelToken}) async {
    final token = await getToken();
    return _mount(token, device, cancelToken: cancelToken);
  }

  Future<MountResponse> _mount(
    Token token,
    int device, {
    CancelToken? cancelToken,
    bool retry = true,
  }) async {
    try {
      final resp = await dio.get(
        'api/forward/v1/fs/mount',
        queryParameters: {
          'slave_id': device,
        },
        cancelToken: cancelToken,
        options: Options(headers: {
          'Authorization': 'Bearer ${token.access}',
        }),
      );
      return MountResponse.fromJson(resp.data);
    } on DioError catch (e) {
      if (retry && (e.response?.statusCode ?? 0) == 401) {
        try {
          token = await refreshToken(token: token);
          return _mount(
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

  Future<ListResponse> list(
    int device,
    String root,
    String path, {
    CancelToken? cancelToken,
  }) async {
    final token = await getToken();
    return _list(token, device, root, path, cancelToken: cancelToken);
  }

  Future<ListResponse> _list(
    Token token,
    int device,
    String root,
    String path, {
    CancelToken? cancelToken,
    bool retry = true,
  }) async {
    try {
      final resp = await dio.get(
        'api/forward/v1/fs/list',
        queryParameters: {
          'slave_id': device,
          'root': root,
          'path': path,
        },
        cancelToken: cancelToken,
        options: Options(headers: {
          'Authorization': 'Bearer ${token.access}',
        }),
      );
      return ListResponse.fromJson(resp.data);
    } on DioError catch (e) {
      if (retry && (e.response?.statusCode ?? 0) == 401) {
        try {
          token = await refreshToken(token: token);
          return _list(
            token,
            device,
            root,
            path,
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
