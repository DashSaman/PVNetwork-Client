package com.pvnetwork.vpn;

import java.util.Locale;

public final class ConfigDetector {
    private ConfigDetector() {}
    public static String detect(String raw) {
        if (raw == null || raw.trim().isEmpty()) return null;
        String s = raw.trim().toLowerCase(Locale.ROOT);
        if (s.startsWith("vless://")) return s.contains("security=reality") ? "VLESS + Reality" : "VLESS";
        if (s.startsWith("vmess://")) return "VMess";
        if (s.startsWith("trojan://")) return "Trojan";
        if (s.startsWith("ss://")) return "Shadowsocks";
        if (s.startsWith("hysteria2://") || s.startsWith("hy2://")) return "Hysteria2";
        if (s.startsWith("tuic://")) return "TUIC";
        if (s.startsWith("anytls://")) return "AnyTLS";
        if (s.contains("[interface]") && s.contains("privatekey")) return "WireGuard";
        if (s.contains("client") && (s.contains("remote ") || s.contains("proto udp") || s.contains("proto tcp"))) return "OpenVPN";
        if (s.startsWith("openconnect://") || s.startsWith("anyconnect://")) return "OpenConnect";
        if (s.startsWith("ikev2://")) return "IKEv2/IPsec";
        if (s.startsWith("sstp://")) return "SSTP";
        return null;
    }
}
