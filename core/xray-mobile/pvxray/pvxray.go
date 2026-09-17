package pvxray

import (
        "errors"
        "net/http"
        "net/url"
        "os"
        "strconv"
        "strings"
        "sync"
        "time"

        "github.com/xtls/xray-core/app/stats"
        "github.com/xtls/xray-core/core"

        _ "github.com/xtls/xray-core/app/dispatcher"
        _ "github.com/xtls/xray-core/app/dns"
        _ "github.com/xtls/xray-core/app/log"
        _ "github.com/xtls/xray-core/app/policy"
        _ "github.com/xtls/xray-core/app/proxyman/inbound"
        _ "github.com/xtls/xray-core/app/proxyman/outbound"
        _ "github.com/xtls/xray-core/app/router"
        _ "github.com/xtls/xray-core/main/json"
        _ "github.com/xtls/xray-core/proxy/blackhole"
        _ "github.com/xtls/xray-core/proxy/dns"
        _ "github.com/xtls/xray-core/proxy/freedom"
        _ "github.com/xtls/xray-core/proxy/shadowsocks"
        _ "github.com/xtls/xray-core/proxy/socks"
        _ "github.com/xtls/xray-core/proxy/trojan"
        _ "github.com/xtls/xray-core/proxy/tun"
        _ "github.com/xtls/xray-core/proxy/vless/outbound"
        _ "github.com/xtls/xray-core/proxy/vmess/outbound"
        _ "github.com/xtls/xray-core/transport/internet/grpc"
        _ "github.com/xtls/xray-core/transport/internet/httpupgrade"
        _ "github.com/xtls/xray-core/transport/internet/reality"
        _ "github.com/xtls/xray-core/transport/internet/splithttp"
        _ "github.com/xtls/xray-core/transport/internet/tagged/taggedimpl"
        _ "github.com/xtls/xray-core/transport/internet/tcp"
        _ "github.com/xtls/xray-core/transport/internet/tls"
        _ "github.com/xtls/xray-core/transport/internet/udp"
        _ "github.com/xtls/xray-core/transport/internet/websocket"
)

// healthInboundPort is the fixed local HTTP inbound PVNetwork's generated
// configs expose for latency probing (contract with XrayConfigBuilder).
const healthInboundPort = 19670

var (
        mu       sync.Mutex
        instance *core.Instance
)

func Version() string { return core.Version() }

// InitEnvironment points the core at app-managed asset/config locations.
// Must be called before Start. Empty values are ignored.
func InitEnvironment(assetLocation, configLocation string) error {
        if strings.TrimSpace(assetLocation) != "" {
                if err := os.Setenv("XRAY_LOCATION_ASSET", assetLocation); err != nil {
                        return err
                }
        }
        if strings.TrimSpace(configLocation) != "" {
                if err := os.Setenv("XRAY_LOCATION_CONFIG", configLocation); err != nil {
                        return err
                }
        }
        return nil
}

func ValidateConfig(config string) error {
        if strings.TrimSpace(config) == "" {
                return errors.New("configuration is empty")
        }
        _, err := core.LoadConfig("json", strings.NewReader(config))
        return err
}

// Start uses int64 deliberately so gomobile exposes a stable Java/Kotlin long ABI.
func Start(config string, tunFD int64) error {
        mu.Lock()
        defer mu.Unlock()

        if tunFD < 0 {
                return errors.New("invalid TUN file descriptor")
        }
        if instance != nil && instance.IsRunning() {
                return errors.New("Xray is already running")
        }
        if err := ValidateConfig(config); err != nil {
                return err
        }
        fdValue := strconv.FormatInt(tunFD, 10)
        if err := os.Setenv("xray.tun.fd", fdValue); err != nil {
                return err
        }
        if err := os.Setenv("XRAY_TUN_FD", fdValue); err != nil {
                _ = os.Unsetenv("xray.tun.fd")
                return err
        }

        started, err := core.StartInstance("json", []byte(config))
        if err != nil {
                _ = os.Unsetenv("xray.tun.fd")
                _ = os.Unsetenv("XRAY_TUN_FD")
                return err
        }
        instance = started
        return nil
}

func Stop() error {
        mu.Lock()
        defer mu.Unlock()
        var err error
        if instance != nil {
                err = instance.Close()
                instance = nil
        }
        _ = os.Unsetenv("xray.tun.fd")
        _ = os.Unsetenv("XRAY_TUN_FD")
        return err
}

func IsRunning() bool {
        mu.Lock()
        defer mu.Unlock()
        return instance != nil && instance.IsRunning()
}

func statsManager() (stats.Manager, error) {
        mu.Lock()
        defer mu.Unlock()
        if instance == nil || !instance.IsRunning() {
                return nil, errors.New("Xray is not running")
        }
        mgr := instance.GetFeature(stats.ManagerType())
        if mgr == nil {
                return nil, errors.New("stats service is unavailable in this config")
        }
        sm, ok := mgr.(stats.Manager)
        if !ok {
                return nil, errors.New("stats service has an unexpected type")
        }
        return sm, nil
}

func queryCounter(name string) int64 {
        sm, err := statsManager()
        if err != nil {
                return 0
        }
        counter := sm.GetCounter(name)
        if counter == nil {
                return 0
        }
        return counter.Get()
}

// QueryUplink reports bytes uploaded through the 'proxy' outbound since the
// last start (or since ResetStats). Requires the config to enable the stats
// service; PVNetwork's generated configs always do. Returns 0 when stats are
// unavailable.
func QueryUplink() int64 {
        return queryCounter("outbound>>>proxy>>>traffic>>>uplink")
}

// QueryDownlink reports bytes downloaded through the 'proxy' outbound.
func QueryDownlink() int64 {
        return queryCounter("outbound>>>proxy>>>traffic>>>downlink")
}

// ResetStats zeroes the uplink/downlink counters. No-op when stats are
// unavailable.
func ResetStats() {
        sm, err := statsManager()
        if err != nil {
                return
        }
        for _, name := range []string{
                "outbound>>>proxy>>>traffic>>>uplink",
                "outbound>>>proxy>>>traffic>>>downlink",
        } {
                if counter := sm.GetCounter(name); counter != nil {
                        counter.Set(0)
                }
        }
}

// MeasureDelay probes url through the RUNNING instance's health-in HTTP
// inbound (127.0.0.1:<healthInboundPort>), whose traffic is routed through
// the 'proxy' outbound. Returns milliseconds, or -1 when the core is not
// running or the probe fails. The caller owns the URL contract (typically
// an HTTP 204 endpoint).
func MeasureDelay(url string) int64 {
        if !IsRunning() {
                return -1
        }
        return probeThroughProxy("http://127.0.0.1:" + strconv.Itoa(healthInboundPort), url)
}

// MeasureDirectDelay probes url without any proxy (control measurement for
// the UI). Returns milliseconds, or -1 when the probe fails.
func MeasureDirectDelay(url string) int64 {
        return probeThroughProxy("", url)
}

func probeThroughProxy(proxyAddr, url string) int64 {
        transport := &http.Transport{
                Proxy: nil,
        }
        if proxyAddr != "" {
                parsed, err := parseProxyURL(proxyAddr)
                if err != nil {
                        return -1
                }
                transport.Proxy = http.ProxyURL(parsed)
        }
        client := &http.Client{
                Transport: transport,
                Timeout:   8 * time.Second,
                CheckRedirect: func(req *http.Request, via []*http.Request) error {
                        return http.ErrUseLastResponse
                },
        }
        start := time.Now()
        resp, err := client.Get(url)
        if err != nil {
                return -1
        }
        defer resp.Body.Close()
        if resp.StatusCode < 200 || resp.StatusCode > 399 {
                return -1
        }
        return time.Since(start).Milliseconds()
}

func parseProxyURL(raw string) (*url.URL, error) {
        return url.Parse(raw)
}
