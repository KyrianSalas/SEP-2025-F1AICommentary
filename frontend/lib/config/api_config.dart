class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://dev.api.f1aicommentary.co.uk',
  );

  static Uri get _baseUri => Uri.parse(baseUrl);

  static Uri get root => _baseUri;

  static String get hostLabel {
    final host = _baseUri.host;
    return host.isEmpty ? baseUrl : host;
  }

  static Uri api(String path) {
    final normalised = path.startsWith('/') ? path.substring(1) : path;
    return _baseUri.replace(path: '/api/$normalised');
  }

  static Uri ws(String path) {
    final normalised = path.startsWith('/') ? path.substring(1) : path;
    final wsScheme = _baseUri.scheme == 'https' ? 'wss' : 'ws';
    return _baseUri.replace(scheme: wsScheme, path: '/api/ws/$normalised');
  }
}