package com.pvnetwork.vpn

/**
 * Reflective bridge to the gomobile-generated `Pvxray` API bundled inside
 * `libs/pvxray.aar`.
 *
 * Reflection (instead of a compile-time import) keeps the host app buildable
 * even when the AAR artifact is absent (desktop/dev builds, fresh CI hosts).
 * When the class cannot be resolved, [available] is false and every call
 * reports an error so the Dart layer degrades gracefully.
 */
object PvxrayBridge {
    // gomobile derives the Java package from the Go import path
    // github.com/pvnetwork/xray-mobile/pvxray (dashes become underscores).
    private val candidates = listOf(
        "github.com.pvnetwork.xray_mobile.pvxray.Pvxray",
        "github.pvnetwork.xray_mobile.pvxray.Pvxray",
        "com.pvnetwork.xray_mobile.pvxray.Pvxray"
    )

    private val cls: Class<*>? = candidates.firstNotNullOfOrNull { name ->
        try {
            Class.forName(name)
        } catch (_: Throwable) {
            null
        }
    }

    val available: Boolean
        get() = cls != null

    private fun call(method: String, vararg args: Any?): Any? {
        val target = cls ?: throw IllegalStateException("pvxray core is not bundled in this build")
        val m = target.declaredMethods.firstOrNull { it.name == method && it.parameterCount == args.size }
            ?: throw IllegalStateException("pvxray method not found: $method/${args.size}")
        return try {
            m.invoke(null, *args)
        } catch (e: java.lang.reflect.InvocationTargetException) {
            throw (e.cause ?: e)
        }
    }

    fun version(): String = call("version")?.toString() ?: ""

    /** @throws Throwable when the config is rejected by the core. */
    fun validate(config: String) {
        call("validateConfig", config)
    }

    /** @throws Throwable when the core fails to start. */
    fun start(config: String, tunFd: Int) {
        call("start", config, tunFd.toLong())
    }

    fun stop() {
        call("stop")
    }

    fun isRunning(): Boolean = call("isRunning") as? Boolean ?: false

    fun queryUplink(): Long = (call("queryUplink") as? Number)?.toLong() ?: 0L

    fun queryDownlink(): Long = (call("queryDownlink") as? Number)?.toLong() ?: 0L

    fun resetStats() {
        call("resetStats")
    }

    fun measureDelay(url: String): Long = (call("measureDelay", url) as? Number)?.toLong() ?: -1L

    fun initEnvironment(assets: String, configDir: String) {
        call("initEnvironment", assets, configDir)
    }
}
