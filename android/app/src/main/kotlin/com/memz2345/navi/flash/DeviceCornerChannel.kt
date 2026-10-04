package com.memz2345.navi.flash

import android.app.Activity
import android.os.Build
import android.util.Log
import android.view.RoundedCorner
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

   
                       
  
                                            
      
                                                                  
  
                                            
                                        
                                      
  
                                             
                                                                               
                               
                                                                                                     
                                                                
                                                    
                                                                   
                                     
  
                                                               
                                        
  
                                          
                 
   
object DeviceCornerChannel {

    private const val CHANNEL_NAME = "com.memz2345.navi.flash/device_corners"
    private const val TAG = "DeviceCorner"

    private val CORNER_POSITIONS = intArrayOf(
        RoundedCorner.POSITION_TOP_LEFT,
        RoundedCorner.POSITION_TOP_RIGHT,
        RoundedCorner.POSITION_BOTTOM_LEFT,
        RoundedCorner.POSITION_BOTTOM_RIGHT,
    )

                                                     
    private val RADIUS_RESOURCES = arrayOf(
        "config_roundedCornerRadius",
        "config_roundedCornerTopRadius",
        "config_roundedCornerBottomRadius",
        "config_mainBuiltInDisplayRoundedCornerRadius",
    )

    fun register(activity: Activity, messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL_NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCornerRadius" -> {
                    val (radiusDp, source) = detect(activity)
                                                       
                    Log.i(
                        TAG,
                        "屏幕圆角 ${radiusDp}dp（来源 $source）" +
                            " insets=${insetsPx(activity)}" +
                            " display=${displayPx(activity)}" +
                            " res=${resourcePx(activity)}" +
                            " density=${activity.resources.displayMetrics.density}"
                    )
                    result.success(
                        mapOf("radiusDp" to radiusDp, "source" to source)
                    )
                }
                else -> result.notImplemented()
            }
        }
    }

                                                
    private fun detect(activity: Activity): Pair<Double, String> {
        val windowInsetsPx = insetsPx(activity)
        if (windowInsetsPx > 0) return toDp(activity, windowInsetsPx) to "windowInsets"

        val displayPx = displayPx(activity)
        if (displayPx > 0) return toDp(activity, displayPx) to "display"

        val resourcePx = resourcePx(activity)
        if (resourcePx > 0) return toDp(activity, resourcePx) to "resource"

        return 0.0 to "none"
    }

    fun insetsPx(activity: Activity): Int =
        runCatching { fromWindowInsets(activity) }.getOrDefault(0)

    fun displayPx(activity: Activity): Int =
        runCatching { fromDisplay(activity) }.getOrDefault(0)

    fun resourcePx(activity: Activity): Int =
        runCatching { fromResource(activity) }.getOrDefault(0)

    private fun toDp(activity: Activity, px: Int): Double {
        val density = activity.resources.displayMetrics.density
        val safeDensity = if (density > 0f) density.toDouble() else 1.0
        return px / safeDensity
    }

                                        
    private fun fromWindowInsets(activity: Activity): Int {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return 0
        val insets = activity.windowManager.currentWindowMetrics.windowInsets
        return maxRadiusOf { insets.getRoundedCorner(it) }
    }

                                                
    @Suppress("DEPRECATION")
    private fun fromDisplay(activity: Activity): Int {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return 0
        val display = activity.display ?: return 0
        return maxRadiusOf { display.getRoundedCorner(it) }
    }

    private inline fun maxRadiusOf(cornerAt: (Int) -> RoundedCorner?): Int {
        var max = 0
        for (position in CORNER_POSITIONS) {
            val radius = runCatching { cornerAt(position)?.radius }.getOrNull() ?: 0
            if (radius > max) max = radius
        }
        return max
    }

                                        
    private fun fromResource(activity: Activity): Int {
        val res = activity.resources
        for (name in RADIUS_RESOURCES) {
            val id = res.getIdentifier(name, "dimen", "android")
            if (id == 0) continue
            val px = runCatching { res.getDimensionPixelSize(id) }.getOrDefault(0)
            if (px > 0) return px
        }
        return 0
    }
}
