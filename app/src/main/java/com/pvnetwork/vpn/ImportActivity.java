package com.pvnetwork.vpn;

import android.app.Activity;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.view.Gravity;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

public class ImportActivity extends Activity {
    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        int bg=Color.rgb(9,10,13), gold=Color.rgb(232,173,52), card=Color.rgb(24,26,31);
        getWindow().setStatusBarColor(bg);
        LinearLayout root=new LinearLayout(this); root.setOrientation(LinearLayout.VERTICAL); root.setPadding(dp(22),dp(28),dp(22),dp(24)); root.setBackgroundColor(bg);
        TextView title=tv(getString(R.string.add_configuration),28,Color.WHITE); title.setTypeface(Typeface.DEFAULT_BOLD); root.addView(title);
        root.addView(tv(getString(R.string.import_description),14,Color.rgb(170,174,184)), margin(0,7,0,18));
        EditText input=new EditText(this); input.setMinLines(9); input.setGravity(Gravity.TOP); input.setTextColor(Color.WHITE); input.setHintTextColor(Color.rgb(115,120,130)); input.setHint(R.string.import_hint); input.setPadding(dp(15),dp(15),dp(15),dp(15));
        GradientDrawable ib=new GradientDrawable(); ib.setColor(card); ib.setCornerRadius(dp(16)); ib.setStroke(dp(1),Color.rgb(43,46,54)); input.setBackground(ib); root.addView(input,new LinearLayout.LayoutParams(-1,0,1f));
        Button save=new Button(this); save.setText(R.string.detect_and_save); save.setAllCaps(false); save.setTextSize(16); save.setTextColor(Color.rgb(10,10,12)); GradientDrawable sb=new GradientDrawable(); sb.setColor(gold); sb.setCornerRadius(dp(16)); save.setBackground(sb);
        save.setOnClickListener(v->{ String raw=input.getText().toString().trim(); String protocol=ConfigDetector.detect(raw); if(protocol==null){ Toast.makeText(this,R.string.unsupported_config,Toast.LENGTH_LONG).show(); return; } getSharedPreferences("pvnetwork",MODE_PRIVATE).edit().putString("protocol",protocol).putString("profile",raw).apply(); Toast.makeText(this,getString(R.string.saved_as)+" "+protocol,Toast.LENGTH_SHORT).show(); finish(); });
        root.addView(save,margin(0,16,0,0)); setContentView(root);
    }
    private TextView tv(String s,float z,int c){TextView v=new TextView(this);v.setText(s);v.setTextSize(z);v.setTextColor(c);return v;}
    private LinearLayout.LayoutParams margin(int l,int t,int r,int b){LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(-1,-2);p.setMargins(dp(l),dp(t),dp(r),dp(b));return p;}
    private int dp(int v){return Math.round(v*getResources().getDisplayMetrics().density);}
}
