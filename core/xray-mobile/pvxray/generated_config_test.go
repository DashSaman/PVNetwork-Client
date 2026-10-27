package pvxray

import (
    "os"
    "path/filepath"
    "strings"
    "testing"

    "github.com/xtls/xray-core/app/proxyman"
    "github.com/xtls/xray-core/core"
    vlessout "github.com/xtls/xray-core/proxy/vless/outbound"
    vmessout "github.com/xtls/xray-core/proxy/vmess/outbound"
)

// A JSON parser PASS is not enough: fields may parse yet be ignored.
// Assert the actual compiled protobuf carries the intended protocol,
// endpoint credentials, transport and TLS/REALITY security settings.
// This still does NOT test real remote connections, DNS, TUN or traffic.
func TestPVNetworkGeneratedConfigsAgainstPinnedCore(t *testing.T) {
    if os.Getenv("PV_REQUIRE_XRAY_FIXTURES") != "1" {
        t.Skip("run in CI after Dart exporter creates synthetic fixtures")
    }
    directory := filepath.Join("..", "config-fixtures")
    entries, err := os.ReadDir(directory)
    if err != nil {
        t.Fatalf("synthetic Flutter fixtures are mandatory: %v", err)
    }
    type requirement struct {
        transport string
        security  string
        protocol  string
    }
    expected := map[string]requirement{
        "vless-reality.json":    {transport: "tcp", security: "reality", protocol: "vless"},
        "vless-ws-tls.json":     {transport: "websocket", security: "tls", protocol: "vless"},
        "vmess-ws-tls.json":     {transport: "websocket", security: "tls", protocol: "vmess"},
        "trojan-tls.json":      {transport: "tcp", security: "tls", protocol: "trojan"},
        "shadowsocks-aead.json": {transport: "tcp", security: "", protocol: "shadowsocks"},
        "socks5-auth.json":     {transport: "tcp", security: "", protocol: "socks"},
        "https-proxy-auth.json": {transport: "tcp", security: "tls", protocol: "http"},
    }
    seen := make(map[string]bool, len(expected))
    for _, entry := range entries {
        if entry.IsDir() { continue }
        want, ok := expected[entry.Name()]
        if !ok { t.Fatalf("unexpected generated fixture %q", entry.Name()) }
        seen[entry.Name()] = true
        t.Run(entry.Name(), func(t *testing.T) {
            data, readErr := os.ReadFile(filepath.Join(directory, entry.Name()))
            if readErr != nil { t.Fatal(readErr) }
            cfg, parseErr := core.LoadConfig("json", strings.NewReader(string(data)))
            if parseErr != nil {
                t.Fatalf("Dart generated config rejected by pinned Xray: %v", parseErr)
            }
            var outboundFound bool
            for _, outbound := range cfg.Outbound {
                if outbound.Tag != "proxy" { continue }
                outboundFound = true
                if outbound.ProxySettings == nil {
                    t.Fatal("proxy outbound has no compiled protocol settings")
                }
                typedProxy, decodeErr := outbound.ProxySettings.GetInstance()
                if decodeErr != nil { t.Fatalf("proxy decode failed: %v", decodeErr) }
                if outbound.SenderSettings == nil {
                    t.Fatal("proxy outbound has no sender settings")
                }
                senderMsg, decodeErr := outbound.SenderSettings.GetInstance()
                if decodeErr != nil { t.Fatalf("sender decode: %v", decodeErr) }
                sender, ok := senderMsg.(*proxyman.SenderConfig)
                if !ok { t.Fatalf("wrong sender proto type: %T", senderMsg) }
                stream := sender.GetStreamSettings()
                if stream == nil { t.Fatal("sender missing compiled stream settings") }
                if got := stream.GetProtocolName(); got != want.transport {
                    t.Errorf("compiled transport = %q, want %q", got, want.transport)
                }
                sec := strings.ToLower(stream.GetSecurityType())
                if want.security == "" && sec != "" {
                    t.Errorf("unexpected compiled security %q", sec)
                }
                if want.security != "" && !strings.Contains(sec, want.security) {
                    t.Errorf("compiled security = %q, expected %q", sec, want.security)
                }
                if want.security != "" && len(stream.GetSecuritySettings()) == 0 {
                    t.Error("compiled TLS/REALITY must retain its security settings")
                }
                switch want.protocol {
                case "vless":
                    vless, ok := typedProxy.(*vlessout.Config)
                    if !ok { t.Fatalf("compiled proxy is %T not VLESS", typedProxy) }
                    endpoint := vless.GetVnext()
                    if endpoint == nil || endpoint.GetAddress() == nil ||
                        endpoint.GetPort() == 0 || endpoint.GetUser() == nil ||
                        endpoint.GetUser().GetAccount() == nil {
                        t.Error("compiled VLESS endpoint/user is missing")
                    }
                case "vmess":
                    vmess, ok := typedProxy.(*vmessout.Config)
                    if !ok { t.Fatalf("compiled proxy is %T not VMess", typedProxy) }
                    endpoint := vmess.GetReceiver()
                    if endpoint == nil || endpoint.GetAddress() == nil ||
                        endpoint.GetPort() == 0 || endpoint.GetUser() == nil ||
                        endpoint.GetUser().GetAccount() == nil {
                        t.Error("compiled VMess endpoint/user is missing")
                    }
                default:
                    // For the other protocols inspect the actual compiled
                    // protocol family; typedProxy is generated by Xray.
                    family := strings.ToLower(outbound.ProxySettings.Type)
                    if !strings.Contains(family, want.protocol) {
                        t.Errorf("compiled proxy family = %q, want %q", family, want.protocol)
                    }
                }
            }
            if !outboundFound {
                t.Fatal("compiled config is missing the active proxy outbound")
            }
        })
    }
    for file := range expected {
        if !seen[file] { t.Errorf("mandatory Flutter-generated fixture missing: %s", file) }
    }
}
