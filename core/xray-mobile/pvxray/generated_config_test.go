package pvxray

import (
    "os"
    "path/filepath"
    "testing"
)

// The Flutter-generated files are validated against the exact Xray dependency
// in go.mod, not a schema copy or a mock native method channel. This is a
// configuration compatibility gate, NOT real TCP/UDP tunnel interoperability.
// The AAR build's standard 'go test ./...' skips this until Flutter has
// emitted the fixtures. CI re-runs this test with PV_REQUIRE_XRAY_FIXTURES=1.
func TestPVNetworkGeneratedConfigsAgainstPinnedCore(t *testing.T) {
    if os.Getenv("PV_REQUIRE_XRAY_FIXTURES") != "1" {
        t.Skip("run in CI after Dart exporter creates synthetic fixtures")
    }
    directory := filepath.Join("..", "config-fixtures")
    entries, err := os.ReadDir(directory)
    if err != nil {
        t.Fatalf("synthetic Flutter fixtures are mandatory: %v", err)
    }
    expected := map[string]bool{
        "vless-reality.json": false,
        "vless-ws-tls.json": false,
        "vmess-ws-tls.json": false,
        "trojan-tls.json": false,
        "shadowsocks-aead.json": false,
        "socks5-auth.json": false,
        "https-proxy-auth.json": false,
    }
    for _, item := range entries {
        if item.IsDir() { continue }
        if _, ok := expected[item.Name()]; !ok {
            t.Fatalf("unexpected fixture %q", item.Name())
        }
        expected[item.Name()] = true
        item := item
        t.Run(item.Name(), func(t *testing.T) {
            data, err := os.ReadFile(filepath.Join(directory, item.Name()))
            if err != nil { t.Fatal(err) }
            if err := ValidateConfig(string(data)); err != nil {
                t.Fatalf("PVNetwork Dart-generated config rejected by pinned Xray: %v", err)
            }
        })
    }
    for file, seen := range expected {
        if !seen { t.Errorf("mandatory generated Xray fixture missing: %s", file) }
    }
}
