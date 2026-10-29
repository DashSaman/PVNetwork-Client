import 'dart:async';

import 'package:flutter/services.dart';

/// Produces user-facing messages without exporting the raw exception source.
/// VPN configurations, subscription URLs, TLS keys and passwords are secrets.
/// Do not persist the original exception string in public diagnostics.
String safeVpnError(Object error) {
  if (error is TimeoutException) {
    return 'VPN operation timed out. The native session may still be active; retry Stop before reconnecting.';
  }
  if (error is PlatformException) {
    switch (error.code) {
      case 'vpn-permission':
        return 'Android VPN permission is required.';
      case 'engine-unavailable':
        return 'The selected VPN engine is unavailable in this build.';
      case 'busy':
        return 'A VPN operation is already running.';
      case 'stop-failed':
        return 'VPN core cleanup failed. Do not start another connection until Stop succeeds.';
      case 'start-failed':
        return 'VPN startup failed. Check the profile, network and server.';
      default:
        return 'Native VPN operation failed (code: ${_safeCode(error.code)}).';
    }
  }
  if (error is FormatException) {
    // FormatException.source can include an entire secret-bearing raw URL.
    // Only the well-known validated description is displayed.
    return 'Invalid VPN configuration. Check address, port, security and transport fields.';
  }
  if (error is StateError) {
    final message = error.message.toString();
    // Explicitly authored local state errors may be actionable. Guard all
    // credential-like substrings as a last resort.
    return sanitizeVpnText(message);
  }
  return 'VPN operation failed. Inspect redacted diagnostics.';
}

String _safeCode(String code) {
  // Platform exception codes are not trusted logs; reject arbitrary tokens.
  return RegExp(r'^[a-zA-Z0-9_-]{1,32}$').hasMatch(code)
      ? code
      : 'unknown';
}

/// Defense in depth for errors that are already strings. Never use this to
/// sanitize a network config to be logged verbatim.
String sanitizeVpnText(String text) {
  var result = text.replaceAll(
    RegExp(r'(?:vless|vmess|trojan|ss|hysteria2?|hy2|tuic|socks5?|https?|wireguard)://[^\s\]\)\}]+',
        caseSensitive: false),
    '[redacted-config-url]',
  );
  result = result.replaceAll(
    RegExp(r'(?:(?:password|passwd|token|secret|private[_-]?key|authorization|uuid|access[_-]?token)\s*[:=]\s*)[^\s,;]+',
        caseSensitive: false),
    '[redacted-secret]',
  );
  result = result.replaceAll(
    RegExp(r'-----BEGIN [^-]*PRIVATE KEY-----[\s\S]*?-----END [^-]*PRIVATE KEY-----',
        caseSensitive: false),
    '[redacted-private-key]',
  );
  // Never display arbitrarily long native error content.
  if (result.length > 350) {
    result = '${result.substring(0, 350)}…';
  }
  return result;
}
