package com.memz2345.navi.flash

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

   
                                      
                                
  
                                            
                                                          
                                                           
                                                           
   
class ModelDownloadChannel(private val context: Context) {

    companion object {
        private const val CHANNEL_NAME = ModelDownloadService.CHANNEL_NAME
    }

    fun register(messenger: BinaryMessenger) {
        val channel = MethodChannel(messenger, CHANNEL_NAME)
                                             
        ModelDownloadService.flutterChannel = channel

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val title = call.argument<String>("title") ?: "模型下载"
                    val raw = call.argument<List<Any?>>("files")
                    val specs = raw.orEmpty().mapNotNull { item ->
                        @Suppress("UNCHECKED_CAST")
                        ModelDownloadService.FileSpec.fromMap(item as? Map<*, *>)
                    }
                    if (specs.isEmpty()) {
                        result.error("BAD_ARGS", "files is empty", null)
                    } else {
                        ModelDownloadService.start(context, title, specs)
                        result.success(true)
                    }
                }
                "cancel" -> {
                    ModelDownloadService.cancel(context)
                    result.success(true)
                }
                "status" -> {
                    result.success(
                        mapOf(
                            "running" to ModelDownloadService.running,
                            "received" to ModelDownloadService.lastReceived,
                            "total" to ModelDownloadService.lastTotal,
                            "name" to ModelDownloadService.lastName
                        )
                    )
                }
                else -> result.notImplemented()
            }
        }
    }
}
