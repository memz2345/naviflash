package com.memz2345.navi.flash

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

   
                 
  
                                         
      
                                                                       
                                                                 
                             
                                                                 
                                                 
       
  
                                          
   
class FavWidgetChannel(private val context: Context) {

    companion object {
        private const val CHANNEL_NAME = "com.memz2345.navi.flash/home_widget"
    }

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL_NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasWidgets" -> result.success(FavWidgetStore.widgetIds(context).isNotEmpty())

                "updateFavWidget" -> {
                    try {
                        val title = call.argument<String>("folderTitle").orEmpty()
                        val cacheDir = call.argument<String>("coverCacheDir")
                        val items = parseItems(call.argument<List<*>>("items"))
                        FavWidgetStore.save(context, title, cacheDir, items)
                        FavWidgetStore.updateAll(context)
                                                          
                        FavWidgetStore.publishGeneratedPreview(context)
                        result.success(true)
                    } catch (t: Throwable) {
                        result.error("WIDGET_UPDATE_FAILED", t.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun parseItems(raw: List<*>?): List<FavWidgetStore.Item> {
        if (raw == null) return emptyList()
        return raw.mapNotNull { entry ->
            val map = entry as? Map<*, *> ?: return@mapNotNull null
            FavWidgetStore.Item(
                title = (map["title"] as? String).orEmpty(),
                coverPath = map["coverPath"] as? String,
                bvid = map["bvid"] as? String,
            )
        }
    }
}
