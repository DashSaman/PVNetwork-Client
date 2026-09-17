package pvxray

import (
        "os"
        "strings"
        "testing"
)

const lifecycleConfig = `{
  "log": {"loglevel": "warning"},
  "stats": {},
  "policy": {
    "levels": {"0": {"statsUserUplink": true, "statsUserDownlink": true}},
    "system": {"statsOutboundUplink": true, "statsOutboundDownlink": true}
  },
  "inbounds": [
    {"tag": "socks-in", "listen": "127.0.0.1", "port": 19671, "protocol": "socks",
     "settings": {"auth": "noauth", "udp": false, "userLevel": 0}}
  ],
  "outbounds": [
    {"tag": "proxy", "protocol": "freedom", "settings": {}},
    {"tag": "direct", "protocol": "freedom", "settings": {}}
  ]
}`

func TestVersionIsNotEmpty(t *testing.T) {
        if strings.TrimSpace(Version()) == "" {
                t.Fatal("Version() returned an empty string")
        }
}

func TestValidateConfigRejectsEmpty(t *testing.T) {
        if err := ValidateConfig("   \n\t"); err == nil {
                t.Fatal("expected error for empty config")
        }
}

func TestValidateConfigRejectsBrokenJSON(t *testing.T) {
        if err := ValidateConfig(`{"outbounds": [`); err == nil {
                t.Fatal("expected error for broken JSON")
        }
}

func TestValidateConfigAcceptsMinimal(t *testing.T) {
        minimal := `{"inbounds": [], "outbounds": [{"protocol": "freedom", "tag": "direct"}]}`
        if err := ValidateConfig(minimal); err != nil {
                t.Fatalf("minimal config should validate, got: %v", err)
        }
}

func TestStartStopLifecycle(t *testing.T) {
        if IsRunning() {
                t.Skip("another test left the core running")
        }
        if err := Start(lifecycleConfig, 0); err != nil {
                t.Fatalf("Start failed: %v", err)
        }
        if !IsRunning() {
                t.Fatal("IsRunning() = false after Start")
        }

        if up, down := QueryUplink(), QueryDownlink(); up < 0 || down < 0 {
                t.Fatalf("negative counters: up=%d down=%d", up, down)
        }
        ResetStats() // must not panic even with zero traffic

        if err := Start(lifecycleConfig, 0); err == nil {
                t.Fatal("second Start while running must fail")
        }

        if err := Stop(); err != nil {
                t.Fatalf("Stop failed: %v", err)
        }
        if IsRunning() {
                t.Fatal("IsRunning() = true after Stop")
        }

        // Double Stop must stay safe.
        if err := Stop(); err != nil {
                t.Fatalf("second Stop must be a no-op, got: %v", err)
        }
}

func TestStartRejectsNegativeTunFD(t *testing.T) {
        if err := Start(lifecycleConfig, -1); err == nil {
                t.Fatal("Start with negative TUN fd must fail")
        }
        if IsRunning() {
                t.Fatal("core must not be running after rejected Start")
        }
}

func TestMeasureDelayWithoutInstance(t *testing.T) {
        if IsRunning() {
                t.Skip("another test left the core running")
        }
        if got := MeasureDelay("https://www.gstatic.com/generate_204"); got != -1 {
                t.Fatalf("MeasureDelay without a running instance = %d, want -1", got)
        }
}

func TestInitEnvironmentSetsLocations(t *testing.T) {
        if err := InitEnvironment("/data/assets", "/data/config"); err != nil {
                t.Fatalf("InitEnvironment failed: %v", err)
        }
        if got := os.Getenv("XRAY_LOCATION_ASSET"); got != "/data/assets" {
                t.Fatalf("XRAY_LOCATION_ASSET = %q", got)
        }
        if got := os.Getenv("XRAY_LOCATION_CONFIG"); got != "/data/config" {
                t.Fatalf("XRAY_LOCATION_CONFIG = %q", got)
        }
        t.Cleanup(func() {
                _ = os.Unsetenv("XRAY_LOCATION_ASSET")
                _ = os.Unsetenv("XRAY_LOCATION_CONFIG")
        })
}
