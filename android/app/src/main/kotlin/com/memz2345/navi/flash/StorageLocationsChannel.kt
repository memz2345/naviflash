package com.memz2345.navi.flash

import android.content.Context
import android.os.Build
import android.os.Environment
import android.os.StatFs
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

   
                       
  
                                               
      
                                                                                         
                                                                        
  
              
                                                        
                                     
                                            
                                               
                                                  
                                                   
                                             
                                                
   
class StorageLocationsChannel(private val context: Context) {

    companion object {
        private const val CHANNEL_NAME = "com.memz2345.navi.flash/storage_locations"

                                        
        private val MEDIA_TYPES = listOf(
            Environment.DIRECTORY_MOVIES to "电影",
            Environment.DIRECTORY_DOWNLOADS to "下载",
            Environment.DIRECTORY_DOCUMENTS to "文档",
            Environment.DIRECTORY_MUSIC to "音乐",
            Environment.DIRECTORY_PICTURES to "图片",
            Environment.DIRECTORY_DCIM to "相机 (DCIM)"
        )

                                         
        private val MODEL_TYPES = listOf(
            Environment.DIRECTORY_DOCUMENTS to "文档",
            Environment.DIRECTORY_DOWNLOADS to "下载"
        )
    }

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL_NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "listCandidates" -> result.success(
                    listCandidates(call.argument<String>("slot") ?: "video")
                )
                "pathInfo" -> {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.error("BAD_ARGS", "path is null", null)
                    } else {
                        result.success(pathInfo(path))
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun listCandidates(slot: String): List<Map<String, Any?>> {
        val out = ArrayList<Map<String, Any?>>()
        val seen = HashSet<String>()

                                     
        val internal = context.filesDir
        if (internal != null) {
                out.add(
                    buildEntry(
                        dir = internal,
                        label = "内部存储",
                        detail = "应用私有 data，卸载时删除"
                    )
                )
            seen.add(internal.absolutePath)
        }

                                       
        val volumes = ContextCompat.getExternalFilesDirs(context, null)
        for (volume in volumes) {
            if (volume == null) continue
            val volLabel = volumeLabel(volume)
            val types = if (slot == "models") MODEL_TYPES else MEDIA_TYPES

                           
            if (seen.add(volume.absolutePath)) {
                out.add(
                    buildEntry(
                        dir = volume,
                        label = volLabel,
                        detail = "应用专属目录（$volLabel）"
                    )
                )
            }

            for ((type, label) in types) {
                val dir = ContextCompat.getExternalFilesDirs(context, type)
                    .firstOrNull { it != null && it.absolutePath.startsWith(volume.absolutePath) }
                    ?: File(volume, type).takeIf { it.exists() || it.mkdirs() }
                if (dir == null) continue
                val path = dir.absolutePath
                if (!seen.add(path)) continue
                out.add(
                    buildEntry(
                        dir = dir,
                        label = label,
                        detail = "$volLabel · $label"
                    )
                )
            }
        }

        return out
    }

    private fun buildEntry(dir: File, label: String, detail: String): Map<String, Any?> {
        val (free, total) = spaceOf(dir)
        return mapOf(
            "path" to dir.absolutePath,
            "label" to label,
            "detail" to detail,
            "freeBytes" to free,
            "totalBytes" to total,
            "writable" to isWritable(dir)
        )
    }

                                    
    private fun isWritable(dir: File): Boolean {
        return try {
            if (!dir.exists() && !dir.mkdirs()) return false
            val probe = File(dir, ".naviflash_write_probe")
            probe.writeText("1")
            val ok = probe.exists()
            probe.delete()
            ok
        } catch (_: Throwable) {
            false
        }
    }

    private fun pathInfo(path: String): Map<String, Any?> {
        val dir = File(path)
        val (free, total) = spaceOf(dir)
        return mapOf(
            "path" to dir.absolutePath,
            "exists" to dir.exists(),
            "writable" to isWritable(dir),
            "freeBytes" to free,
            "totalBytes" to total
        )
    }

    private fun spaceOf(dir: File): Pair<Long?, Long?> {
        val probe = if (dir.exists()) dir else (dir.parentFile ?: dir)
        return try {
            val stat = StatFs(probe.absolutePath)
            val total = stat.blockCountLong * stat.blockSizeLong
            val free = stat.availableBlocksLong * stat.blockSizeLong
            free to total
        } catch (_: Throwable) {
            null to null
        }
    }

                               
    private fun volumeLabel(dir: File): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            try {
                if (Environment.isExternalStorageRemovable(dir)) "外置 SD 卡" else "内部共享存储"
            } catch (_: Throwable) {
                "内部共享存储"
            }
        } else {
            "内部共享存储"
        }
    }
}
