import 'package:dio/dio.dart';
import 'package:webpctv/rpc/webapi/fs.dart';
import 'package:webpctv/rpc/webapi/session.dart';

import './rpc.dart';

class Client extends RpcClient with FileSystem, Session {
  final String url;
  Client({
    required this.url,
    required String name,
    required String password,
    required List<int> devices,
  }) : super(
          dio: Dio()..options.baseUrl = url.endsWith('/') ? url : url + '/',
          name: name,
          password: password,
          devices: devices,
        );
}
