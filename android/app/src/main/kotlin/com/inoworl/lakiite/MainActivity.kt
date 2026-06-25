package com.inoworl.lakiite

import android.content.Intent
import co.ab180.airbridge.flutter.AirbridgeFlutter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private var deepLinkChannel: MethodChannel? = null
    private var pendingInitialDeepLink: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        cacheInitialDeepLink(intent)
        deepLinkChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, RAW_DEEP_LINK_CHANNEL)
        deepLinkChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialDeepLink" -> {
                    result.success(pendingInitialDeepLink)
                    pendingInitialDeepLink = null
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        AirbridgeFlutter.trackDeeplink(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        dispatchRawDeepLink(intent)
    }

    private fun cacheInitialDeepLink(intent: Intent?) {
        val deepLink = intent?.dataString ?: return
        if (pendingInitialDeepLink == null) {
            pendingInitialDeepLink = deepLink
        }
    }

    private fun dispatchRawDeepLink(intent: Intent?) {
        val deepLink = intent?.dataString ?: return
        val channel = deepLinkChannel
        if (channel == null) {
            pendingInitialDeepLink = deepLink
            return
        }
        channel.invokeMethod("onDeepLink", deepLink)
    }

    private companion object {
        const val RAW_DEEP_LINK_CHANNEL = "lakiite/deep_link"
    }
}
