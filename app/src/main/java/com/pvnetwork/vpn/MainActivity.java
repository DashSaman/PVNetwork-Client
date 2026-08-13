package com.pvnetwork.vpn;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

public class MainActivity extends Activity {
    private final int BG = Color.rgb(9,10,13), CARD = Color.rgb(24,26,31), GOLD = Color.rgb(232,173,52), MUTED = Color.rgb(170,174,184);
    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        getWindow().setStatusBarColor(BG);
        render();
    }
    @Override protected void onResume() { super.onResume(); if (findViewById(2001) != null) refreshProfile(); }

    private void render() {
        ScrollView scroll = new ScrollView(this); scroll.setBackgroundColor(BG);
        LinearLayout root = new LinearLayout(this); root.setOrientation(LinearLayout.VERTICAL); root.setPadding(dp(22), dp(26), dp(22), dp(32));
        scroll.addView(root);

        TextView brand = tv(getString(R.string.app_name), 31, Color.WHITE); brand.setTypeface(Typeface.DEFAULT_BOLD); root.addView(brand);
        TextView sub = tv(getString(R.string.universal_client), 14, GOLD); root.addView(sub, margin(0,4,0,22));

        LinearLayout status = card(); status.setId(2000);
        TextView statusTitle = tv(getString(R.string.connection), 13, MUTED); status.addView(statusTitle);
        TextView profile = tv(getString(R.string.no_profile), 22, Color.WHITE); profile.setId(2001); profile.setTypeface(Typeface.DEFAULT_BOLD); status.addView(profile, margin(0,8,0,4));
        TextView detail = tv(getString(R.string.import_to_begin), 14, MUTED); detail.setId(2002); status.addView(detail);
        root.addView(status, margin(0,0,0,16));

        Button connect = button(getString(R.string.connect), GOLD, Color.rgb(12,12,14));
        connect.setOnClickListener(v -> {
            String p = getPreferencesStore().getString("protocol", "");
            if (p.isEmpty()) Toast.makeText(this, R.string.import_to_begin, Toast.LENGTH_SHORT).show();
            else Toast.makeText(this, getString(R.string.engine_gate) + " " + p, Toast.LENGTH_LONG).show();
        });
        root.addView(connect, margin(0,0,0,18));

        TextView quick = tv(getString(R.string.quick_actions), 18, Color.WHITE); quick.setTypeface(Typeface.DEFAULT_BOLD); root.addView(quick, margin(0,4,0,10));
        root.addView(action(getString(R.string.add_configuration), getString(R.string.add_configuration_hint), v -> startActivity(new Intent(this, ImportActivity.class))), margin(0,0,0,10));
        root.addView(action(getString(R.string.scan_qr), getString(R.string.scan_qr_hint), v -> Toast.makeText(this, R.string.qr_next_gate, Toast.LENGTH_SHORT).show()), margin(0,0,0,10));
        root.addView(action(getString(R.string.pv_store), getString(R.string.pv_store_hint), v -> Toast.makeText(this, R.string.store_backend_pending, Toast.LENGTH_SHORT).show()), margin(0,0,0,22));

        TextView protocolTitle = tv(getString(R.string.protocol_platform), 18, Color.WHITE); protocolTitle.setTypeface(Typeface.DEFAULT_BOLD); root.addView(protocolTitle);
        TextView protocols = tv(ProtocolRegistry.summary(), 14, MUTED); protocols.setLineSpacing(0,1.25f); root.addView(protocols, margin(0,10,0,0));
        setContentView(scroll);
        refreshProfile();
    }

    private android.content.SharedPreferences getPreferencesStore() { return getSharedPreferences("pvnetwork", MODE_PRIVATE); }
    private void refreshProfile() {
        TextView p = findViewById(2001), d = findViewById(2002); if (p == null) return;
        String protocol = getPreferencesStore().getString("protocol", "");
        if (protocol.isEmpty()) { p.setText(R.string.no_profile); d.setText(R.string.import_to_begin); }
        else { p.setText(protocol); d.setText(R.string.profile_ready); }
    }
    private LinearLayout action(String title, String hint, View.OnClickListener l) {
        LinearLayout box = card(); box.setClickable(true); box.setOnClickListener(l);
        TextView t=tv(title,18,Color.WHITE); t.setTypeface(Typeface.DEFAULT_BOLD); box.addView(t);
        box.addView(tv(hint,13,MUTED), margin(0,5,0,0)); return box;
    }
    private LinearLayout card() { LinearLayout x=new LinearLayout(this); x.setOrientation(LinearLayout.VERTICAL); x.setPadding(dp(18),dp(18),dp(18),dp(18)); GradientDrawable g=new GradientDrawable(); g.setColor(CARD); g.setCornerRadius(dp(18)); g.setStroke(dp(1),Color.rgb(40,43,50)); x.setBackground(g); return x; }
    private Button button(String s,int bg,int fg){ Button b=new Button(this); b.setText(s); b.setTextSize(17); b.setTextColor(fg); b.setAllCaps(false); GradientDrawable g=new GradientDrawable(); g.setColor(bg); g.setCornerRadius(dp(18)); b.setBackground(g); b.setMinHeight(dp(58)); return b; }
    private TextView tv(String s,float size,int color){ TextView v=new TextView(this); v.setText(s); v.setTextSize(size); v.setTextColor(color); return v; }
    private LinearLayout.LayoutParams margin(int l,int t,int r,int b){ LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(-1,-2); p.setMargins(dp(l),dp(t),dp(r),dp(b)); return p; }
    private int dp(int v){ return Math.round(v*getResources().getDisplayMetrics().density); }
}
