package com.pvnetwork.vpn

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import java.util.concurrent.Executors

/**
 * Android owns the VPN interface; only this service calls establish().
 * Native core start/stop must not run on the Android main thread.
 *
 * A 20s deadline bounds the MethodChannel response but cannot forcibly
 * terminate a stuck native call. If the native call returns after expiry,
 * its queued cleanup closes the core and the TUN. This distinction must be
 * validated with physical-device tests before public release.
 */
class PVVpnService : VpnService() {
    private val main = Handler(Looper.getMainLooper())
    private val worker = Executors.newSingleThreadExecutor { task ->
        Thread(task, "pvnetwork-vpn-core").apply { isDaemon = true }
    }

    // All generation writes happen on the main thread. Worker reads are
    // volatile; a newer STOP/START invalidates callbacks from old sessions.
    @Volatile private var generation = 0L
    @Volatile private var destroying = false

    // TUN ownership remains with the Android service. We must not detachFd:
    // upstream Xray AndroidTun.Close() is a no-op at the pinned revision.
    // A successful native stop must precede closing this descriptor.
    private var tun: ParcelFileDescriptor? = null
    private var startDeadline: Runnable? = null

    override fun onCreate() {
        super.onCreate()
        promote()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> requestStop(startId)
            ACTION_START -> {
                val config = intent.getStringExtra(EXTRA_CONFIG)
                if (config.isNullOrBlank()) {
                    PvxrayPlugin.reportStartFailure("Empty VPN configuration.")
                    requestStop(startId)
                } else {
                    requestStart(config, startId)
                }
            }
            else -> {
                // No blind sticky restart with an empty or stale configuration.
                requestStop(startId)
            }
        }
        return START_NOT_STICKY
    }

    private fun requestStart(config: String, startId: Int) {
        val epoch = ++generation
        clearDeadline()
        val deadline = Runnable {
            if (!destroying && generation == epoch) {
                ++generation
                PvxrayPlugin.reportStartFailure(
                    "VPN core did not finish starting within 20 seconds."
                )
                // Do not call native Stop concurrently with native Start.
                // A late startup must be torn down by this same worker.
                worker.execute {
                    cleanupNative()
                    main.post { stopSelfResult(startId) }
                }
            }
        }
        startDeadline = deadline
        main.postDelayed(deadline, START_DEADLINE_MS)

        worker.execute {
            try {
                if (destroying || generation != epoch) return@execute
                if (PvxrayBridge.isRunning()) {
                    throw IllegalStateException("A VPN core session is already running")
                }
                val descriptor = Builder()
                    .setSession("PVNetwork")
                    .setMtu(1500)
                    .addAddress("198.18.0.2", 30)
                    .addDnsServer("198.18.0.1")
                    .addRoute("0.0.0.0", 0)
                    .addRoute("::", 0)
                    .setBlocking(false)
                    // The native core uses our app UID. Excluding this UID
                    // keeps upstream sockets outside the full-device TUN.
                    .addDisallowedApplication(packageName)
                    .establish()
                    ?: throw IllegalStateException("VPN permission revoked or TUN unavailable")

                tun = descriptor
                if (destroying || generation != epoch) {
                    cleanupNative()
                    return@execute
                }
                // Do not use detachFd(): Go's AndroidTun.Close does not
                // close the caller-supplied fd. Java retains ownership.
                PvxrayBridge.start(config, descriptor.fd)
                if (destroying || generation != epoch) {
                    cleanupNative()
                    return@execute
                }
                main.post {
                    if (!destroying && generation == epoch) {
                        clearDeadline()
                        PvxrayPlugin.reportStartSuccess()
                    }
                }
            } catch (_: Throwable) {
                cleanupNative()
                main.post {
                    if (!destroying && generation == epoch) {
                        clearDeadline()
                        PvxrayPlugin.reportStartFailure(
                            "Native VPN startup failed; inspect redacted diagnostics."
                        )
                        stopSelfResult(startId)
                    }
                }
            }
        }
    }

    private fun requestStop(startId: Int) {
        ++generation
        clearDeadline()
        PvxrayPlugin.reportStartFailure("VPN connection was cancelled.")
        worker.execute {
            cleanupNative()
            main.post { stopSelfResult(startId) }
        }
    }

    /** Called exclusively on the worker after native start has settled. */
    private fun cleanupNative() {
        try {
            PvxrayBridge.stop()
        } catch (_: Throwable) {
            // Still attempt to release the OS TUN interface.
        } finally {
            try {
                tun?.close()
            } catch (_: Throwable) {
            }
            tun = null
        }
    }

    private fun clearDeadline() {
        startDeadline?.let { main.removeCallbacks(it) }
        startDeadline = null
    }

    override fun onRevoke() {
        main.post { requestStop(0) }
        super.onRevoke()
    }

    override fun onDestroy() {
        destroying = true
        ++generation
        clearDeadline()
        PvxrayPlugin.reportStartFailure("VPN service was destroyed.")
        // Never block the main thread waiting for a possibly stuck native
        // call. Enqueue cleanup and allow the worker to drain once it returns.
        worker.execute { cleanupNative() }
        worker.shutdown()
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
        val notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("PVNetwork")
                .setContentText("VPN service starting")
                .setSmallIcon(android.R.drawable.stat_notify_sync_noanim)
                .setContentIntent(contentIntent)
                .setOngoing(true)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setContentTitle("PVNetwork")
                .setContentText("VPN service starting")
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
        private const val START_DEADLINE_MS = 20_000L
    }
}
