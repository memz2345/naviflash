package com.memz2345.navi.flash

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

   
                              
                                               
   
class ModelDownloadReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        val ctx = context ?: return
        ModelDownloadService.cancel(ctx)
    }
}
