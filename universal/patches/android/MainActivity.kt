package com.pvnetwork.vpn

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        PvxrayPlugin.register(flutterEngine.dartExecutor.binaryMessenger, applicationContext)
        PvxrayPlugin.attachActivity(this)
    }

    override fun onDestroy() {
        PvxrayPlugin.attachActivity(null)
        super.onDestroy()
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == PvxrayPlugin.VPN_PERMISSION_REQUEST) {
            PvxrayPlugin.handlePermissionResult(resultCode == android.app.Activity.RESULT_OK)
        }
    }
}
