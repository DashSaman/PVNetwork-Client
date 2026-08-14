package pvxray

import (
	"errors"
	"os"
	"strconv"
	"strings"
	"sync"

	"github.com/xtls/xray-core/core"

	_ "github.com/xtls/xray-core/app/dispatcher"
	_ "github.com/xtls/xray-core/app/dns"
	_ "github.com/xtls/xray-core/app/log"
	_ "github.com/xtls/xray-core/app/policy"
	_ "github.com/xtls/xray-core/app/proxyman/inbound"
	_ "github.com/xtls/xray-core/app/proxyman/outbound"
	_ "github.com/xtls/xray-core/app/router"
	_ "github.com/xtls/xray-core/app/stats"
	_ "github.com/xtls/xray-core/main/json"
	_ "github.com/xtls/xray-core/proxy/blackhole"
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

var (
	mu       sync.Mutex
	instance *core.Instance
)

func Version() string { return core.Version() }

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
