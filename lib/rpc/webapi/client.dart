import 'package:dio/dio.dart';

import './rpc.dart';

class Client extends RpcClient {
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
