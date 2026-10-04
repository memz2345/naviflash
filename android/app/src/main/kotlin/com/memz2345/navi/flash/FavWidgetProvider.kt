package com.memz2345.navi.flash

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.os.Bundle
import android.util.Log

   
            
  
                                                 
                                                    
                                
   
class FavWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { id ->
            runCatching {
                appWidgetManager.updateAppWidget(
                    id,
                    FavWidgetStore.buildViews(context, appWidgetManager.getAppWidgetOptions(id)),
                )
            }.onFailure { Log.w(TAG, "onUpdate 失败 id=$id", it) }
        }
    }

                                       
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        runCatching {
            appWidgetManager.updateAppWidget(
                appWidgetId,
                FavWidgetStore.buildViews(context, newOptions),
            )
        }.onFailure { Log.w(TAG, "onAppWidgetOptionsChanged 失败 id=$appWidgetId", it) }
    }

       
                                   
                                
       
    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        val manager = AppWidgetManager.getInstance(context)
        val remain = manager.getAppWidgetIds(
            android.content.ComponentName(context, FavWidgetProvider::class.java)
        )
        if (remain.isEmpty()) {
            FavWidgetStore.clearCoverFiles(context)
        }
    }

    private companion object {
        const val TAG = "FavWidget"
    }
}
