package com.inoworl.lakiite

import android.app.Application
import android.content.pm.PackageManager
import android.util.Log
import co.ab180.airbridge.flutter.AirbridgeFlutter

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        val appName = readMetadata(AIRBRIDGE_APP_NAME_KEY) ?: DEFAULT_AIRBRIDGE_APP_NAME
        val sdkToken = readMetadata(AIRBRIDGE_SDK_TOKEN_KEY)

        if (sdkToken.isNullOrBlank()) {
            Log.i(TAG, "Airbridge SDK token is not configured. Initialization skipped.")
            return
        }

        AirbridgeFlutter.initializeSDK(this, appName, sdkToken)
    }

    private fun readMetadata(key: String): String? {
        val applicationInfo = packageManager.getApplicationInfo(
            packageName,
            PackageManager.GET_META_DATA,
        )
        return applicationInfo.metaData?.getString(key)
    }

    private companion object {
        const val TAG = "MainApplication"
        const val DEFAULT_AIRBRIDGE_APP_NAME = "lakiite"
        const val AIRBRIDGE_APP_NAME_KEY = "co.ab180.airbridge.app_name"
        const val AIRBRIDGE_SDK_TOKEN_KEY = "co.ab180.airbridge.sdk_token"
    }
}
