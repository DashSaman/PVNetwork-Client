package com.pvnetwork.vpn

import pvxray.Pvxray

/**
 * Type-checked bridge to the gomobile AAR produced from this checkout.
 *
 * The generated class is `pvxray.Pvxray` (confirmed by Android CI
 * 40425906428). Direct Java linkage prevents stale guessed package strings
 * from silently compiling an APK that can never connect.
 *
 * Android builds MUST include the AAR; desktop platforms use their own
 * runtime adapter and do not compile this Kotlin source.
 */
object PvxrayBridge {
    val available: Boolean
        get() = true

    fun version(): String = Pvxray.version()

    fun validate(config: String) {
        Pvxray.validateConfig(config)
    }

    fun start(config: String, tunFd: Int) {
        Pvxray.start(config, tunFd.toLong())
    }

    fun stop() {
        Pvxray.stop()
    }

    fun isRunning(): Boolean = Pvxray.isRunning()

    fun queryUplink(): Long = Pvxray.queryUplink()

    fun queryDownlink(): Long = Pvxray.queryDownlink()

    fun resetStats() {
        Pvxray.resetStats()
    }

    fun measureDelay(url: String): Long = Pvxray.measureDelay(url)

    fun initEnvironment(assets: String, configDir: String) {
        Pvxray.initEnvironment(assets, configDir)
    }
}
