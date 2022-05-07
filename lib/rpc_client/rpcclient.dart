import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:lotus_pollen/rpc_client/exceptions.dart';

class RPCClient {
  RPCClient({
    this.url = 'http://127.0.0.1:10604',
    this.username = 'lotus',
    this.password = 'lotus',
    this.walletPassphrase = '',
  });

  String url;
  String username;
  String password;
  String walletPassphrase;

  int requestId = 0;

  final client = http.Client();

  Future<dynamic> call(final methodName, final params) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': _getAuthString(username, password)
    };

    final url = Uri.parse(this.url);
    final body = {
      'jsonrpc': '2.0',
      'id': '${requestId++}',
      'method': methodName,
      'params': params,
    };

    try {
      final response =
          await client.post(url, body: json.encode(body), headers: headers);

      switch (response.statusCode) {
        case HttpStatus.ok:
          final body = json.decode(response.body);
          if (body['error'] != null) {
            final error = body['error']['message'];
            throw RPCException(
              errorCode: error['code'],
              errorMsg: error['message'],
              method: methodName,
              params: params,
              errorType: '',
            );
          }
          return body['result'];
        case HttpStatus.unauthorized:
        case HttpStatus.forbidden:
          throw HTTPException(
            code: response.statusCode,
            message: 'Unauthorized',
          );
        case HttpStatus.internalServerError:
          final body = json.decode(response.body);
          if (body['error'] != null) {
            final error = body['error'];
            throw RPCException(
              errorCode: error['code'],
              errorMsg: error['message'],
              method: methodName,
              params: params,
              errorType: '',
            );
          }
          throw HTTPException(
            code: response.statusCode,
            message: 'Internal Server Error',
          );
        default:
          throw HTTPException(
            code: response.statusCode,
            message: 'Internal Server Error',
          );
      }
    } on SocketException catch (e) {
      throw HTTPException(
        code: 500,
        message: e.message,
      );
    } catch (e) {
      rethrow;
    }
  }
}

String _getAuthString(String username, String password) {
  final token = base64.encode(latin1.encode('$username:$password'));
  final authstr = 'Basic ' + token.trim();
  return authstr;
}
