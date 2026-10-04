package com.memz2345.navi.flash

import android.app.Activity
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.drawable.BitmapDrawable
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.ViewGroup
import android.widget.ImageView
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

   
                   
  
                                    
      
                                                 
                                                          
                                                 
  
                                                                                      
                                                                         
                                            
                                                     
                                             
                                                           
                           
  
                                                       
                                      
   
object SplashChannel {

    private const val CHANNEL_NAME = "com.memz2345.navi.flash/splash"
    private const val FILE_NAME = "splash_background.img"

                                 
    private const val HOLD_AFTER_FIRST_FRAME_MS = 600L
                                
    private const val SAFETY_REMOVE_MS = 4000L
    private const val FADE_OUT_MS = 250L

    private val mainHandler = Handler(Looper.getMainLooper())
    private val ioExecutor: ExecutorService =
        Executors.newSingleThreadExecutor { r -> Thread(r, "splash-io") }

                                              
    private var overlay: ImageView? = null

    fun backgroundFile(context: Context): File =
        File(context.filesDir, FILE_NAME)

    fun register(context: Context, messenger: BinaryMessenger) {
        val appContext = context.applicationContext
        MethodChannel(messenger, CHANNEL_NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasBackground" -> {
                    result.success(backgroundFile(appContext).exists())
                }
                "setBackground" -> {
                    val path = call.argument<String>("path")
                    if (path.isNullOrBlank()) {
                        result.error("INVALID_ARG", "path is null", null)
                        return@setMethodCallHandler
                    }
                                                         
                    ioExecutor.execute {
                        val ok = try {
                            copyInto(appContext, backgroundFile(appContext), path)
                        } catch (_: Throwable) {
                            false
                        }
                        mainHandler.post { result.success(ok) }
                    }
                }
                "clearBackground" -> {
                    val ok = try {
                        val f = backgroundFile(appContext)
                        if (f.exists()) f.delete() else true
                    } catch (_: Throwable) {
                        false
                    }
                    result.success(ok)
                }
                else -> result.notImplemented()
            }
        }
    }

       
                                                           
      
                                                          
                                                   
                                                    
                                                 
       
    fun apply(activity: Activity) {
        val file = backgroundFile(activity)
        if (!file.exists()) return
        ioExecutor.execute {
            val bmp = try {
                decodeScreenSized(activity, file)
            } catch (_: Throwable) {
                null
            } ?: return@execute
            mainHandler.post {
                if (activity.isFinishing || activity.isDestroyed) return@post
                                                           
                activity.window.setBackgroundDrawable(
                    BitmapDrawable(activity.resources, bmp).apply {
                        gravity = Gravity.FILL
                    },
                )
                showOverlay(activity, bmp)
                mainHandler.postDelayed(
                    { removeOverlay() },
                    SAFETY_REMOVE_MS,
                )
            }
        }
    }

                                                                
    fun onFlutterUiDisplayed() {
        if (overlay == null) return
        mainHandler.postDelayed(
            { removeOverlay() },
            HOLD_AFTER_FIRST_FRAME_MS,
        )
    }

    private fun showOverlay(activity: Activity, bmp: Bitmap) {
        val root = activity.findViewById<ViewGroup>(android.R.id.content) ?: return
        val iv = ImageView(activity).apply {
            setImageBitmap(bmp)
            scaleType = ImageView.ScaleType.FIT_CENTER
            setBackgroundColor(ContextCompat.getColor(activity, R.color.splash_background))
        }
        overlay = iv
        root.addView(
            iv,
            ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )
    }

    private fun removeOverlay() {
        val iv = overlay ?: return
        overlay = null
        iv.animate()
            .alpha(0f)
            .setDuration(FADE_OUT_MS)
            .withEndAction { (iv.parent as? ViewGroup)?.removeView(iv) }
            .start()
    }

                                             
    private fun copyInto(context: Context, dst: File, source: String): Boolean {
        val tmp = File(dst.parentFile, dst.name + ".tmp")
        try {
            val input = if (source.startsWith("content:")) {
                context.contentResolver.openInputStream(Uri.parse(source))
            } else {
                FileInputStream(File(source))
            } ?: return false
            input.use { ins ->
                tmp.outputStream().use { ins.copyTo(it, 64 * 1024) }
            }
            if (tmp.length() == 0L) {
                tmp.delete()
                return false
            }
                                              
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(tmp.absolutePath, bounds)
            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) {
                tmp.delete()
                return false
            }
            if (dst.exists()) dst.delete()
            return tmp.renameTo(dst)
        } catch (_: Throwable) {
            try {
                if (tmp.exists()) tmp.delete()
            } catch (_: Throwable) {
            }
            return false
        }
    }

                                    
    private fun decodeScreenSized(context: Context, file: File): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(file.absolutePath, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
        val dm = context.resources.displayMetrics
        val target = maxOf(dm.widthPixels, dm.heightPixels)
        var sample = 1
        val maxEdge = maxOf(bounds.outWidth, bounds.outHeight)
        while (maxEdge / sample > target) sample *= 2
        return BitmapFactory.decodeFile(
            file.absolutePath,
            BitmapFactory.Options().apply { inSampleSize = sample },
        )
    }
}
