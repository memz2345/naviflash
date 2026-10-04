package com.memz2345.navi.flash

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

   
                                                                   
  
                                                                     
                                                
                               
  
                                                              
   
object AppLinkChannel {
    const val CHANNEL_NAME = "com.memz2345.navi.flash/app_links"

    fun register(activity: Activity, messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL_NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "openLinkVerifySettings" ->
                    result.success(openLinkVerifySettings(activity))
                else -> result.notImplemented()
            }
        }
    }

                                                      
    private fun openLinkVerifySettings(activity: Activity): Boolean {
        val uri = Uri.parse("package:" + activity.packageName)
                                                                      
        val ok = runCatching {
            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                Intent(Settings.ACTION_APP_OPEN_BY_DEFAULT_SETTINGS, uri)
            } else {
                Intent(Intent.ACTION_MAIN, uri).setClassName(
                    "com.android.settings",
                    "com.android.settings.applications.InstalledAppOpenByDefaultActivity"
                )
            }
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            activity.startActivity(intent)
        }.isSuccess
        if (ok) return true

                                         
        return runCatching {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, uri)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            activity.startActivity(intent)
        }.isSuccess
    }
}
