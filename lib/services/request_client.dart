import 'dart:async';

import 'package:http/http.dart' as http;

const _abortKey = #pindRequestAbort;
Future<T> withRequestCancellation<T>(
  Future<void>? abort,
  Future<T> Function() task,
) => runZoned(task, zoneValues: {_abortKey: abort});

/// Deadlines cover headers and response bodies and abort the underlying socket.
class RequestClient extends http.BaseClient {
  RequestClient({
    http.Client? inner,
    this.timeout = const Duration(seconds: 30),
    this.uploadTimeout = const Duration(seconds: 90),
  }) : _inner = inner ?? http.Client();
  final http.Client _inner;
  final Duration timeout, uploadTimeout;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final duration =
        request.url.path.contains('/storage/v1/object/') &&
            request.method != 'GET'
        ? uploadTimeout
        : timeout;
    final deadline = Completer<void>();
    final timer = Timer(duration, () {
      if (!deadline.isCompleted) deadline.complete();
    });
    final original = request is http.Abortable ? request.abortTrigger : null;
    final scoped = Zone.current[_abortKey] as Future<void>?;
    // Finalize first: multipart sets its boundary Content-Type here.
    final body = request.finalize();
    final proxy =
        http.AbortableStreamedRequest(
            request.method,
            request.url,
            abortTrigger: Future.any([deadline.future, ?original, ?scoped]),
          )
          ..headers.addAll(request.headers)
          ..contentLength = request.contentLength
          ..followRedirects = request.followRedirects
          ..maxRedirects = request.maxRedirects
          ..persistentConnection = request.persistentConnection;
    unawaited(() async {
      try {
        await proxy.sink.addStream(body);
      } catch (error, stack) {
        proxy.sink.addError(error, stack);
      } finally {
        await proxy.sink.close();
      }
    }());
    try {
      final response = await _inner
          .send(proxy)
          .timeout(
            duration,
            onTimeout: () {
              if (!deadline.isCompleted) deadline.complete();
              throw TimeoutException('Request deadline exceeded', duration);
            },
          );
      Stream<List<int>> body() async* {
        try {
          yield* response.stream.timeout(duration);
        } finally {
          timer.cancel();
        }
      }

      return http.StreamedResponse(
        body(),
        response.statusCode,
        headers: response.headers,
        request: request,
        contentLength: response.contentLength,
        reasonPhrase: response.reasonPhrase,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
      );
    } catch (_) {
      timer.cancel();
      rethrow;
    }
  }

  @override
  void close() => _inner.close();
}
