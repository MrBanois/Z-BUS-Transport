import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// A failed API call, carrying the server's `detail` when it supplied one.
///
/// The UI shows [message] verbatim, so the server owns the wording of every
/// validation failure the user sees.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.detail, this.field});

  /// Always non-empty and safe to display.
  final String message;

  /// HTTP status, or null when the request never completed.
  final int? statusCode;

  /// The server's `detail` string, when present.
  final String? detail;

  /// The form field the server rejected, when it said so.
  ///
  /// Endpoints that can point at one control return `detail` as
  /// `{"message": ..., "field": ...}`; the rest return a bare string and leave
  /// this null, in which case the caller shows [message] as a banner. This
  /// exists so the UI never has to pattern match on wording.
  final String? field;

  /// 409 means the address is taken, which the register form renders under the
  /// email field rather than as a banner.
  bool get isConflict => statusCode == 409;

  /// 401 means the credentials were rejected.
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// Raised when the server could not be reached at all.
class ApiUnreachable extends ApiException {
  ApiUnreachable(super.message);
}

/// Thin JSON transport over the FastAPI server.
///
/// This is the only place that knows the base URL or the wire format. It does no
/// authorization and holds no session: the caller supplies the permission mask
/// it already has.
class ApiClient {
  ApiClient({http.Client? client, this.baseUrl = defaultBaseUrl})
    : _client = client ?? http.Client();

  /// Matches `python ./Main.py`, which serves on port 8000.
  ///
  /// Override for a device or a deployed host without editing code:
  /// `--dart-define=ZBUS_API=http://10.0.2.2:8000`.
  static const String defaultBaseUrl = String.fromEnvironment(
    'ZBUS_API',
    defaultValue: 'http://127.0.0.1:8000',
  );

  final http.Client _client;
  final String baseUrl;
  final Duration timeout = const Duration(seconds: 12);

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<Object?> _send(
    Future<http.Response> Function() request,
    String what,
  ) async {
    late final http.Response response;
    try {
      response = await request().timeout(timeout);
    } on TimeoutException {
      throw ApiUnreachable(
        'The server did not respond. Check that it is running.',
      );
    } on http.ClientException catch (e) {
      // Thrown for a refused connection, a DNS failure and an XMLHttpRequest
      // error alike. dart:io's SocketException is deliberately not caught
      // here: importing dart:io would break the web build, and every case it
      // covers already arrives as a ClientException.
      throw ApiUnreachable(
        'Cannot reach the server at $baseUrl. ${e.message}'.trim(),
      );
    } on FormatException {
      throw ApiUnreachable(
        'The server at $baseUrl sent a malformed response.',
      );
    }

    return _decode(response, what);
  }

  Object? _decode(http.Response response, String what) {
    final status = response.statusCode;
    Object? body;
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body);
      } on FormatException {
        // A proxy or an unhandled server error can return HTML. Do not surface
        // that as a raw parse failure; report the status instead.
        body = null;
      }
    }

    if (status >= 200 && status < 300) return body;

    // FastAPI's `detail` is whatever the route put in its HTTPException: a
    // string for most routes, an object naming the offending field where the
    // route can identify one, and a list of objects for a schema validation
    // failure. Only the first two carry a usable message.
    String? message;
    String? field;
    if (body is Map<String, dynamic>) {
      final detail = body['detail'];
      if (detail is String && detail.isNotEmpty) {
        message = detail;
      } else if (detail is Map<String, dynamic>) {
        final text = detail['message'];
        if (text is String && text.isNotEmpty) message = text;
        final named = detail['field'];
        if (named is String && named.isNotEmpty) field = named;
      }
    }
    message ??= _statusMessage(status, what);
    throw ApiException(
      message,
      statusCode: status,
      detail: message,
      field: field,
    );
  }

  String _statusMessage(int status, String what) => switch (status) {
    400 => '$what was rejected by the server.',
    401 => 'Invalid credentials',
    404 => 'The server has no $what endpoint.',
    409 => '$what conflicts with an existing record.',
    >= 500 => 'The server failed to handle $what.',
    _ => '$what failed ($status).',
  };

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
    String what,
  ) async {
    final decoded = await _send(
      () => _client.post(
        _uri(path),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
      what,
    );
    // A list or a scalar here means the server does not answer this route the
    // way the client expects: a contract error, not user error.
    if (decoded is Map<String, dynamic>) return decoded;
    throw ApiException('$what returned an unexpected response.');
  }

  Future<Map<String, dynamic>> _put(
    String path,
    Map<String, dynamic> body,
    String what,
  ) async {
    final decoded = await _send(
      () => _client.put(
        _uri(path),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
      what,
    );
    if (decoded is Map<String, dynamic>) return decoded;
    throw ApiException('$what returned an unexpected response.');
  }

  Future<List<Map<String, dynamic>>> _list(String path, String what) async {
    final body = await _send(() => _client.get(_uri(path)), what);
    if (body is! List) {
      throw ApiException('$what returned an unexpected response.');
    }
    // Skip a malformed row rather than failing the whole dropdown over one.
    return [
      for (final item in body)
        if (item is Map<String, dynamic>) item,
    ];
  }

  /// `POST /api/login` with a JSON body.
  ///
  /// The password travels in the body, never the query string, so it stays out
  /// of browser history, proxy logs and server access logs.
  Future<Map<String, dynamic>> login(String email, String password) =>
      _post('/api/login', {'email': email, 'password': password}, 'Sign in');

  /// `POST /api/register`. Returns the generated user id.
  Future<String> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String department,
    required String position,
  }) async {
    final body = await _post('/api/register', {
      'f_name': firstName,
      'l_name': lastName,
      'email': email,
      'password': password,
      'dep': department,
      'pos': position,
    }, 'Registration');
    return '${body['info'] ?? ''}'.trim();
  }

  /// `GET /api/department/passenger`: only departments flagged ISEMP = 'F'.
  Future<List<Map<String, dynamic>>> passengerDepartments() =>
      _list('/api/department/passenger', 'departments');

  /// `GET /api/position/passenger`: only positions flagged ISEMP = 'F'.
  Future<List<Map<String, dynamic>>> passengerPositions() =>
      _list('/api/position/passenger', 'positions');

  /// `GET /api/user/profile/{id}`: the signed-in member's own record.
  ///
  /// The response deliberately has no password field, so there is nothing to
  /// strip here. `/api/user` does return the hashes, which is why this route
  /// exists rather than filtering that list client side.
  Future<Map<String, dynamic>> profile(String userId) => _send(
    () => _client.get(_uri('/api/user/profile/${Uri.encodeComponent(userId)}')),
    'Profile',
  ).then((body) {
    if (body is Map<String, dynamic>) return body;
    throw ApiException('Profile returned an unexpected response.');
  });

  /// `PUT /api/user/profile/{id}`.
  ///
  /// The server accepts only the fields sent here; `password`, `isemp` and
  /// `salary` are not part of the route, so they cannot be changed through it.
  Future<String> saveProfile({
    required String userId,
    required String firstName,
    required String lastName,
    String? department,
    String? position,
  }) async {
    final body = <String, dynamic>{
      'f_name': firstName,
      'l_name': lastName,
      // Null means "unchanged". Sent explicitly rather than omitted so the
      // intent survives a JSON encoder that drops nulls.
      'dep': department,
      'pos': position,
    };
    final decoded = await _put(
      '/api/user/profile/${Uri.encodeComponent(userId)}',
      body,
      'Saving your profile',
    );
    return '${decoded['info'] ?? ''}'.trim();
  }

  void dispose() => _client.close();
}
