package com.inoworl.lakiite

import android.content.Intent
import co.ab180.airbridge.flutter.AirbridgeFlutter
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onResume() {
        super.onResume()
        AirbridgeFlutter.trackDeeplink(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
