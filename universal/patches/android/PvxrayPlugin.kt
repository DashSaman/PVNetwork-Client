package com.pvnetwork.vpn

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Dart-side contract implementation for channel `dev.pvnetwork.xray`.
 *
 * `start` resolves only after PVVpnService established the TUN and the core
 * accepted the config, so the Dart adapter can map a successful return to a
 * real tunnel instead of a optimistic flag.
 */
object PvxrayPlugin : MethodChannel.MethodCallHandler {

    private const val CHANNEL = "dev.pvnetwork.xray"
    const val VPN_PERMISSION_REQUEST = 4712

    private var channel: MethodChannel? = null
    private var appContext: android.content.Context? = null
    private var activity: Activity? = null

    private var pendingPrepare: MethodChannel.Result? = null
    private var pendingStart: MethodChannel.Result? = null

    fun register(messenger: BinaryMessenger, context: android.content.Context) {
        appContext = context.applicationContext
        channel = MethodChannel(messenger, CHANNEL).also { it.setMethodCallHandler(this) }
    }

    fun attachActivity(activity: Activity?) {
        this.activity = activity
    }

    fun handlePermissionResult(granted: Boolean) {
        pendingPrepare?.success(granted)
        pendingPrepare = null
    }

    fun reportStartSuccess() {
        pendingStart?.success(true)
        pendingStart = null
    }

    fun reportStartFailure(message: String) {
        pendingStart?.error("start-failed", message, null)
        pendingStart = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (!PvxrayBridge.available && call.method != "prepare" && call.method != "isVpnPrepared" && call.method != "stop") {
            result.error("engine-unavailable", "pvxray core is not bundled in this build", null)
            return
        }
        try {
            when (call.method) {
                "version" -> result.success(PvxrayBridge.version())
                "validate" -> {
                    PvxrayBridge.validate(call.argument<String>("config") ?: "")
                    result.success(true)
                }
                "start" -> {
                    if (VpnService.prepare(appContext) != null) {
                        result.error("vpn-permission", "VPN permission has not been granted yet", null)
                        return
                    }
                    if (pendingStart != null) {
                        result.error("busy", "another start attempt is in flight", null)
                        return
                    }
                    pendingStart = result
                    val config = call.argument<String>("config") ?: ""
                    PvxrayBridge.initEnvironment(appContext!!.filesDir.absolutePath, appContext!!.filesDir.absolutePath)
                    val intent = Intent(appContext, PVVpnService::class.java)
                        .setAction(PVVpnService.ACTION_START)
                        .putExtra(PVVpnService.EXTRA_CONFIG, config)
                    appContext!!.startForegroundService(intent)
                }
                "stop" -> {
                    val intent = Intent(appContext, PVVpnService::class.java).setAction(PVVpnService.ACTION_STOP)
                    appContext!!.startService(intent)
                    result.success(true)
                }
                "isRunning" -> result.success(PvxrayBridge.isRunning())
                "queryUplink" -> result.success(PvxrayBridge.queryUplink())
                "queryDownlink" -> result.success(PvxrayBridge.queryDownlink())
                "resetStats" -> {
                    PvxrayBridge.resetStats()
                    result.success(true)
                }
                "measureDelay" -> result.success(PvxrayBridge.measureDelay(call.argument<String>("url") ?: ""))
                "initEnvironment" -> {
                    PvxrayBridge.initEnvironment(
                        call.argument<String>("assets") ?: "",
                        call.argument<String>("config") ?: ""
                    )
                    result.success(true)
                }
                "prepare" -> {
                    val intent = VpnService.prepare(appContext)
                    if (intent == null) {
                        result.success(true)
                    } else {
                        val activity = activity
                        if (activity == null) {
                            result.error("no-activity", "VPN permission dialog requires a foreground activity", null)
                        } else if (pendingPrepare != null) {
                            result.error("busy", "a permission request is already pending", null)
                        } else {
                            pendingPrepare = result
                            activity.startActivityForResult(intent, VPN_PERMISSION_REQUEST)
                        }
                    }
                }
                "isVpnPrepared" -> result.success(VpnService.prepare(appContext) == null)
                else -> result.notImplemented()
            }
        } catch (t: Throwable) {
            result.error("core-error", t.message ?: t.javaClass.simpleName, null)
        }
    }
}
