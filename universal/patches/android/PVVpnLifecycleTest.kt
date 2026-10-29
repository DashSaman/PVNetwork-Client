package com.pvnetwork.vpn

import android.content.Intent
import android.net.VpnService
import android.os.Build
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Emulator-only native VPN/TUN start-stop acceptance gate.
 *
 * Runs against the same patched Kotlin service and native pvxray AAR as
 * PVNetwork. The CI emulator pregrants ACTIVATE_VPN and is not a user device.
 * This does NOT establish actual external proxy, DNS, IPv6 or no-leak proof.
 */
@RunWith(AndroidJUnit4::class)
class PVVpnLifecycleTest {
    private val app get() = InstrumentationRegistry.getInstrumentation().targetContext

    private val config = """
        {
          "log": {"loglevel":"warning"},
          "inbounds": [
            {"tag":"tun-in","protocol":"tun","settings":{"mtu":1500,"userLevel":0}}
          ],
          "outbounds": [
            {"tag":"proxy","protocol":"freedom","settings":{}}
          ]
        }
    """.trimIndent()

    private fun waitFor(timeoutMs: Long, condition: () -> Boolean): Boolean {
        val limit = System.currentTimeMillis() + timeoutMs
        while (System.currentTimeMillis() < limit) {
            if (condition()) return true
            Thread.sleep(100L)
        }
        return condition()
    }

    @Test
    fun actualNativeTunCanStartStopAndRestartWithoutStaleState() {
        assertTrue("native pvxray was not linked", PvxrayBridge.available)
        assertTrue("native version missing", PvxrayBridge.version().isNotBlank())
        assertNull(
            "VPN permission missing; grant ACTIVATE_VPN only on the disposable emulator",
            VpnService.prepare(app),
        )
        val launch = app.packageManager.getLaunchIntentForPackage(app.packageName)
        if (launch != null) {
            launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            app.startActivity(launch)
        }
        Thread.sleep(600L)

        for (cycle in 1..3) {
            val intent = Intent(app, PVVpnService::class.java)
                .setAction(PVVpnService.ACTION_START)
                .putExtra(PVVpnService.EXTRA_CONFIG, config)

            try {
                if (Build.VERSION.SDK_INT >= 26) {
                    app.startForegroundService(intent)
                } else {
                    app.startService(intent)
                }
                assertTrue(
                    "cycle $cycle: native TUN did not start within 12 seconds",
                    waitFor(12_000L) { PvxrayBridge.isRunning() },
                )
            } finally {
                val stop = Intent(app, PVVpnService::class.java)
                    .setAction(PVVpnService.ACTION_STOP)
                app.startService(stop)
                assertTrue(
                    "cycle $cycle: native Xray did not stop within 12 seconds",
                    waitFor(12_000L) { !PvxrayBridge.isRunning() },
                )
                assertFalse(
                    "cycle $cycle: Xray remained active after stop",
                    PvxrayBridge.isRunning(),
                )
            }
            Thread.sleep(250L)
        }
    }
}
