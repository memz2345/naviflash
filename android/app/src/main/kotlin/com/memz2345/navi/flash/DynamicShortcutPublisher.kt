package com.memz2345.navi.flash

import android.content.Context
import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import android.os.Build
import android.util.Log

   
                          
  
                                            
                                    
                                     
                                           
                    
  
                                                
                                                   
                                                                    
                                          
                                                                             
                                                    
                                       
             
  
                                               
   
object DynamicShortcutPublisher {
    private const val TAG = "ShortcutPublisher"

                                              
    private const val ID_PREFIX = "dyn_"

    fun publish(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N_MR1) return
        val manager = context.getSystemService(ShortcutManager::class.java) ?: return

        val ids = readConfiguredIds(context)
        val packageName = context.packageName

        val infos = ids.mapIndexed { rank, id ->
            val entry = ShortcutCatalog.entryOf(id) ?: return@mapIndexed null
            val intent = Intent(
                context,
                MainActivity::class.java,
            ).apply {
                action = "com.memz2345.navi.flash.action.SHORTCUT"
                putExtra(MainActivity.ACTION_EXTRA, entry.action)
            }
            @Suppress("DEPRECATION")
            ShortcutInfo.Builder(context, "$ID_PREFIX${entry.id}")
                .setShortLabel(context.getString(entry.shortLabel))
                .setLongLabel(context.getString(entry.longLabel))
                .setIcon(Icon.createWithResource(packageName, entry.icon))
                .setIntent(intent)
                .setRank(rank)
                .build()
        }.filterNotNull()

                             
                                                  
                                            
                          
        val ok = try {
            manager.setDynamicShortcuts(infos)
        } catch (e: Throwable) {
            Log.w(TAG, "setDynamicShortcuts 异常，清空动态项后重发", e)
            try {
                manager.removeAllDynamicShortcuts()
                manager.setDynamicShortcuts(infos)
            } catch (e2: Throwable) {
                Log.w(TAG, "清空后重发仍失败", e2)
                false
            }
        }
        if (ok) {
            Log.i(TAG, "已发布 ${infos.size} 项动态快捷方式: ${ids.joinToString()}")
        } else {
                                             
            Log.w(TAG, "setDynamicShortcuts 被系统限流或拒绝（${infos.size} 项）")
        }
    }

                                    
    private fun readConfiguredIds(context: Context): List<String> {
        val prefs = context.getSharedPreferences(
            "FlutterSharedPreferences",
            Context.MODE_PRIVATE,
        )
        val raw = prefs.getString(ShortcutCatalog.PREFS_KEY, null)
            ?: return ShortcutCatalog.DEFAULT_IDS
        val ids = raw.split(",").map { it.trim() }.filter { it.isNotEmpty() }.distinct()
        return ids
            .filter { ShortcutCatalog.entryOf(it) != null }
            .take(ShortcutCatalog.MAX_SHORTCUTS)
            .ifEmpty { ShortcutCatalog.DEFAULT_IDS }
    }
}
