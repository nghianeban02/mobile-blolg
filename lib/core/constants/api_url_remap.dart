/// Rewrites image/API asset URLs so they use the same host as [apiBaseUrl].
///
/// Backend often stores `http://localhost:8080/...` or LAN IP from `app.api.base-url`.
/// Emulator/simulator must load via `10.0.2.2` or `127.0.0.1`, not the phone's LAN IP.
String remapDevAssetUrl(String absoluteUrl, String apiBaseUrl) {
  try {
    final asset = Uri.parse(absoluteUrl);
    final api = Uri.parse(apiBaseUrl);

    if (asset.host == api.host &&
        (asset.port == api.port || (!api.hasPort && asset.port == 80))) {
      return absoluteUrl;
    }

    if (!_shouldRemapHost(asset)) return absoluteUrl;

    return asset
        .replace(
          scheme: api.scheme,
          host: api.host,
          port: api.hasPort ? api.port : asset.port,
        )
        .toString();
  } catch (_) {
    return absoluteUrl;
  }
}

bool _shouldRemapHost(Uri asset) {
  if (_isLoopbackHost(asset.host)) return true;
  if (asset.path.startsWith('/api/images/')) {
    return _isPrivateLanHost(asset.host);
  }
  return false;
}

bool _isLoopbackHost(String host) {
  return host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2';
}

bool _isPrivateLanHost(String host) {
  if (host.startsWith('192.168.')) return true;
  if (host.startsWith('10.')) return true;
  if (host.startsWith('172.')) {
    final parts = host.split('.');
    if (parts.length >= 2) {
      final second = int.tryParse(parts[1]);
      if (second != null && second >= 16 && second <= 31) return true;
    }
  }
  return false;
}
