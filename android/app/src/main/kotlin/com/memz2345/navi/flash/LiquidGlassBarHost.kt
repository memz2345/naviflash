package com.memz2345.navi.flash

import android.app.Activity
import android.graphics.Bitmap
import android.graphics.ColorSpace
import android.graphics.Rect
import android.hardware.HardwareBuffer
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.view.Choreographer
import android.view.Gravity
import android.view.PixelCopy
import android.view.SurfaceView
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.EaseOut
import androidx.compose.animation.core.spring
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Circle
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.State
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.platform.LocalViewConfiguration
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.util.fastCoerceIn
import androidx.compose.ui.util.fastRoundToInt
import androidx.compose.ui.util.lerp
import com.kyant.backdrop.Backdrop
import com.kyant.backdrop.backdrops.layerBackdrop
import com.kyant.backdrop.backdrops.rememberCanvasBackdrop
import com.kyant.backdrop.backdrops.rememberCombinedBackdrop
import com.kyant.backdrop.backdrops.rememberLayerBackdrop
import com.kyant.backdrop.drawBackdrop
import com.kyant.backdrop.effects.blur
import com.kyant.backdrop.effects.lens
import com.kyant.backdrop.effects.vibrancy
import com.kyant.backdrop.highlight.Highlight
import com.kyant.backdrop.shadow.InnerShadow
import com.kyant.backdrop.shadow.Shadow
import com.kyant.shapes.Capsule
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.launch
import kotlin.math.abs
import kotlin.math.roundToInt
import kotlin.math.sign

   
                                          
   
data class LiquidBarTab(
    val id: String,
    val label: String,
    val iconCodePoint: Int?,
    val iconFontFamily: String?,
    val selectedIconCodePoint: Int?,
)

   
                                        
  
                                                  
                                         
   
data class BackdropFrame(
    val image: ImageBitmap,
    val srcLeftPx: Int,
    val srcTopPx: Int,
)

   
                      
  
                                                 
           
                                                                
                                                               
                                                                 
                                                 
  
                                              
                                                                   
  
                                                
                          
   
object LiquidGlassBarHost {

    private const val TAG = "LiquidGlassBarHost"
    const val CHANNEL_NAME = "com.memz2345.navi.flash/liquid_bar"

       
                                 
      
                                                        
                        
                                                     
                                                                  
                                             
                                                 
                                                                
                                           
      
                                            
                                             
                                                           
                                          
       
    private const val BACKDROP_ACTIVE_MIN_GAP_MS = 24L
    private const val BACKDROP_INTERVAL_IDLE_MS = 500L
    private const val BACKDROP_ACTIVE_WINDOW_MS = 700L

                            
    private const val BACKDROP_PAD_DP = 40f

       
                     
      
                                                   
                                               
                              
       
    private const val BACKDROP_MAX_COMPENSATION_DP = 16f

       
                      
      
                                                       
                                                     
                                       
       
    private const val INDICATOR_OVERFLOW_DP = 20f

       
                                                  
                                                  
                                         
                                         
                                                     
      
                                                            
                                  
       
    private const val TAB_WIDTH_DP = 76f
    private const val BOTTOM_GAP_DP = 12f
    private const val INNER_PAD_DP = 4f

    private val handler = Handler(Looper.getMainLooper())

    private var channel: MethodChannel? = null
    private var hostRoot: ViewGroup? = null
    private var hostView: View? = null
    private var hostOwner: ComposeHostOwner? = null

    private var tabs: List<LiquidBarTab> = emptyList()
    private var indexState: MutableState<Int>? = null
    private var backdropState: MutableState<BackdropFrame?>? = null

       
                                           
                         
      
                                           
                                                          
                                        
      
                                                     
                                  
       
    private var scrollOffsetState: MutableState<Float>? = null

                                                       
    private var captureScrollBaselinePx = 0f

    private var barHeightPx = 0
    private var surfaceView: SurfaceView? = null

                                                     
                                                
    private val backdropBuffers = arrayOfNulls<Bitmap>(3)
    private var backdropBufferCursor = 0
    private var backdropBufferW = 0
    private var backdropBufferH = 0

                                                                   
                                                               
                   
    private val hwBuffers = arrayOfNulls<HardwareBuffer>(3)
    private val hwBitmaps = arrayOfNulls<Bitmap>(3)
    private var hwBufferCursor = 0
    private var hwBufferW = 0
    private var hwBufferH = 0

       
                                                      
                                              
                                    
       
    private var hwPixelCopySupported: Boolean? = null

                                                 
    private var lastRefreshRequestAt = 0L

                                         
                                              
                 
    private var hostWidthPx = 0
    private var hostHeightPx = 0
    private var capsuleTopPx = 0
    private var capsuleLeftPx = 0
    private var capsuleWidthPx = 0
    private var capsuleHeightPx = 0
    private var backdropPadPx = 0
    private var backdropTopPx = 0
    private var activityRef: Activity? = null

                                                               
    private var maxCompensationPx = 0f

                                   
                                
    private var backdropLoopRunning = false

                                                 
    private var copyInFlight = false

                                     
    private var lastCaptureStartedAt = 0L

    private val choreographer = Choreographer.getInstance()

                                        
    private val activeFrameCallback = object : Choreographer.FrameCallback {
        override fun doFrame(frameTimeNanos: Long) {
            tickActive()
        }
    }

                                
    private val idleTick = Runnable { captureBackdrop() }

                                      
    private var loggedCopyFailure = false
    private var loggedPixelSample = false

    fun install(activity: Activity, messenger: BinaryMessenger) {
        val ch = MethodChannel(messenger, CHANNEL_NAME)
        channel = ch
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "showBar" -> result.success(show(activity, call.arguments as? Map<*, *>))
                "updateIndex" -> {
                    val idx = (call.arguments as? Map<*, *>?)?.get("index") as? Number
                    indexState?.value = idx?.toInt() ?: 0
                    result.success(null)
                }
                "refresh" -> {
                                                   
                    lastRefreshRequestAt = SystemClock.uptimeMillis()
                                                     
                                                  
                    val dyDp =
                        (call.arguments as? Map<*, *>?)?.get("scrollDelta") as? Number
                    val scrollState = scrollOffsetState
                    if (dyDp != null && scrollState != null) {
                        val density =
                            activityRef?.resources?.displayMetrics?.density ?: 1f
                                                       
                                                            
                        val limit = maxCompensationPx * 4f
                        scrollState.value = (scrollState.value + dyDp.toFloat() * density)
                            .fastCoerceIn(-limit, limit)
                    }
                                                   
                    handler.removeCallbacks(idleTick)
                    captureBackdrop()
                    result.success(null)
                }
                "hideBar" -> {
                    Log.d(TAG, "hideBar（首页被盖住 / 离开）")
                    dismiss()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    fun dispose() {
        channel?.setMethodCallHandler(null)
        channel = null
        dismiss()
    }

    fun dismiss() {
        stopBackdropLoop()
        releaseBackdropBuffers()
        val root = hostRoot
        val view = hostView
        val owner = hostOwner
        hostRoot = null
        hostView = null
        hostOwner = null
        indexState = null
        backdropState = null
        scrollOffsetState = null
        captureScrollBaselinePx = 0f
        surfaceView = null
        activityRef = null
        if (root != null && view != null && view.parent === root) {
            root.removeView(view)
        }
        owner?.destroy()
    }

                                                         
    private fun releaseBackdropBuffers() {
        backdropBuffers.fill(null)
        backdropBufferCursor = 0
        backdropBufferW = 0
        backdropBufferH = 0
        for (i in hwBitmaps.indices) {
            runCatching { hwBitmaps[i]?.recycle() }
            hwBitmaps[i] = null
            runCatching { hwBuffers[i]?.close() }
            hwBuffers[i] = null
        }
        hwBufferCursor = 0
        hwBufferW = 0
        hwBufferH = 0
    }

    private fun show(activity: Activity, args: Map<*, *>?): Boolean {
        if (args == null) return false
        val parsed = parseTabs(args["tabs"])
        if (parsed.isEmpty()) return false

        dismiss()

        val density = activity.resources.displayMetrics.density
        val bottomInset = ((args["bottomInset"] as? Number)?.toFloat() ?: 0f) * density
        val barHeight = ((args["height"] as? Number)?.toFloat() ?: 64f) * density
                                                    
                                                
        val overflowPx = (INDICATOR_OVERFLOW_DP * density).roundToInt()
        val bottomGapPx = (BOTTOM_GAP_DP * density).roundToInt()
        barHeightPx = (barHeight.toInt() + bottomGapPx + bottomInset.toInt() + overflowPx)
            .coerceAtLeast(1)
        val dark = args["dark"] as? Boolean ?: false
        val accent = (args["accent"] as? Number)?.toInt()
        val startIndex = (args["index"] as? Number)?.toInt() ?: 0

        val root = activity.findViewById<ViewGroup>(android.R.id.content) ?: return false
        tabs = parsed
        val idx = mutableStateOf(startIndex)
        val backdrop = mutableStateOf<BackdropFrame?>(null)
        val scrollOffset = mutableFloatStateOf(0f)
        indexState = idx
        backdropState = backdrop
        scrollOffsetState = scrollOffset
        val surface = findSurfaceView(root)
        surfaceView = surface
        activityRef = activity

                              
                                               
                                                  
                                          
        val hostW = listOf(surface?.width, root.width)
            .firstOrNull { it != null && it > 0 }
            ?: activity.resources.displayMetrics.widthPixels
        val hostH = listOf(surface?.height, root.height)
            .firstOrNull { it != null && it > 0 }
            ?: activity.resources.displayMetrics.heightPixels
        hostWidthPx = hostW
        hostHeightPx = hostH
        val insetPx = bottomInset.roundToInt()
        val targetW = (parsed.size * TAB_WIDTH_DP * density).roundToInt()
        val capsuleW = targetW.coerceAtMost(hostW)
        capsuleWidthPx = capsuleW
        capsuleLeftPx = (hostW - capsuleW) / 2
        capsuleHeightPx = barHeight.roundToInt().coerceAtLeast(1)
        capsuleTopPx = (hostH - insetPx - bottomGapPx - capsuleHeightPx).coerceAtLeast(0)
        backdropPadPx = (BACKDROP_PAD_DP * density).roundToInt()
        backdropTopPx = capsuleTopPx
        maxCompensationPx = BACKDROP_MAX_COMPENSATION_DP * density
        loggedCopyFailure = false
        Log.d(
            TAG,
            "show: surface=$surface host=${hostW}x$hostH capsule=($capsuleLeftPx,$capsuleTopPx," +
                "${capsuleW}x$capsuleHeightPx) inset=$insetPx gap=$bottomGapPx",
        )

        val ch = channel
        val view = ComposeView(activity)
        val owner = ComposeHostOwner()
        owner.start()
        owner.attachTo(view)
        view.setContent {
            MaterialTheme(colorScheme = barColorScheme(dark)) {
                LiquidGlassBar(
                    tabs = tabs,
                    index = idx.value,
                                                         
                    backdropSource = backdrop,
                    scrollCompensation = scrollOffset,
                    nodeLeftPx = capsuleLeftPx,
                    nodeTopPx = capsuleTopPx,
                    barHeightDp = barHeight / density,
                    bottomInsetDp = bottomInset / density,
                    bottomGapDp = bottomGapPx / density,
                    accent = accent?.let { Color(it) },
                                                  
                                                    
                                                        
                    onSelect = { i ->
                        if (i != idx.value) idx.value = i
                        ch?.invokeMethod("onTabSelected", mapOf("index" to i))
                    },
                )
            }
        }
        root.addView(
            view,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                barHeightPx,
                Gravity.BOTTOM,
            ),
        )
        hostRoot = root
        hostView = view
        hostOwner = owner

                                         
        startBackdropLoop()
        return true
    }

       
                                       
      
                                                 
                                              
                                                
                          
       
    private fun startBackdropLoop() {
        stopBackdropLoop()
        backdropLoopRunning = true
        copyInFlight = false
                                     
        lastRefreshRequestAt = SystemClock.uptimeMillis()
        lastCaptureStartedAt = 0L
                              
        handler.postDelayed(
            { if (backdropLoopRunning) scheduleNextCapture() },
            120,
        )
    }

    private fun stopBackdropLoop() {
        backdropLoopRunning = false
        choreographer.removeFrameCallback(activeFrameCallback)
        handler.removeCallbacks(idleTick)
    }

                                         
    private fun scheduleNextCapture() {
        if (!backdropLoopRunning) return
        val active = SystemClock.uptimeMillis() - lastRefreshRequestAt <
            BACKDROP_ACTIVE_WINDOW_MS
        if (active) {
            choreographer.postFrameCallback(activeFrameCallback)
        } else {
            handler.postDelayed(idleTick, BACKDROP_INTERVAL_IDLE_MS)
        }
    }

                                                        
    private fun activeMinGapMs(): Long = if (hwPixelCopySupported == true) {
        16L
    } else {
        BACKDROP_ACTIVE_MIN_GAP_MS
    }

                                         
    private fun tickActive() {
        if (!backdropLoopRunning) return
        val now = SystemClock.uptimeMillis()
        if (copyInFlight || now - lastCaptureStartedAt < activeMinGapMs()) {
            choreographer.postFrameCallback(activeFrameCallback)
            return
        }
        captureBackdrop()
    }

       
                                
      
                                                
                                               
       
    private fun acquireBuffer(w: Int, h: Int): Bitmap {
        if (backdropBufferW != w || backdropBufferH != h) {
            backdropBuffers.fill(null)
            backdropBufferW = w
            backdropBufferH = h
            backdropBufferCursor = 0
        }
        backdropBufferCursor = (backdropBufferCursor + 1) % backdropBuffers.size
        val existing = backdropBuffers[backdropBufferCursor]
        if (existing != null) return existing
        return Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888).also {
            backdropBuffers[backdropBufferCursor] = it
        }
    }

       
                                                  
                                                               
                                                      
                                             
       
    private fun acquireHwBuffer(w: Int, h: Int): Pair<Bitmap, HardwareBuffer> {
        if (hwBufferW != w || hwBufferH != h) {
            for (i in hwBitmaps.indices) {
                runCatching { hwBitmaps[i]?.recycle() }
                hwBitmaps[i] = null
                runCatching { hwBuffers[i]?.close() }
                hwBuffers[i] = null
            }
            hwBufferW = w
            hwBufferH = h
            hwBufferCursor = 0
        }
        hwBufferCursor = (hwBufferCursor + 1) % hwBuffers.size
        val slot = hwBufferCursor
        val cachedBmp = hwBitmaps[slot]
        val cachedBuf = hwBuffers[slot]
        if (cachedBmp != null && cachedBuf != null && !cachedBmp.isRecycled) {
            return cachedBmp to cachedBuf
        }
        val buf = HardwareBuffer.create(
            w,
            h,
            HardwareBuffer.RGBA_8888,
                           1,
            HardwareBuffer.USAGE_GPU_SAMPLED_IMAGE or
                HardwareBuffer.USAGE_GPU_COLOR_OUTPUT,
        )
        val bmp = Bitmap.wrapHardwareBuffer(
            buf,
            ColorSpace.get(ColorSpace.Named.SRGB),
        ) ?: run {
            buf.close()
            error("Bitmap.wrapHardwareBuffer 返回 null")
        }
        hwBuffers[slot] = buf
        hwBitmaps[slot] = bmp
        return bmp to buf
    }

       
                                    
      
                                                        
                                                 
                                        
      
                                                           
                                             
       
    private fun captureBackdrop() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
                                              
        if (copyInFlight) return
        val state = backdropState ?: return
        val surface = surfaceView
        val surfaceW = surface?.width ?: 0
        val surfaceH = surface?.height ?: 0
                                                 
                                                              
        val availW = if (surfaceW > 0) minOf(hostWidthPx, surfaceW) else hostWidthPx
        val availH = if (surfaceH > 0) minOf(hostHeightPx, surfaceH) else hostHeightPx
        val capW = capsuleWidthPx
        val capH = capsuleHeightPx
        if (capW <= 0 || capH <= 0 || availW <= 0 || availH <= 0) return
        val pad = backdropPadPx
        val left = (capsuleLeftPx - pad).coerceAtLeast(0)
        val top = (capsuleTopPx - pad).coerceAtLeast(0)
        val right = (capsuleLeftPx + capW + pad).coerceAtMost(availW)
        val bottom = (capsuleTopPx + capH + pad).coerceAtMost(availH)
        if (right - left < capW || bottom - top < capH) return
        val bmpW = right - left
        val bmpH = bottom - top
        backdropTopPx = top
        val rect = Rect(left, top, right, bottom)

                                                                   
                      
        val canUseHw = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P &&
            surface != null && surfaceW >= right && surfaceH >= bottom &&
            hwPixelCopySupported != false

        if (canUseHw) {
                                    
            val pair = runCatching { acquireHwBuffer(bmpW, bmpH) }.getOrElse {
                captureViaBitmap(state, surface, surfaceW, surfaceH, rect, left, top, bmpW, bmpH)
                return
            }
            val bmp = pair.first
            copyInFlight = true
            lastCaptureStartedAt = SystemClock.uptimeMillis()
                                          
                                            
            captureScrollBaselinePx = scrollOffsetState?.value ?: 0f
            val finish = PixelCopy.OnPixelCopyFinishedListener { result ->
                copyInFlight = false
                                                       
                if (!backdropLoopRunning || backdropState == null) {
                    return@OnPixelCopyFinishedListener
                }
                if (result == PixelCopy.SUCCESS) {
                                           
                    hwPixelCopySupported = true
                    settleScrollCompensation()
                    state.value = BackdropFrame(
                        image = bmp.asImageBitmap(),
                        srcLeftPx = left,
                        srcTopPx = top,
                    )
                } else if (hwPixelCopySupported == null) {
                                                    
                    Log.i(TAG, "PixelCopy 不支持 HARDWARE Bitmap（result=$result），用 CPU 路径")
                    disableHwCopy()
                    captureViaBitmap(state, surface, surfaceW, surfaceH, rect, left, top, bmpW, bmpH)
                    return@OnPixelCopyFinishedListener
                } else if (!loggedCopyFailure) {
                    loggedCopyFailure = true
                    Log.w(TAG, "PixelCopy(HARDWARE) 失败 result=$result rect=$rect")
                }
                scheduleNextCapture()
            }
            runCatching {
                PixelCopy.request(surface, rect, bmp, finish, handler)
            }.onFailure {
                copyInFlight = false
                if (hwPixelCopySupported == null) {
                                                      
                    Log.i(TAG, "PixelCopy 拒绝 HARDWARE Bitmap，用 CPU 路径", it)
                    disableHwCopy()
                    captureViaBitmap(state, surface, surfaceW, surfaceH, rect, left, top, bmpW, bmpH)
                } else {
                    Log.w(TAG, "PixelCopy(HARDWARE) 抛异常", it)
                    scheduleNextCapture()
                }
            }
            return
        }

                              
        captureViaBitmap(state, surface, surfaceW, surfaceH, rect, left, top, bmpW, bmpH)
    }

       
                                      
                                
       
    private fun settleScrollCompensation() {
        val state = scrollOffsetState ?: return
        state.value = state.value - captureScrollBaselinePx
        captureScrollBaselinePx = 0f
    }

                                
    private fun disableHwCopy() {
        hwPixelCopySupported = false
        for (i in hwBitmaps.indices) {
            runCatching { hwBitmaps[i]?.recycle() }
            hwBitmaps[i] = null
            runCatching { hwBuffers[i]?.close() }
            hwBuffers[i] = null
        }
        hwBufferCursor = 0
        hwBufferW = 0
        hwBufferH = 0
    }


                                              
    private fun captureViaBitmap(
        state: MutableState<BackdropFrame?>,
        surface: SurfaceView?,
        surfaceW: Int,
        surfaceH: Int,
        rect: Rect,
        left: Int,
        top: Int,
        bmpW: Int,
        bmpH: Int,
    ) {
        val bmp = acquireBuffer(bmpW, bmpH)
        copyInFlight = true
        lastCaptureStartedAt = SystemClock.uptimeMillis()
        captureScrollBaselinePx = scrollOffsetState?.value ?: 0f
        val finish = PixelCopy.OnPixelCopyFinishedListener { result ->
            copyInFlight = false
            if (!backdropLoopRunning || backdropState == null) {
                return@OnPixelCopyFinishedListener
            }
            if (result == PixelCopy.SUCCESS) {
                if (!loggedPixelSample) {
                    loggedPixelSample = true
                    val px = bmp.getPixel(bmp.width / 2, bmp.height / 2)
                    Log.d(
                        TAG,
                        "backdrop ok ${bmp.width}x${bmp.height} src=($left,$top) center=0x" +
                            Integer.toHexString(px),
                    )
                }
                settleScrollCompensation()
                state.value = BackdropFrame(
                    image = bmp.asImageBitmap(),
                    srcLeftPx = left,
                    srcTopPx = top,
                )
            } else if (!loggedCopyFailure) {
                loggedCopyFailure = true
                Log.w(
                    TAG,
                    "PixelCopy 失败 result=$result surface=${surface != null} rect=$rect",
                )
            }
            scheduleNextCapture()
        }
        if (surface != null && left >= 0 && surfaceW >= rect.right && surfaceH >= rect.bottom) {
            runCatching { PixelCopy.request(surface, rect, bmp, finish, handler) }
                .onFailure {
                    copyInFlight = false
                    Log.w(TAG, "PixelCopy(surface) 抛异常", it)
                    scheduleNextCapture()
                }
            return
        }
                                                         
                                     
        val activity = activityRef
        val window = activity?.window
        if (activity == null || window == null) {
            copyInFlight = false
            scheduleNextCapture()
            return
        }
        val location = IntArray(2)
        window.decorView.getLocationOnScreen(location)
        runCatching {
            PixelCopy.request(
                window,
                Rect(
                    rect.left,
                    rect.top + location[1],
                    rect.right,
                    rect.bottom + location[1],
                ),
                bmp,
                finish,
                handler,
            )
        }.onFailure {
            copyInFlight = false
            Log.w(TAG, "PixelCopy(window) 抛异常", it)
            scheduleNextCapture()
        }
    }

    private fun parseTabs(raw: Any?): List<LiquidBarTab> {
        val list = raw as? List<*> ?: return emptyList()
        return list.mapNotNull { any ->
            val m = any as? Map<*, *> ?: return@mapNotNull null
            LiquidBarTab(
                id = m["id"] as? String ?: return@mapNotNull null,
                label = m["label"] as? String ?: "",
                iconCodePoint = (m["iconCodePoint"] as? Number)?.toInt(),
                iconFontFamily = m["iconFontFamily"] as? String,
                selectedIconCodePoint = (m["selectedIconCodePoint"] as? Number)?.toInt(),
            )
        }
    }

    private fun findSurfaceView(root: View): SurfaceView? {
        if (root is SurfaceView) return root
        if (root is ViewGroup) {
            for (i in 0 until root.childCount) {
                val found = findSurfaceView(root.getChildAt(i))
                if (found != null) return found
            }
        }
        return null
    }

    @Composable
    private fun barColorScheme(dark: Boolean): ColorScheme {
        val context = LocalContext.current
        return remember(dark, context) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (dark) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
            } else {
                if (dark) darkColorScheme() else lightColorScheme()
            }
        }
    }

       
                                          
      
             
                                                              
                                                    
                                                  
                                                            
                                            
       
    @Composable
    private fun rememberScreenBackdrop(
        source: State<BackdropFrame?>,
        nodeLeft: () -> Int,
        nodeTop: () -> Int,
        scrollCompensation: () -> Float,
    ): Backdrop {
        val onDrawBackdrop: DrawScope.() -> Unit = remember {
            {
                val frame = source.value
                if (frame != null && size.width > 0f && size.height > 0f) {
                                                       
                                                     
                                                       
                      
                                               
                                                                
                                                 
                                                              
                    val dy = scrollCompensation()
                        .fastCoerceIn(-maxCompensationPx, maxCompensationPx)
                        .roundToInt()
                    drawImage(
                        image = frame.image,
                        dstOffset = IntOffset(
                            frame.srcLeftPx - nodeLeft(),
                            frame.srcTopPx - nodeTop() - dy,
                        ),
                        dstSize = IntSize(frame.image.width, frame.image.height),
                    )
                }
            }
        }
        return rememberCanvasBackdrop(onDrawBackdrop)
    }

       
                                                                     
                                                       
      
                                                               
                                 
                                                             
                                   
                                                  
      
                                                           
                                                     
                  
       
    @Composable
    private fun LiquidGlassBar(
        tabs: List<LiquidBarTab>,
        index: Int,
        backdropSource: State<BackdropFrame?>,
        scrollCompensation: State<Float>,
        nodeLeftPx: Int,
        nodeTopPx: Int,
        barHeightDp: Float,
        bottomInsetDp: Float,
        bottomGapDp: Float,
        accent: Color?,
        onSelect: (Int) -> Unit,
    ) {
        val cs = MaterialTheme.colorScheme
        val tint = accent ?: cs.primary
        val isLight = cs.surface != Color.Black
        val tabCount = tabs.size.coerceAtLeast(1)
        val density = LocalDensity.current
        val isLtr = LocalLayoutDirection.current == LayoutDirection.Ltr
                                          
                           
        val touchSlop = LocalViewConfiguration.current.touchSlop
        val animationScope = rememberCoroutineScope()
                                           
        val tabsBackdrop = rememberLayerBackdrop()
        val indicatorHeightDp = barHeightDp - 8f

                                            
        var currentIndex by remember { mutableIntStateOf(index) }

        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(bottom = (bottomGapDp + bottomInsetDp).dp),
            contentAlignment = Alignment.BottomCenter,
        ) {
                                    
            BoxWithConstraints(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(barHeightDp.dp),
            ) {
                val barWidthDp = minOf(
                    tabCount * TAB_WIDTH_DP,
                    constraints.maxWidth.toFloat() / density.density,
                )
                               
                BoxWithConstraints(
                    modifier = Modifier
                        .width(barWidthDp.dp)
                        .height(barHeightDp.dp)
                        .align(Alignment.BottomCenter),
                    contentAlignment = Alignment.CenterStart,
                ) {
                                                               
                                                                
                    val sidePaddingPx = with(density) { INNER_PAD_DP.dp.toPx() }
                    val tabWidthPx = (constraints.maxWidth.toFloat() - 2f * sidePaddingPx) /
                        tabCount
                    val innerPadPx = sidePaddingPx.roundToInt()

                                                               
                    val backdrop = rememberScreenBackdrop(
                        backdropSource,
                        nodeLeft = { nodeLeftPx },
                        nodeTop = { nodeTopPx },
                        scrollCompensation = { scrollCompensation.value },
                    )
                    val innerBackdrop = rememberScreenBackdrop(
                        backdropSource,
                        nodeLeft = { nodeLeftPx + innerPadPx },
                        nodeTop = { nodeTopPx + innerPadPx },
                        scrollCompensation = { scrollCompensation.value },
                    )

                                                   
                val offsetAnimation = remember { Animatable(0f) }
                val panelOffset = remember(density) {
                    derivedStateOf {
                        val fraction =
                            (offsetAnimation.value / constraints.maxWidth.toFloat())
                                .fastCoerceIn(-1f, 1f)
                        with(density) {
                            4f.dp.toPx() * fraction.sign * EaseOut.transform(abs(fraction))
                        }
                    }
                }

                                                               
                                                
                val realIndex by rememberUpdatedState(index)
                val dampedDragAnimation = remember(animationScope) {
                    DampedDragAnimation(
                        animationScope = animationScope,
                        initialValue = index.toFloat(),
                        valueRange = 0f..(tabCount - 1).toFloat(),
                        visibilityThreshold = 0.001f,
                        initialScale = 1f,
                        pressedScale = 78f / 56f,
                        touchSlop = touchSlop,
                                                     
                                                           
                                                               
                                                        
                        onDragStarted = { position, gestureSize ->
                            val px = if (isLtr) {
                                position.x
                            } else {
                                gestureSize.width - position.x
                            }
                                                           
                                                                      
                                                                     
                            val target = ((px - sidePaddingPx) / tabWidthPx)
                                .toInt()
                                .fastCoerceIn(0, tabCount - 1)
                                                                    
                            pressTargetIndex = target
                            if (target.toFloat() != targetValue) {
                                updateValue(target.toFloat())
                            }
                        },
                        onDragStopped = {
                            val targetIndex =
                                targetValue.fastRoundToInt().fastCoerceIn(0, tabCount - 1)
                            currentIndex = targetIndex
                            animateToValue(targetIndex.toFloat())
                            animationScope.launch {
                                offsetAnimation.animateTo(0f, spring(1f, 300f, 0.5f))
                            }
                                                       
                                      
                            if (targetIndex != realIndex) onSelect(targetIndex)
                        },
                                                       
                                                      
                        onTap = { targetIndex ->
                            currentIndex = targetIndex
                            animateToValue(targetIndex.toFloat())
                            animationScope.launch {
                                offsetAnimation.animateTo(0f, spring(1f, 300f, 0.5f))
                            }
                            onSelect(targetIndex)
                        },
                                                  
                        onLongPress = {
                            currentIndex = realIndex
                            animateToValue(realIndex.toFloat())
                            animationScope.launch {
                                offsetAnimation.animateTo(0f, spring(1f, 300f, 0.5f))
                            }
                        },
                        onDrag = { _, dragAmount ->
                            updateValue(
                                (
                                    targetValue +
                                        dragAmount.x / tabWidthPx * (if (isLtr) 1f else -1f)
                                    ).fastCoerceIn(0f, (tabCount - 1).toFloat()),
                            )
                            animationScope.launch {
                                offsetAnimation.snapTo(offsetAnimation.value + dragAmount.x)
                            }
                        },
                    )
                }

                                                    
                LaunchedEffect(index) {
                    if (index != currentIndex) {
                        currentIndex = index
                        dampedDragAnimation.animateToValue(index.toFloat())
                    }
                }

                                                         
                                                       
                                                                       
                val tabScale: () -> Float = {
                    lerp(1f, 1.2f, dampedDragAnimation.pressProgress)
                }

                val interactiveHighlight = remember(animationScope) {
                    InteractiveHighlight(
                        animationScope = animationScope,
                        position = { size, _ ->
                            Offset(
                                if (isLtr) {
                                    sidePaddingPx +
                                        (dampedDragAnimation.value + 0.5f) * tabWidthPx +
                                        panelOffset.value
                                } else {
                                    size.width - sidePaddingPx -
                                        (dampedDragAnimation.value + 0.5f) * tabWidthPx +
                                        panelOffset.value
                                },
                                size.height / 2f,
                            )
                        },
                    )
                }

                                              
                Row(
                    Modifier
                        .graphicsLayer { translationX = panelOffset.value }
                        .drawBackdrop(
                            backdrop = backdrop,
                            shape = { Capsule() },
                            effects = {
                                vibrancy()
                                blur(with(density) { 8.dp.toPx() })
                                lens(
                                    with(density) { 24.dp.toPx() },
                                    with(density) { 24.dp.toPx() },
                                )
                            },
                            layerBlock = {
                                val progress = dampedDragAnimation.pressProgress
                                val scale = lerp(1f, 1f + 16.dp.toPx() / size.width, progress)
                                scaleX = scale
                                scaleY = scale
                            },
                                                        
                                             
                        )
                        .then(interactiveHighlight.modifier)
                        .height(barHeightDp.dp)
                        .fillMaxWidth()
                        .padding(horizontal = INNER_PAD_DP.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {}

                                                                   
                                                      
                                                                  
                                                                
                                 
                Row(
                    Modifier
                        .graphicsLayer { translationX = panelOffset.value }
                        .alpha(0f)
                        .layerBackdrop(tabsBackdrop)
                        .drawBackdrop(
                            backdrop = innerBackdrop,
                            shape = { Capsule() },
                            effects = {
                                vibrancy()
                                blur(with(density) { 8.dp.toPx() })
                                lens(
                                    with(density) {
                                        24.dp.toPx() * dampedDragAnimation.pressProgress
                                    },
                                    with(density) {
                                        24.dp.toPx() * dampedDragAnimation.pressProgress
                                    },
                                )
                            },
                            highlight = {
                                Highlight.Default.copy(
                                    alpha = dampedDragAnimation.pressProgress,
                                )
                            },
                                          
                        )
                        .height(indicatorHeightDp.dp)
                        .fillMaxWidth()
                        .padding(horizontal = INNER_PAD_DP.dp)
                        .graphicsLayer(colorFilter = ColorFilter.tint(tint)),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    tabs.forEachIndexed { i, tab ->
                        BarTab(
                            tab = tab,
                            selected = i == currentIndex,
                            tint = tint,
                            scale = tabScale,
                            modifier = Modifier.weight(1f),
                        )
                    }
                }

                                                 
                                                        
                                                         
                                                           
                            
                Row(
                    Modifier
                        .graphicsLayer { translationX = panelOffset.value }
                        .height(indicatorHeightDp.dp)
                        .fillMaxWidth()
                        .padding(horizontal = INNER_PAD_DP.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    tabs.forEachIndexed { i, tab ->
                        BarTab(
                            tab = tab,
                            selected = i == currentIndex,
                            tint = tint,
                            scale = tabScale,
                            modifier = Modifier.weight(1f),
                        )
                    }
                }

                                                 
                                                  
                                                          
                val indicatorBackdrop = rememberScreenBackdrop(
                    backdropSource,
                    nodeLeft = {
                        nodeLeftPx + innerPadPx +
                            (dampedDragAnimation.value * tabWidthPx).roundToInt() +
                            panelOffset.value.roundToInt()
                    },
                    nodeTop = { nodeTopPx + innerPadPx },
                    scrollCompensation = { scrollCompensation.value },
                )
                Box(
                    Modifier
                        .padding(horizontal = INNER_PAD_DP.dp)
                        .graphicsLayer {
                            translationX =
                                dampedDragAnimation.value * tabWidthPx + panelOffset.value
                        }
                        .drawBackdrop(
                                                                 
                            backdrop = rememberCombinedBackdrop(
                                indicatorBackdrop,
                                tabsBackdrop,
                            ),
                            shape = { Capsule() },
                            effects = {
                                val progress = dampedDragAnimation.pressProgress
                                lens(
                                    with(density) { 10.dp.toPx() } * progress,
                                    with(density) { 14.dp.toPx() } * progress,
                                    chromaticAberration = true,
                                )
                            },
                            highlight = {
                                Highlight.Default.copy(
                                    alpha = dampedDragAnimation.pressProgress,
                                )
                            },
                            shadow = { Shadow(alpha = dampedDragAnimation.pressProgress) },
                            innerShadow = {
                                val progress = dampedDragAnimation.pressProgress
                                InnerShadow(radius = 8.dp * progress, alpha = progress)
                            },
                            layerBlock = {
                                                         
                                                     
                                scaleX = dampedDragAnimation.scaleX
                                scaleY = dampedDragAnimation.scaleY
                                val velocity = dampedDragAnimation.velocity / 10f
                                scaleX /= 1f - (velocity * 0.75f).fastCoerceIn(-0.2f, 0.2f)
                                scaleY *= 1f - (velocity * 0.25f).fastCoerceIn(-0.2f, 0.2f)
                            },
                                                                      
                                                         
                                              
                            onDrawSurface = {
                                val progress = dampedDragAnimation.pressProgress
                                drawRect(
                                    if (isLight) {
                                        Color.Black.copy(alpha = 0.1f)
                                    } else {
                                        Color.White.copy(alpha = 0.1f)
                                    },
                                    alpha = 1f - progress,
                                )
                                drawRect(Color.Black.copy(alpha = 0.03f * progress))
                            },
                        )
                        .height(indicatorHeightDp.dp)
                        .fillMaxWidth(1f / tabCount),
                )

                                                     
                                                
                                                             
                                                 
                                                       
                                                     
                Box(
                    Modifier
                        .fillMaxSize()
                        .then(interactiveHighlight.gestureModifier)
                        .then(dampedDragAnimation.modifier),
                )
                }
            }
        }
    }

    @Composable
    private fun BarTab(
        tab: LiquidBarTab,
        selected: Boolean,
        tint: Color,
        scale: () -> Float,
        modifier: Modifier = Modifier,
    ) {
        val cs = MaterialTheme.colorScheme
        val context = LocalContext.current
        val codePoint = if (selected) {
            tab.selectedIconCodePoint ?: tab.iconCodePoint
        } else {
            tab.iconCodePoint
        }
        val typeface = remember(tab.iconFontFamily) {
            codePoint?.let { IconFonts.load(context, tab.iconFontFamily) }
        }
        val fg = if (selected) tint else cs.onSurfaceVariant
        Column(
                                                     
                                                         
                               
            modifier = modifier
                .clip(Capsule())
                .fillMaxHeight()
                .graphicsLayer {
                    val s = scale()
                    scaleX = s
                    scaleY = s
                },
            verticalArrangement = Arrangement.spacedBy(2.dp, Alignment.CenterVertically),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Box(Modifier.size(24.dp), contentAlignment = Alignment.Center) {
                if (codePoint != null && typeface != null) {
                    Text(
                        text = String(Character.toChars(codePoint)),
                        fontFamily = FontFamily(typeface),
                        fontSize = 22.sp,
                        color = fg,
                    )
                } else {
                    Icon(
                        imageVector = Icons.Filled.Circle,
                        contentDescription = null,
                        tint = fg,
                        modifier = Modifier.size(20.dp),
                    )
                }
            }
            Spacer(Modifier.size(2.dp))
            Text(
                text = tab.label,
                fontSize = 10.sp,
                color = fg,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                textAlign = TextAlign.Center,
            )
        }
    }
}
