import 'package:dio/dio.dart';

import './rpc.dart';
// import './session.dart';
// import './categories.dart';

class Client extends RpcClient {
  Client({
    required String baseUrl,
    required String name,
    required String password,
  }) : super(
          dio: Dio()
            ..options.baseUrl = baseUrl.endsWith('/') ? baseUrl : baseUrl + '/',
          name: name,
          password: password,
        );
}
