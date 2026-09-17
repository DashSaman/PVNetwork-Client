package com.pvnetwork.vpn

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor

/**
 * Foreground VpnService that owns the TUN interface and hands the raw fd to
 * the pvxray core. The service is the single place allowed to call
 * `establish()`; the plugin layer only orchestrates.
 */
class PVVpnService : VpnService() {

    private var tun: ParcelFileDescriptor? = null

    override fun onCreate() {
        super.onCreate()
        promote()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                shutdown()
                return START_NOT_STICKY
            }
            else -> {
                val config = intent?.getStringExtra(EXTRA_CONFIG) ?: ""
                return try {
                    startTunnel(config)
                    START_STICKY
                } catch (t: Throwable) {
                    PvxrayPlugin.reportStartFailure(t.message ?: t.javaClass.simpleName)
                    shutdown()
                    START_NOT_STICKY
                }
            }
        }
    }

    private fun startTunnel(config: String) {
        if (PvxrayBridge.isRunning()) return
        val fdBuilder = Builder()
            .setSession("PVNetwork")
            .setMtu(1500)
            .addAddress("198.18.0.2", 30)
            .addDnsServer("198.18.0.1")
            .addRoute("0.0.0.0", 0)
            .addRoute("::", 0)
            .setBlocking(false)
        val descriptor = fdBuilder.establish()
            ?: throw IllegalStateException("establish() returned null (permission revoked?)")
        tun = descriptor
        val fdNumber = descriptor.detachFd()
        PvxrayBridge.start(config, fdNumber)
        PvxrayPlugin.reportStartSuccess()
    }

    private fun shutdown() {
        try {
            PvxrayBridge.stop()
        } catch (_: Throwable) {
            // The core must never block teardown.
        }
        tun?.let {
            try {
                it.close()
            } catch (_: Throwable) {
            }
        }
        tun = null
        stopSelf()
    }

    override fun onRevoke() {
        shutdown()
        super.onRevoke()
    }

    override fun onDestroy() {
        try {
            PvxrayBridge.stop()
        } catch (_: Throwable) {
        }
        tun = null
        super.onDestroy()
    }

    private fun promote() {
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "PVNetwork tunnel", NotificationManager.IMPORTANCE_LOW)
            )
        }
        val launch = packageManager.getLaunchIntentForPackage(packageName)
        val contentIntent = PendingIntent.getActivity(
            this, 0, launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val notification: Notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("PVNetwork")
                .setContentText("Tunnel active")
                .setSmallIcon(android.R.drawable.stat_notify_sync_noanim)
                .setContentIntent(contentIntent)
                .setOngoing(true)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setContentTitle("PVNetwork")
                .setContentText("Tunnel active")
                .setSmallIcon(android.R.drawable.stat_notify_sync_noanim)
                .setContentIntent(contentIntent)
                .setOngoing(true)
                .build()
        }
        startForeground(NOTIFICATION_ID, notification)
    }

    companion object {
        const val ACTION_START = "com.pvnetwork.vpn.START"
        const val ACTION_STOP = "com.pvnetwork.vpn.STOP"
        const val EXTRA_CONFIG = "config"
        const val CHANNEL_ID = "pvnetwork-vpn"
        const val NOTIFICATION_ID = 4711
    }
}
