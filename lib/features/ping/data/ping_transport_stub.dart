import 'ping_transport.dart';

/// Web 不伪造 ICMP。
PingTransport createTransport() => _Unsupported();

class _Unsupported implements PingTransport {
  @override
  bool get supported => false;
  @override
  Future<double?> probe(String target, int bytes, int timeoutMs) =>
      Future.error(UnsupportedError('仅支持 Android'));
  @override
  void cancel() {}
}
