import "dart:convert";
import "dart:io";

const _name = r"^[A-Za-z0-9_:\-]{1,64}$";
const _email = r"^[^\s@]+@[^\s@]+\.[^\s@]+$";
const _reserved = {"pageview", "engagement"};

class DatafsException implements Exception {
  DatafsException(this.code, {this.status});
  final String code;
  final int? status;
  @override
  String toString() => "DatafsException($code)";
}

String stripUrl(String raw) {
  final uri = Uri.parse(raw);
  return Uri(
    scheme: uri.scheme.isEmpty ? null : uri.scheme,
    host: uri.host.isEmpty ? null : uri.host,
    port: uri.hasPort ? uri.port : null,
    path: uri.path.isEmpty ? "/" : uri.path,
  ).toString();
}

Map<String, String> campaignOf(String raw) {
  final params = Uri.parse(raw).queryParameters;
  String? cut(String key) {
    final value = params[key];
    if (value == null || value.isEmpty) return null;
    return value.length > 64 ? value.substring(0, 64) : value;
  }

  final out = <String, String>{};
  final source = cut("utm_source");
  final medium = cut("utm_medium");
  final name = cut("utm_campaign");
  if (source != null) out["s"] = source;
  if (medium != null) out["m"] = medium;
  if (name != null) out["c"] = name;
  return out;
}

void assertProps(Map<String, String>? props) {
  if (props == null) return;
  if (props.length > 10) throw DatafsException("invalid_props");
  final email = RegExp(_email);
  for (final entry in props.entries) {
    if (entry.key.isEmpty || entry.key.length > 32 || entry.value.length > 64 || email.hasMatch(entry.value)) {
      throw DatafsException("invalid_props");
    }
  }
}

class Datafs {
  Datafs({required this.domain, required String endpoint, HttpClient? http})
      : endpoint = endpoint.endsWith("/") ? endpoint.substring(0, endpoint.length - 1) : endpoint,
        _http = http ?? HttpClient();

  final String domain;
  final String endpoint;
  final HttpClient _http;

  Future<void> pageview({required String url, String? referrer}) {
    final body = <String, Object?>{
      "n": "pageview",
      "u": stripUrl(url),
      "d": domain,
      ...campaignOf(url),
    };
    if (referrer != null && referrer.isNotEmpty) body["r"] = stripUrl(referrer);
    return _send(body);
  }

  Future<void> event(String name, {Map<String, String>? props, required String url, String? referrer}) {
    if (!RegExp(_name).hasMatch(name) || _reserved.contains(name)) {
      throw DatafsException("invalid_name");
    }
    assertProps(props);
    final body = <String, Object?>{
      "n": name,
      "u": stripUrl(url),
      "d": domain,
      ...campaignOf(url),
    };
    if (referrer != null && referrer.isNotEmpty) body["r"] = stripUrl(referrer);
    if (props != null && props.isNotEmpty) body["p"] = props;
    return _send(body);
  }

  Future<void> _send(Map<String, Object?> body) async {
    final request = await _http.postUrl(Uri.parse("$endpoint/api/event"));
    request.headers.set(HttpHeaders.contentTypeHeader, "text/plain;charset=UTF-8");
    request.add(utf8.encode(jsonEncode(body)));
    final response = await request.close();
    await response.drain();
    if (response.statusCode != 202) {
      throw DatafsException("event_rejected", status: response.statusCode);
    }
  }
}
