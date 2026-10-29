package com.pvnetwork.vpn

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import android.os.Handler
import android.os.Looper
import java.util.concurrent.Executors
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
    private var pendingStop: MethodChannel.Result? = null
    private val main = Handler(Looper.getMainLooper())
    private val queryWorker = Executors.newSingleThreadExecutor { task ->
        Thread(task, "pvnetwork-vpn-query").apply { isDaemon = true }
    }

    // A blocked Go mutex must never block Flutter's Android main thread.
    // Result completions are always marshalled back to that thread.
    private fun runNative(result: MethodChannel.Result, task: () -> Any?) {
        queryWorker.execute {
            try {
                val value = task()
                main.post { result.success(value) }
            } catch (_: Throwable) {
                main.post {
                    result.error(
                        "core-error",
                        "Native VPN operation failed; inspect redacted diagnostics.",
                        null
                    )
                }
            }
        }
    }


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

    /** Must be called on the Android main thread after native Stop returns. */
    fun reportStopCompleted(clean: Boolean) {
        val pending = pendingStop
        pendingStop = null
        if (clean) {
            pending?.success(true)
        } else {
            pending?.error(
                "stop-failed",
                "The VPN core could not be cleanly stopped.",
                null
            )
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (!PvxrayBridge.available && call.method != "prepare" && call.method != "isVpnPrepared" && call.method != "stop") {
            result.error("engine-unavailable", "pvxray core is not bundled in this build", null)
            return
        }
        try {
            when (call.method) {
                "version" -> runNative(result) { PvxrayBridge.version() }
                "validate" -> runNative(result) {
                    PvxrayBridge.validate(call.argument<String>("config") ?: "")
                    true
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
                    if (pendingStop != null) {
                        result.error("busy", "Another VPN stop is already in progress.", null)
                        return
                    }
                    // A stop must only resolve after the worker has closed
                    // Xray and its TUN, not when startService merely returns.
                    pendingStop = result
                    reportStartFailure("VPN connection was cancelled.")
                    val intent = Intent(appContext, PVVpnService::class.java)
                        .setAction(PVVpnService.ACTION_STOP)
                    appContext!!.startService(intent)
                }
                "isRunning" -> runNative(result) { PvxrayBridge.isRunning() }
                "queryUplink" -> runNative(result) { PvxrayBridge.queryUplink() }
                "queryDownlink" -> runNative(result) { PvxrayBridge.queryDownlink() }
                "resetStats" -> runNative(result) {
                    PvxrayBridge.resetStats()
                    true
                }
                "measureDelay" -> runNative(result) { PvxrayBridge.measureDelay(call.argument<String>("url") ?: "") }
                "initEnvironment" -> runNative(result) {
                    PvxrayBridge.initEnvironment(
                        call.argument<String>("assets") ?: "",
                        call.argument<String>("config") ?: ""
                    )
                    true
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
            // A failed foreground-service launch must not leave pendingStart
            // permanently occupied, otherwise every retry reports busy.
            if (pendingStart === result) pendingStart = null
            if (pendingStop === result) pendingStop = null
            if (pendingPrepare === result) pendingPrepare = null
            result.error("core-error", t.message ?: t.javaClass.simpleName, null)
        }
    }
}
