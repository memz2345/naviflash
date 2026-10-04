package com.memz2345.navi.flash

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProviderInfo
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import kotlin.math.max
import kotlin.math.sqrt

   
                                      
  
                                                         
                                                   
                                         
  
                                                               
                                                             
                              
   
object FavWidgetStore {
    private const val TAG = "FavWidget"
    private const val PREFS = "fav_widget_store"
    private const val KEY_TITLE = "folder_title"
    private const val KEY_ITEMS = "items"
    private const val KEY_CACHE_DIR = "cover_cache_dir"

                     
    const val MAX_ITEMS = 4

       
                    
      
                                                               
                                                     
                                                
       
    private const val TOTAL_PIXEL_BUDGET = 180_000

                               
    private const val TALL_ENOUGH_DP = 170

                                       
    const val ACTION_REFRESH = "widget_refresh"

                                        
    const val ACTION_PICK_FOLDER = "widget_pick_folder"

    data class Item(val title: String, val coverPath: String?, val bvid: String?)

    private val coverIds = intArrayOf(
        R.id.fav_cover_0, R.id.fav_cover_1, R.id.fav_cover_2, R.id.fav_cover_3,
    )
    private val titleIds = intArrayOf(
        R.id.fav_title_0, R.id.fav_title_1, R.id.fav_title_2, R.id.fav_title_3,
    )
    private val itemIds = intArrayOf(
        R.id.fav_item_0, R.id.fav_item_1, R.id.fav_item_2, R.id.fav_item_3,
    )

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

                                                                       

    fun save(context: Context, folderTitle: String, coverCacheDir: String?, items: List<Item>) {
        val arr = JSONArray()
        items.take(MAX_ITEMS).forEach { item ->
            arr.put(
                JSONObject().apply {
                    put("title", item.title)
                    put("cover", item.coverPath ?: JSONObject.NULL)
                    put("bvid", item.bvid ?: JSONObject.NULL)
                }
            )
        }
        prefs(context).edit()
            .putString(KEY_TITLE, folderTitle)
            .putString(KEY_ITEMS, arr.toString())
            .putString(KEY_CACHE_DIR, coverCacheDir)
            .apply()
    }

    fun folderTitle(context: Context): String {
        val raw = prefs(context).getString(KEY_TITLE, null)
        return if (raw.isNullOrBlank()) {
            context.getString(R.string.fav_widget_folder_fallback)
        } else {
            raw
        }
    }

    fun items(context: Context): List<Item> {
        val raw = prefs(context).getString(KEY_ITEMS, null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            (0 until arr.length()).mapNotNull { i ->
                val o = arr.optJSONObject(i) ?: return@mapNotNull null
                Item(
                    title = o.optString("title", ""),
                    coverPath = if (o.isNull("cover")) null else o.optString("cover"),
                    bvid = if (o.isNull("bvid")) null else o.optString("bvid"),
                )
            }
        } catch (t: Throwable) {
            Log.w(TAG, "读取小组件数据失败", t)
            emptyList()
        }
    }

                                    
    fun clearCoverFiles(context: Context) {
        val dir = prefs(context).getString(KEY_CACHE_DIR, null) ?: return
        runCatching { File(dir).deleteRecursively() }
            .onFailure { Log.w(TAG, "清理封面缓存失败: $dir", it) }
        prefs(context).edit()
            .remove(KEY_ITEMS)
            .remove(KEY_TITLE)
            .remove(KEY_CACHE_DIR)
            .apply()
    }

                                                                     

       
                                                    
                                            
       
    fun buildViews(context: Context, options: Bundle?): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.fav_widget)

        val minWidthDp =
            options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 250) ?: 250
        val minHeightDp =
            options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110) ?: 110
        val twoRows = minHeightDp >= TALL_ENOUGH_DP
        val slots = if (twoRows) MAX_ITEMS else 2

        views.setTextViewText(R.id.fav_widget_title, folderTitle(context))

        val stored = items(context).take(slots)
        val empty = stored.isEmpty()
        views.setViewVisibility(R.id.fav_widget_empty, if (empty) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.fav_widget_row1, if (empty) View.GONE else View.VISIBLE)
        views.setViewVisibility(
            R.id.fav_widget_row2,
            if (empty || !twoRows) View.GONE else View.VISIBLE,
        )

                                                     
        val density = context.resources.displayMetrics.density
        val colWidthDp = ((minWidthDp - 20 - 8) / 2).coerceAtLeast(60)
        var targetW = (colWidthDp * density).toInt().coerceIn(96, 360)
        var targetH = (targetW * 9 / 16).coerceAtLeast(54)
                               
        val perItem = TOTAL_PIXEL_BUDGET / slots.coerceAtLeast(1)
        if (targetW * targetH > perItem) {
            val scale = sqrt(perItem.toDouble() / (targetW * targetH))
            targetW = (targetW * scale).toInt().coerceAtLeast(64)
            targetH = (targetH * scale).toInt().coerceAtLeast(36)
        }

        for (i in 0 until MAX_ITEMS) {
            if (i >= slots || i >= stored.size) {
                views.setViewVisibility(itemIds[i], View.GONE)
                continue
            }
            val item = stored[i]
            val bitmap = decodeCover(item.coverPath, targetW, targetH)
            if (bitmap != null) {
                views.setImageViewBitmap(coverIds[i], bitmap)
            } else {
                                                            
                views.setImageViewResource(coverIds[i], R.drawable.fav_widget_cover_bg)
            }
            views.setTextViewText(titleIds[i], item.title)
            views.setOnClickPendingIntent(coverIds[i], videoPendingIntent(context, item.bvid, i))
            views.setOnClickPendingIntent(
                titleIds[i],
                videoPendingIntent(context, item.bvid, i + 100),
            )
        }

                                       
        views.setOnClickPendingIntent(
            R.id.fav_widget_title,
            openAppPendingIntent(context, ACTION_PICK_FOLDER, reqCode = 200),
        )
        views.setOnClickPendingIntent(
            R.id.fav_widget_empty,
            openAppPendingIntent(context, ACTION_PICK_FOLDER, reqCode = 202),
        )
                             
        views.setOnClickPendingIntent(
            R.id.fav_widget_refresh,
            openAppPendingIntent(context, ACTION_REFRESH, reqCode = 201),
        )

        return views
    }

                                                                     
    private fun videoPendingIntent(context: Context, bvid: String?, reqCode: Int): PendingIntent {
        val action = if (bvid.isNullOrBlank()) "recommend" else "video:$bvid"
        val intent = Intent(context, MainActivity::class.java).apply {
                                                                   
            this.action = "fav_widget_video_${bvid ?: "none"}_$reqCode"
            putExtra(MainActivity.ACTION_EXTRA, action)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        return PendingIntent.getActivity(
            context, reqCode, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

                                                   
    private fun openAppPendingIntent(
        context: Context,
        flashAction: String,
        reqCode: Int,
    ): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = "fav_widget_open_$reqCode"
            putExtra(MainActivity.ACTION_EXTRA, flashAction)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        return PendingIntent.getActivity(
            context, reqCode, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

                                                                     

    private fun decodeCover(path: String?, targetW: Int, targetH: Int): Bitmap? {
        if (path.isNullOrEmpty() || !File(path).exists()) return null
        return try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, bounds)
            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null

            var sample = 1
            while (
                bounds.outWidth / (sample * 2) >= targetW &&
                bounds.outHeight / (sample * 2) >= targetH
            ) {
                sample *= 2
            }
            val decoded = BitmapFactory.decodeFile(
                path,
                BitmapFactory.Options().apply {
                    inSampleSize = sample
                    inPreferredConfig = Bitmap.Config.ARGB_8888
                },
            ) ?: return null

                                                 
                                                  
            val ratio = minOf(
                targetW.toFloat() / decoded.width,
                targetH.toFloat() / decoded.height,
            )
            if (ratio >= 1f) return decoded
            val w = max(1, (decoded.width * ratio).toInt())
            val h = max(1, (decoded.height * ratio).toInt())
            val scaled = Bitmap.createScaledBitmap(decoded, w, h, true)
            if (scaled !== decoded) decoded.recycle()
            scaled
        } catch (t: Throwable) {
            Log.w(TAG, "封面解码失败: $path", t)
            null
        }
    }

                                                                       

    fun widgetIds(context: Context): IntArray =
        AppWidgetManager.getInstance(context).getAppWidgetIds(
            ComponentName(context, FavWidgetProvider::class.java),
        )

                      
    fun updateAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        widgetIds(context).forEach { id ->
            runCatching {
                manager.updateAppWidget(id, buildViews(context, manager.getAppWidgetOptions(id)))
            }.onFailure { Log.w(TAG, "刷新小组件 $id 失败", it) }
        }
    }

       
                                           
                                  
                                             
       
    fun publishGeneratedPreview(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.VANILLA_ICE_CREAM) return
        runCatching {
            AppWidgetManager.getInstance(context).setWidgetPreview(
                ComponentName(context, FavWidgetProvider::class.java),
                AppWidgetProviderInfo.WIDGET_CATEGORY_HOME_SCREEN,
                buildViews(
                    context,
                    Bundle().apply {
                        putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 250)
                        putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110)
                    },
                ),
            )
        }.onFailure { Log.w(TAG, "生成微件预览失败", it) }
    }
}
