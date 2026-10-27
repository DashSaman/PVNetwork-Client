package pvxray

import (
    "bytes"
    "context"
    "encoding/json"
    "fmt"
    "io"
    "net"
    "net/http"
    "net/http/httptest"
    "net/url"
    "os"
    "os/exec"
    "path/filepath"
    "strconv"
    "sync/atomic"
    "testing"
    "time"

    "github.com/xtls/xray-core/core"
    _ "github.com/xtls/xray-core/proxy/vless/inbound"
)

const localTestUser = "00000000-0000-4000-8000-000000000001"

// Reserve a test-only port, never one exposed on a public interface.
func freeLoopbackPort(t *testing.T) int {
    t.Helper()
    l, err := net.Listen("tcp", "127.0.0.1:0")
    if err != nil { t.Fatal(err) }
    port := l.Addr().(*net.TCPAddr).Port
    if err := l.Close(); err != nil { t.Fatal(err) }
    return port
}

func localVlessServerConfig(port int) []byte {
    config := map[string]any{
        "log": map[string]any{"loglevel": "info"},
        "inbounds": []any{map[string]any{
            "listen": "127.0.0.1", "port": port, "protocol": "vless",
            "settings": map[string]any{
                "decryption": "none",
                "clients": []any{map[string]any{"id": localTestUser}},
            },
        }},
        "outbounds": []any{map[string]any{
            "tag": "direct", "protocol": "freedom",
            "settings": map[string]any{
                // Exact pinned Xray blocks private-IP destinations reached
                // from VLESS by default. Allow only the loopback test target
                // inside this disposable CI server process. NEVER copy this
                // exception into production customer server configurations.
                "finalRules": []any{map[string]any{
                    "action": "allow",
                    "ip": []string{"127.0.0.1/32"},
                }},
            },
        }},
    }
    content, _ := json.Marshal(config)
    return content
}

// A child process is used because the real VLESS server and client are
// separate Xray processes. Two core.StartInstance objects in one Go test
// process may share global networking state; that is not a valid E2E model.
func TestPVLocalVlessServerHelper(t *testing.T) {
    if os.Getenv("PV_LOCAL_VLESS_SERVER_HELPER") != "1" {
        t.Skip("test helper only; started by the loopback integration test")
    }
    port, err := strconv.Atoi(os.Getenv("PV_LOCAL_VLESS_SERVER_PORT"))
    if err != nil || port < 1 || port > 65535 {
        t.Fatalf("invalid loopback test port")
    }
    server, err := core.StartInstance("json", localVlessServerConfig(port))
    if err != nil { t.Fatalf("local VLESS server startup: %v", err) }
    defer func() { _ = server.Close() }()
    // The parent kills this disposable helper when the request has finished.
    time.Sleep(30 * time.Second)
}

func TestDartGeneratedVlessHasRealLocalHandshakeAndDataPath(t *testing.T) {
    if os.Getenv("PV_REQUIRE_XRAY_FIXTURES") != "1" {
        t.Skip("requires synthetically generated Dart VLESS config from CI")
    }

    var handled atomic.Int64
    target := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        handled.Add(1)
        if r.URL.Path != "/pvnetwork-vless-proof" {
            http.Error(w, "unexpected request", http.StatusNotFound)
            return
        }
        w.Header().Set("X-PVNetwork-Interop", "loopback-vless")
        _, _ = io.WriteString(w, "PVNETWORK_VLESS_REAL_DATA_PATH_OK")
    }))
    defer target.Close()

    // Verify the HTTP target itself is responsive independently of Xray.
    checkURL := target.URL + "/pvnetwork-vless-proof"
    direct, err := (&http.Client{Timeout: 3 * time.Second}).Get(checkURL)
    if err != nil { t.Fatalf("direct localhost control request failed: %v", err) }
    _ = direct.Body.Close()
    if direct.StatusCode != http.StatusOK { t.Fatal("local HTTP control failed") }
    baseline := handled.Load()

    vlessPort := freeLoopbackPort(t)
    socksPort := freeLoopbackPort(t)
    for socksPort == vlessPort { socksPort = freeLoopbackPort(t) }

    helperCtx, cancelHelper := context.WithCancel(context.Background())
    helperBinary, err := os.Executable()
    if err != nil { t.Fatal(err) }
    child := exec.CommandContext(
        helperCtx, helperBinary, "-test.run=^TestPVLocalVlessServerHelper$",
    )
    child.Env = append(os.Environ(),
        "PV_REQUIRE_XRAY_FIXTURES=0",
        "PV_LOCAL_VLESS_SERVER_HELPER=1",
        fmt.Sprintf("PV_LOCAL_VLESS_SERVER_PORT=%d", vlessPort),
    )
    var childOut bytes.Buffer
    child.Stdout = &childOut
    child.Stderr = &childOut
    if err := child.Start(); err != nil { cancelHelper(); t.Fatal(err) }
    defer func() {
        cancelHelper()
        _ = child.Wait()
    }()

    // TCP-level readiness: distinguish a server startup problem from a
    // genuine VLESS protocol/data-path error.
    ready := false
    for attempt := 0; attempt < 80; attempt++ {
        socket, dialErr := net.DialTimeout(
            "tcp", fmt.Sprintf("127.0.0.1:%d", vlessPort), 100*time.Millisecond,
        )
        if dialErr == nil {
            _ = socket.Close()
            ready = true
            break
        }
        time.Sleep(50 * time.Millisecond)
    }
    if !ready {
        cancelHelper()
        t.Fatalf("Xray child server failed to listen: %s", childOut.String())
    }

    // Keep the exact Flutter-generated VLESS outbound; only substitute a
    // test SOCKS inbound for the Android-only TUN and a dynamically allocated
    // localhost port for the fake VPN server.
    raw, err := os.ReadFile(filepath.Join("..", "config-fixtures", "vless-loopback.json"))
    if err != nil { t.Fatal(err) }
    var clientConfig map[string]any
    if err := json.Unmarshal(raw, &clientConfig); err != nil { t.Fatal(err) }
    outbounds, ok := clientConfig["outbounds"].([]any)
    if !ok || len(outbounds) == 0 { t.Fatal("Dart produced no outbound") }
    outbound, ok := outbounds[0].(map[string]any)
    if !ok || outbound["protocol"] != "vless" { t.Fatal("Dart outbound is not VLESS") }
    settings, ok := outbound["settings"].(map[string]any)
    if !ok || settings["id"] != localTestUser {
        t.Fatal("Flutter VLESS identity is not present")
    }
    settings["address"] = "127.0.0.1"
    settings["port"] = vlessPort
    clientConfig["inbounds"] = []any{map[string]any{
        "listen": "127.0.0.1", "port": socksPort, "protocol": "socks",
        "settings": map[string]any{"auth": "noauth", "udp": false},
    }}
    // A private target must deliberately go via the VLESS proxy in this
    // *test*. Production LAN bypass remains unaffected.
    delete(clientConfig, "routing")
    clientBytes, err := json.Marshal(clientConfig)
    if err != nil { t.Fatal(err) }
    client, err := core.StartInstance("json", clientBytes)
    if err != nil { t.Fatalf("Flutter-generated Xray client could not start: %v", err) }
    defer func() { _ = client.Close() }()

    socksURL, err := url.Parse(fmt.Sprintf("socks5://127.0.0.1:%d", socksPort))
    if err != nil { t.Fatal(err) }
    transport := &http.Transport{Proxy: http.ProxyURL(socksURL)}
    defer transport.CloseIdleConnections()
    httpClient := &http.Client{Transport: transport, Timeout: 8*time.Second}
    response, err := httpClient.Get(checkURL)
    if err != nil {
        cancelHelper()
        t.Fatalf("VLESS loopback data path failed (target hits=%d, baseline=%d): %v; child diagnostics: %s",
            handled.Load(), baseline, err, childOut.String())
    }
    defer response.Body.Close()
    payload, err := io.ReadAll(io.LimitReader(response.Body, 256))
    if err != nil { t.Fatal(err) }
    if response.StatusCode != http.StatusOK ||
        response.Header.Get("X-PVNetwork-Interop") != "loopback-vless" ||
        string(payload) != "PVNETWORK_VLESS_REAL_DATA_PATH_OK" ||
        handled.Load() <= baseline {
        t.Fatalf("invalid VLESS response: status=%d body=%q target hits=%d",
            response.StatusCode, string(payload), handled.Load())
    }
    // Test the new in-process probe path. It must force the active 'proxy'
    // outbound, without creating an unauthenticated loopback listener.
    beforeProbe := handled.Load()
    delay := measureDelayThroughInstance(client, checkURL, http.StatusOK)
    if delay < 0 {
        t.Fatal("internal proxy-bound HTTP latency probe failed")
    }
    if handled.Load() <= beforeProbe {
        t.Fatalf("internal latency probe did not traverse real VLESS; hits=%d", handled.Load())
    }

}
