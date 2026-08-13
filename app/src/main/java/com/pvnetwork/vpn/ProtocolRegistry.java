package com.pvnetwork.vpn;

import java.util.Arrays;
import java.util.List;

public final class ProtocolRegistry {
    public enum Stage { IMPORT_READY, ENGINE_NEXT, PLANNED }
    public static final class Entry {
        public final String name; public final Stage stage;
        Entry(String n, Stage s){name=n;stage=s;}
    }
    public static final List<Entry> ALL = Arrays.asList(
        new Entry("VLESS", Stage.IMPORT_READY), new Entry("VLESS + Reality", Stage.IMPORT_READY),
        new Entry("VMess", Stage.IMPORT_READY), new Entry("OpenVPN TCP/UDP", Stage.IMPORT_READY),
        new Entry("WireGuard", Stage.IMPORT_READY), new Entry("Trojan", Stage.IMPORT_READY),
        new Entry("Shadowsocks", Stage.IMPORT_READY), new Entry("Hysteria2", Stage.IMPORT_READY),
        new Entry("TUIC", Stage.IMPORT_READY), new Entry("AnyTLS", Stage.IMPORT_READY),
        new Entry("OpenConnect / AnyConnect", Stage.IMPORT_READY), new Entry("IKEv2/IPsec", Stage.IMPORT_READY),
        new Entry("L2TP/IPsec", Stage.PLANNED), new Entry("SSTP", Stage.IMPORT_READY)
    );
    private ProtocolRegistry() {}
    public static String summary(){ StringBuilder b=new StringBuilder(); for(Entry e:ALL) b.append("• ").append(e.name).append("\n"); return b.toString().trim(); }
}
