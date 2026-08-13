package com.pvnetwork.vpn;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

public class SplashActivity extends Activity {
    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        getWindow().setStatusBarColor(Color.rgb(8,8,10));
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setGravity(Gravity.CENTER);
        root.setPadding(dp(32), dp(32), dp(32), dp(32));
        root.setBackgroundColor(Color.rgb(8,8,10));

        ImageView logo = new ImageView(this);
        logo.setImageResource(com.pvnetwork.vpn.R.drawable.ic_pv_logo);
        root.addView(logo, new LinearLayout.LayoutParams(dp(180), dp(180)));

        TextView title = text(getString(R.string.app_name), 34, Color.WHITE);
        title.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams tp = new LinearLayout.LayoutParams(-1, -2);
        tp.topMargin = dp(20);
        root.addView(title, tp);

        TextView tag = text(getString(R.string.tagline), 15, Color.rgb(210,164,60));
        tag.setGravity(Gravity.CENTER);
        root.addView(tag, new LinearLayout.LayoutParams(-1, -2));
        setContentView(root);

        new Handler(Looper.getMainLooper()).postDelayed(() -> {
            startActivity(new Intent(this, MainActivity.class));
            finish();
        }, 700);
    }
    private TextView text(String s, float sp, int c) { TextView v = new TextView(this); v.setText(s); v.setTextSize(sp); v.setTextColor(c); return v; }
    private int dp(int v) { return Math.round(v * getResources().getDisplayMetrics().density); }
}
