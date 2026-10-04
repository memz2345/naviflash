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
import androidx.compose.animation.core.spring
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.addPathNodes
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.text.font.FontWeight
import com.kyant.backdrop.Backdrop
import com.kyant.backdrop.backdrops.rememberCanvasBackdrop
import com.kyant.backdrop.drawBackdrop
import com.kyant.backdrop.effects.blur
import com.kyant.backdrop.effects.lens
import com.kyant.backdrop.effects.vibrancy
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlin.math.abs

   
                              
  
                                         
                                             
                            
  
      
                             
                          
                                      
                                                   
                                
   
object InteractionBarHost {
    private const val TAG = "InteractionBar"
    private const val CHANNEL_NAME = "com.memz2345.navi.flash/interaction_bar"

                                                 
    internal const val ISLAND_HEIGHT_DP = 44f
    private const val BOTTOM_GAP_DP = 8f
    internal const val ACTION_ITEM_WIDTH_DP = 54f
                                     
    internal const val ISLAND_GAP_DP = 12f

                                           
                                                      
    private const val BACKDROP_PAD_DP = 40f

                                            
    private const val ACTIVE_MIN_GAP_MS = 16L
    private const val IDLE_INTERVAL_MS = 500L
    private const val ACTIVE_WINDOW_MS = 700L

    private var channel: MethodChannel? = null
    private var hostRoot: ViewGroup? = null
    private var hostView: ComposeView? = null
    private var hostOwner: ComposeHostOwner? = null
    private var activityRef: Activity? = null
    private var surfaceView: SurfaceView? = null

    private var frameState: androidx.compose.runtime.MutableState<BackdropFrame?>? = null
    private var uiState: androidx.compose.runtime.MutableState<BarUi?>? = null

                 
    private var loopRunning = false
    private var copyInFlight = false
    private var lastCaptureStartedAt = 0L
    private var lastRefreshRequestAt = 0L
    private val choreographer = Choreographer.getInstance()
    private val handler = Handler(Looper.getMainLooper())

    private val activeFrameCallback = object : Choreographer.FrameCallback {
        override fun doFrame(frameTimeNanos: Long) = tickActive()
    }
    private val idleTick = Runnable { captureBackdrop() }

                      
    private var stripLeft = 0
    private var stripTop = 0
    private var stripRight = 0
    private var stripBottom = 0
    private var leftIslandLeft = 0
    private var rightIslandLeft = 0
    private var backdropPadPx = 0

                                                 
    private var bottomPadDp = BOTTOM_GAP_DP

                                       
    private val cpuBitmaps = arrayOfNulls<Bitmap>(3)
    private var cpuCursor = 0
    private var cpuW = 0
    private var cpuH = 0
    private val hwBuffers = arrayOfNulls<HardwareBuffer>(3)
    private val hwBitmaps = arrayOfNulls<Bitmap>(3)
    private var hwCursor = 0
    private var hwW = 0
    private var hwH = 0

                                               
    private var hwSupported: Boolean? = null
    private var loggedFailure = false

    fun install(activity: Activity, messenger: BinaryMessenger) {
        val ch = MethodChannel(messenger, CHANNEL_NAME)
        channel = ch
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "show" -> {
                    val args = call.arguments
                    if (args is Map<*, *>) show(activity, args)
                    result.success(null)
                }
                "hide" -> {
                    dismiss()
                    result.success(null)
                }
                "refresh" -> {
                                                
                                                          
                    noteUserInteraction()
                    captureBackdrop()
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
        stopLoop()
        releaseBuffers()
        val root = hostRoot
        val view = hostView
        val owner = hostOwner
        hostRoot = null
        hostView = null
        hostOwner = null
        activityRef = null
        surfaceView = null
        frameState = null
        uiState = null
        if (root != null && view != null && view.parent === root) {
            root.removeView(view)
        }
        owner?.destroy()
    }

    private fun releaseBuffers() {
        cpuBitmaps.fill(null); cpuCursor = 0; cpuW = 0; cpuH = 0
        for (i in hwBitmaps.indices) {
            runCatching { hwBitmaps[i]?.recycle() }
            hwBitmaps[i] = null
            runCatching { hwBuffers[i]?.close() }
            hwBuffers[i] = null
        }
        hwCursor = 0; hwW = 0; hwH = 0
    }

                 

    private fun show(activity: Activity, args: Map<*, *>) {
        val ui = BarUi.fromArgs(args) ?: run {
            Log.w(TAG, "show 参数不足，忽略")
            return
        }
        val firstShow = hostView == null
        if (firstShow) {
            createOverlay(activity)
            lastRefreshRequestAt = SystemClock.uptimeMillis()
            lastCaptureStartedAt = 0L
            startLoop()
            handler.postDelayed({ if (loopRunning) scheduleNext() }, 80)
        }
        uiState!!.value = ui
    }

    private fun createOverlay(activity: Activity) {
        val root = activity.findViewById<ViewGroup>(android.R.id.content) ?: return
        val surface = findSurfaceView(root)
        val frame = mutableStateOf<BackdropFrame?>(null)
        val ui = mutableStateOf<BarUi?>(null)
        frameState = frame
        uiState = ui
        surfaceView = surface
        activityRef = activity

                                                           
        hostRoot = root
        layoutGeometry(activity)

        val density = activity.resources.displayMetrics.density
        val inset = androidx.core.view.WindowInsetsCompat.toWindowInsetsCompat(
            root.rootWindowInsets,
        ).getInsets(androidx.core.view.WindowInsetsCompat.Type.navigationBars()).bottom
        val heightPx = ((ISLAND_HEIGHT_DP + BOTTOM_GAP_DP) * density).toInt() + inset

        val owner = ComposeHostOwner()
        owner.start()
        hostOwner = owner

        val view = ComposeView(activity)
        owner.attachTo(view)
        view.setContent {
            InteractionBarContent(
                ui = ui,
                frame = frame,
                bottomPadDp = bottomPadDp,
                geometry = GeometryRefs(
                    stripLeft = { stripLeft },
                    stripTop = { stripTop },
                    leftIslandLeft = { leftIslandLeft },
                    rightIslandLeft = { rightIslandLeft },
                ),
                onWriteComment = { invokeDart("onWriteComment") },
                onCommentsTap = { invokeDart("onCommentsTap") },
                onLike = { invokeDart("onLike") },
                onFavorite = { invokeDart("onFavorite") },
                onForward = { invokeDart("onForward") },
            )
        }
        hostView = view
        hostRoot = root
        root.addView(
            view,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                heightPx,
                Gravity.BOTTOM,
            ),
        )
    }

    private fun layoutGeometry(activity: Activity) {
        val density = activity.resources.displayMetrics.density
        val w = activity.resources.displayMetrics.widthPixels
        val h = activity.resources.displayMetrics.heightPixels
        val root = hostRoot
        val inset = if (root != null) {
            androidx.core.view.WindowInsetsCompat.toWindowInsetsCompat(root.rootWindowInsets)
                .getInsets(androidx.core.view.WindowInsetsCompat.Type.navigationBars()).bottom
        } else {
            0
        }

        val side = (SIDE_MARGIN_DP * density).toInt()
        val islandH = (ISLAND_HEIGHT_DP * density).toInt()
        stripLeft = side
        stripRight = w - side
        stripBottom = h - inset - (BOTTOM_GAP_DP * density).toInt()
        stripTop = stripBottom - islandH
        backdropPadPx = (BACKDROP_PAD_DP * density).toInt()
        bottomPadDp = BOTTOM_GAP_DP + inset / density

                                                                  
                                            
        leftIslandLeft = stripLeft

        val rightIslandW = (ACTION_ITEM_WIDTH_DP * density).toInt() * 4
        rightIslandLeft = stripRight - rightIslandW
    }

                 

    private fun startLoop() {
        stopLoop()
        loopRunning = true
        copyInFlight = false
    }

    private fun stopLoop() {
        loopRunning = false
        choreographer.removeFrameCallback(activeFrameCallback)
        handler.removeCallbacks(idleTick)
    }

    private fun scheduleNext() {
        if (!loopRunning) return
        val active = SystemClock.uptimeMillis() - lastRefreshRequestAt < ACTIVE_WINDOW_MS
        if (active) {
            choreographer.postFrameCallback(activeFrameCallback)
        } else {
            handler.postDelayed(idleTick, IDLE_INTERVAL_MS)
        }
    }

    private fun tickActive() {
        if (!loopRunning) return
        val now = SystemClock.uptimeMillis()
                                                           
        val minGap = if (hwSupported == true) 16L else ACTIVE_MIN_GAP_MS
        if (copyInFlight || now - lastCaptureStartedAt < minGap) {
            choreographer.postFrameCallback(activeFrameCallback)
            return
        }
        captureBackdrop()
    }

    private fun invokeDart(method: String) {
                                
        noteUserInteraction()
        channel?.invokeMethod(method, null)
    }

                                     
    fun noteUserInteraction() {
        lastRefreshRequestAt = SystemClock.uptimeMillis()
    }

                                                                              

                                                         
    private fun backdropCaptureRect(): Rect {
        val surface = surfaceView
        val dm = activityRef?.resources?.displayMetrics
        val boundW = surface?.width?.takeIf { it > 0 } ?: dm?.widthPixels ?: 0
        val boundH = surface?.height?.takeIf { it > 0 } ?: dm?.heightPixels ?: 0
        return Rect(
            (stripLeft - backdropPadPx).coerceAtLeast(0),
            (stripTop - backdropPadPx).coerceAtLeast(0),
            (stripRight + backdropPadPx).coerceAtMost(boundW),
            (stripBottom + backdropPadPx).coerceAtMost(boundH),
        )
    }

    private fun captureBackdrop() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        if (copyInFlight) return
        val state = frameState ?: return
        val surface = surfaceView
        val surfaceW = surface?.width ?: 0
        val surfaceH = surface?.height ?: 0
        if (stripRight <= stripLeft || stripBottom <= stripTop) return

        val rect = backdropCaptureRect()
        val w = rect.width()
        val h = rect.height()

        val canHw = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P &&
            surface != null &&
            surfaceW >= rect.right &&
            surfaceH >= rect.bottom &&
            hwSupported != false

        if (canHw) {
            val pair = runCatching { acquireHw(w, h) }.getOrElse {
                captureViaCpu(state, surface, rect)
                return
            }
            val bmp = pair.first
            copyInFlight = true
            lastCaptureStartedAt = SystemClock.uptimeMillis()
            val listener = PixelCopy.OnPixelCopyFinishedListener { result ->
                copyInFlight = false
                if (!loopRunning || frameState == null) return@OnPixelCopyFinishedListener
                if (result == PixelCopy.SUCCESS) {
                    hwSupported = true
                    state.value = BackdropFrame(
                        image = bmp.asImageBitmap(),
                        srcLeftPx = rect.left,
                        srcTopPx = rect.top,
                    )
                } else if (hwSupported == null) {
                    Log.i(TAG, "PixelCopy 不支持 HARDWARE Bitmap（result=$result），用 CPU")
                    disableHw()
                    captureViaCpu(state, surface, rect)
                    return@OnPixelCopyFinishedListener
                } else if (!loggedFailure) {
                    loggedFailure = true
                    Log.w(TAG, "PixelCopy(HARDWARE) 失败 result=$result")
                }
                scheduleNext()
            }
            runCatching {
                PixelCopy.request(surface, rect, bmp, listener, handler)
            }.onFailure {
                copyInFlight = false
                if (hwSupported == null) {
                    Log.i(TAG, "PixelCopy 拒绝 HARDWARE Bitmap，用 CPU", it)
                    disableHw()
                    captureViaCpu(state, surface, rect)
                } else {
                    scheduleNext()
                }
            }
            return
        }
        captureViaCpu(state, surface, rect)
    }

    private fun disableHw() {
        hwSupported = false
        for (i in hwBitmaps.indices) {
            runCatching { hwBitmaps[i]?.recycle() }
            hwBitmaps[i] = null
            runCatching { hwBuffers[i]?.close() }
            hwBuffers[i] = null
        }
        hwCursor = 0; hwW = 0; hwH = 0
    }

    private fun acquireHw(w: Int, h: Int): Pair<Bitmap, HardwareBuffer> {
        if (hwW != w || hwH != h) {
            for (i in hwBitmaps.indices) {
                runCatching { hwBitmaps[i]?.recycle() }
                hwBitmaps[i] = null
                runCatching { hwBuffers[i]?.close() }
                hwBuffers[i] = null
            }
            hwW = w; hwH = h; hwCursor = 0
        }
        hwCursor = (hwCursor + 1) % hwBuffers.size
        val slot = hwCursor
        val cachedBmp = hwBitmaps[slot]
        val cachedBuf = hwBuffers[slot]
        if (cachedBmp != null && cachedBuf != null && !cachedBmp.isRecycled) {
            return cachedBmp to cachedBuf
        }
        val buf = HardwareBuffer.create(
            w, h, HardwareBuffer.RGBA_8888, 1,
            HardwareBuffer.USAGE_GPU_SAMPLED_IMAGE or HardwareBuffer.USAGE_GPU_COLOR_OUTPUT,
        )
        val bmp = Bitmap.wrapHardwareBuffer(buf, ColorSpace.get(ColorSpace.Named.SRGB))
            ?: run { buf.close(); error("wrapHardwareBuffer null") }
        hwBuffers[slot] = buf
        hwBitmaps[slot] = bmp
        return bmp to buf
    }

    private fun captureViaCpu(
        state: androidx.compose.runtime.MutableState<BackdropFrame?>,
        surface: SurfaceView?,
        rect: Rect,
    ) {
        val bmp = acquireCpu(rect.width(), rect.height())
        copyInFlight = true
        lastCaptureStartedAt = SystemClock.uptimeMillis()
        val finish = PixelCopy.OnPixelCopyFinishedListener { result ->
            copyInFlight = false
            if (!loopRunning || frameState == null) return@OnPixelCopyFinishedListener
            if (result == PixelCopy.SUCCESS) {
                state.value = BackdropFrame(
                    image = bmp.asImageBitmap(),
                    srcLeftPx = rect.left,
                    srcTopPx = rect.top,
                )
            } else if (!loggedFailure) {
                loggedFailure = true
                Log.w(TAG, "PixelCopy(CPU) 失败 result=$result rect=$rect")
            }
            scheduleNext()
        }
        if (surface != null && surface.width >= rect.right && surface.height >= rect.bottom) {
            runCatching { PixelCopy.request(surface, rect, bmp, finish, handler) }
                .onFailure {
                    copyInFlight = false
                    Log.w(TAG, "PixelCopy(surface) 异常", it); scheduleNext()
                }
            return
        }
        val activity = activityRef
        val window = activity?.window
        if (activity == null || window == null) {
            copyInFlight = false; scheduleNext(); return
        }
        val loc = IntArray(2)
        window.decorView.getLocationOnScreen(loc)
        runCatching {
            PixelCopy.request(
                window,
                Rect(rect.left, rect.top + loc[1], rect.right, rect.bottom + loc[1]),
                bmp, finish, handler,
            )
        }.onFailure {
            copyInFlight = false
            Log.w(TAG, "PixelCopy(window) 异常", it); scheduleNext()
        }
    }

    private fun acquireCpu(w: Int, h: Int): Bitmap {
        if (cpuW != w || cpuH != h) {
            cpuBitmaps.fill(null); cpuW = w; cpuH = h; cpuCursor = 0
        }
        cpuCursor = (cpuCursor + 1) % cpuBitmaps.size
        cpuBitmaps[cpuCursor]?.let { return it }
        return Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888).also {
            cpuBitmaps[cpuCursor] = it
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
}

                                            
       
                                            

                                         
private const val SIDE_MARGIN_DP = 12f

private data class BarUi(
    val writeLabel: String,
    val commentCount: Int,
    val likeCount: Int,
    val favoriteCount: Int,
    val forwardCount: Int,
    val liked: Boolean,
    val faved: Boolean,
    val colors: EditorColors,
) {
    companion object {
        fun fromArgs(args: Map<*, *>): BarUi? {
                                 
            val colorsMap = args["colors"] as? Map<*, *> ?: return null
            return BarUi(
                writeLabel = (args["writeLabel"] as? String) ?: "写评论",
                commentCount = (args["commentCount"] as? Number)?.toInt() ?: 0,
                likeCount = (args["likeCount"] as? Number)?.toInt() ?: 0,
                favoriteCount = (args["favoriteCount"] as? Number)?.toInt() ?: 0,
                forwardCount = (args["forwardCount"] as? Number)?.toInt() ?: 0,
                liked = args["liked"] as? Boolean ?: false,
                faved = args["favorite"] as? Boolean ?: false,
                colors = EditorColors.fromMap(colorsMap),
            )
        }
    }
}

                                            
             
                                            

@Composable
private fun InteractionBarContent(
    ui: androidx.compose.runtime.State<BarUi?>,
    frame: androidx.compose.runtime.State<BackdropFrame?>,
    bottomPadDp: Float,
    geometry: GeometryRefs,
    onWriteComment: () -> Unit,
    onCommentsTap: () -> Unit,
    onLike: () -> Unit,
    onFavorite: () -> Unit,
    onForward: () -> Unit,
) {
    val data = ui.value ?: return
    val scope = rememberCoroutineScope()
    val density = LocalDensity.current

                                         
    val baseTint = Color(data.colors.onSurface)

                                                    
                                     
    val leftStretch = remember { IslandStretchState() }
    val rightStretch = remember { IslandStretchState() }

    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.BottomCenter) {
        BoxWithConstraints(
            modifier = Modifier
                .fillMaxWidth()
                .padding(
                    start = SIDE_MARGIN_DP.dp,
                    end = SIDE_MARGIN_DP.dp,
                    bottom = bottomPadDp.dp,
                ),
        ) {
                                 
            val contentWpx = constraints.maxWidth.toFloat()
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.Bottom,
            ) {
                                         
                StretchIsland(
                    isLeftIsland = true,
                    state = leftStretch,
                    otherIslandWidthPx = { rightStretch.widthPx },
                    contentWidthPx = contentWpx,
                    backdrop = rememberStripBackdrop(
                        frame = frame,
                        islandLeftPx = geometry.leftIslandLeft(),
                        stripTopPx = geometry.stripTop(),
                    ),
                    outerModifier = Modifier
                        .pressGlow(scope)
                        .clickable(
                            interactionSource = remember { MutableInteractionSource() },
                            indication = null,
                            onClick = onWriteComment,
                        )
                        .padding(horizontal = 14.dp),
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            PencilIcon,
                            contentDescription = null,
                            tint = baseTint,
                            modifier = Modifier.size(22.dp),
                        )
                        Spacer(Modifier.width(8.dp))
                        Text(
                            data.writeLabel,
                            fontSize = 15.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = baseTint,
                        )
                    }
                }

                                               
                Spacer(Modifier.weight(1f))

                                             
                StretchIsland(
                    isLeftIsland = false,
                    state = rightStretch,
                    otherIslandWidthPx = { leftStretch.widthPx },
                    contentWidthPx = contentWpx,
                    backdrop = rememberStripBackdrop(
                        frame = frame,
                        islandLeftPx = geometry.rightIslandLeft(),
                        stripTopPx = geometry.stripTop(),
                    ),
                    outerModifier = Modifier.pressGlow(scope),
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        ActionItem(
                            icon = BubbleIcon,
                            count = data.commentCount,
                            active = false,
                            baseColor = baseTint,
                            activeColor = baseTint,
                            onTap = onCommentsTap,
                        )
                        ActionItem(
                            icon = if (data.liked) ThumbFilledIcon else ThumbOutlinedIcon,
                            count = data.likeCount,
                            active = data.liked,
                            baseColor = baseTint,
                            activeColor = Color(data.colors.primary),
                            onTap = onLike,
                        )
                        ActionItem(
                            icon = if (data.faved) StarFilledIcon else StarOutlinedIcon,
                            count = data.favoriteCount,
                            active = data.faved,
                            baseColor = baseTint,
                            activeColor = Color(data.colors.primary),
                            onTap = onFavorite,
                        )
                        ActionItem(
                            icon = RepeatIcon,
                            count = data.forwardCount,
                            active = false,
                            baseColor = baseTint,
                            activeColor = baseTint,
                            onTap = onForward,
                        )
                    }
                }
            }
        }
    }
}

   
         
  
                        
                                               
                                                            
                               
                                         
                              
   
@Composable
private fun StretchIsland(
    isLeftIsland: Boolean,
    state: IslandStretchState,
    otherIslandWidthPx: () -> Float,
    contentWidthPx: Float,
    backdrop: Backdrop,
    outerModifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    val density = LocalDensity.current
    val scope = rememberCoroutineScope()
    Box(
        modifier = Modifier
            .height(InteractionBarHost.ISLAND_HEIGHT_DP.dp)
            .onSizeChanged { state.widthPx = it.width.toFloat() }
            .islandStretchGesture(
                isLeftIsland = isLeftIsland,
                state = state,
                scope = scope,
                otherIslandWidthPx = otherIslandWidthPx,
                contentWidthPx = contentWidthPx,
                touchSlopPx = with(density) { 8.dp.toPx() },
                sideMarginPx = with(density) { SIDE_MARGIN_DP.dp.toPx() },
                gapReservePx = with(density) { InteractionBarHost.ISLAND_GAP_DP.dp.toPx() },
                edgeReservePx = with(density) { 4.dp.toPx() },
            )
            .then(outerModifier),
        contentAlignment = Alignment.Center,
    ) {
                                                
        Box(
            modifier = Modifier
                .matchParentSize()
                .graphicsLayer {
                    scaleX = state.scale
                    transformOrigin = TransformOrigin(state.anchorFraction, 0.5f)
                }
                .drawBackdrop(
                    backdrop = backdrop,
                    shape = {
                        RoundedCornerShape(
                            (InteractionBarHost.ISLAND_HEIGHT_DP / 2f).dp,
                        )
                    },
                    effects = {
                        vibrancy()
                        blur(with(density) { 8.dp.toPx() })
                        lens(
                            with(density) { 24.dp.toPx() },
                            with(density) { 24.dp.toPx() },
                        )
                    },
                ),
        )
                    
        content()
    }
}

@Composable
private fun ActionItem(
    icon: ImageVector,
    count: Int,
    active: Boolean,
    baseColor: Color,
    activeColor: Color,
    onTap: () -> Unit,
) {
    val interaction = remember { MutableInteractionSource() }
    val tint = if (active) activeColor else baseColor
    Column(
        modifier = Modifier
            .width(InteractionBarHost.ACTION_ITEM_WIDTH_DP.dp)
            .height(InteractionBarHost.ISLAND_HEIGHT_DP.dp)
            .clickable(
                interactionSource = interaction,
                indication = null,
                onClick = onTap,
            ),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(24.dp))
        Spacer(Modifier.height(2.dp))
        Text(
            formatCount(count),
            fontSize = 11.sp,
            color = tint,
            fontWeight = if (active) FontWeight.SemiBold else FontWeight.Normal,
        )
    }
}

private fun formatCount(n: Int): String {
    if (n >= 10000) {
        val w = n / 10000f
        return "%.1f万".format(w)
    }
    return "$n"
}

                                              
@Composable
private fun rememberStripBackdrop(
    frame: androidx.compose.runtime.State<BackdropFrame?>,
    islandLeftPx: Int,
    stripTopPx: Int,
): Backdrop {
    val onDrawBackdrop: DrawScope.() -> Unit = remember {
        {
            val f = frame.value
            if (f != null && size.width > 0f && size.height > 0f) {
                drawImage(
                    image = f.image,
                    dstOffset = IntOffset(f.srcLeftPx - islandLeftPx, f.srcTopPx - stripTopPx),
                    dstSize = IntSize(f.image.width, f.image.height),
                )
            }
        }
    }
    return rememberCanvasBackdrop(onDrawBackdrop)
}

                                         
private class GeometryRefs(
    val stripLeft: () -> Int,
    val stripTop: () -> Int,
    val leftIslandLeft: () -> Int,
    val rightIslandLeft: () -> Int,
)

                                            
                                          
                                            

private fun materialIcon(pathData: String): ImageVector =
    ImageVector.Builder(
        name = "icon_${pathData.hashCode()}",
        defaultWidth = 24.dp,
        defaultHeight = 24.dp,
        viewportWidth = 24f,
        viewportHeight = 24f,
    )
                                                             
                                                       
                                                      
                                            
        .addPath(addPathNodes(pathData), fill = SolidColor(Color.Black))
        .build()

private val PencilIcon = materialIcon(
    "M3,17.25V21h3.75L17.81,9.94l-3.75,-3.75L3,17.25zM20.71,7.04c0.39,-0.39 0.39,-1.02 0,-1.41l-2.34,-2.34c-0.39,-0.39 -1.02,-0.39 -1.41,0l-1.83,1.83 3.75,3.75 1.83,-1.83z",
)
private val BubbleIcon = materialIcon(
    "M20,2H4C2.9,2 2,2.9 2,4v18l4,-4h14c1.1,0 2,-0.9 2,-2V4c0,-1.1 -0.9,-2 -2,-2zm0,16H6l-2,2V4h16v14z",
)
private val ThumbOutlinedIcon = materialIcon(
    "M9,21h9c0.83,0 1.54,-0.5 1.84,-1.22L23,12v-2c0,-1.1 -0.9,-2 -2,-2h-6.31l0.95,-4.57 0.03,-0.32c0,-0.41 -0.17,-0.79 -0.44,-1.06L14.17,1 7.59,7.59C7.22,7.95 7,8.45 7,9v10c0,1.1 0.9,2 2,2zM1,21h4V9H1v12z",
)
private val ThumbFilledIcon = materialIcon(
    "M1,21h4V9H1v12zM23,10c0,-1.1 -0.9,-2 -2,-2h-6.31l0.95,-4.57 0.03,-0.32c0,-0.41 -0.17,-0.79 -0.44,-1.06L14.17,1 7.59,7.59C7.22,7.95 7,8.45 7,9v10c0,1.1 0.9,2 2,2h10c0.83,0 1.54,-0.5 1.84,-1.22L23,12v-2z",
)
private val StarOutlinedIcon = materialIcon(
    "M19.65,9.04l-4.84,-0.42 -1.89,-4.58c-0.34,-0.81 -1.5,-0.81 -1.84,0L9.19,8.62l-4.84,0.42c-0.88,0.07 -1.24,1.17 -0.57,1.77l3.67,3.18 -1.1,4.72c-0.2,0.86 0.73,1.54 1.48,1.08L12,16.77l4.26,3.05c0.75,0.47 1.68,-0.22 1.48,-1.08l-1.1,-4.72 3.67,-3.18c0.67,-0.6 0.32,-1.7 -0.57,-1.7zM12,15.4l-3.76,2.27 1,-4.28 -3.32,-2.88 4.38,-0.38L12,6.1l1.71,4.04 4.38,0.38 -3.32,2.88 1,4.28L12,15.4z",
)
private val StarFilledIcon = materialIcon(
    "M12,17.27L18.18,21l-1.64,-7.03L22,9.24l-7.19,-0.61L12,2 9.19,8.63 2,9.24l5.46,4.73L5.82,21 12,17.27z",
)
private val RepeatIcon = materialIcon(
    "M7,7h10v3l4,-4 -4,-4v3H5v6h2V7zM17,17H7v-3l-4,4 4,4v-3h12v-6h-2v4z",
)

                                            
                                                      
                                            

private class PressGlowState {
    var position by mutableStateOf(Offset.Zero)
    val progress = Animatable(0f)
}

@Composable
private fun Modifier.pressGlow(scope: CoroutineScope): Modifier {
    val state = remember { PressGlowState() }
    return this
        .pointerInput(Unit) {
            awaitEachGesture {
                val down = awaitFirstDown(requireUnconsumed = false)
                state.position = down.position
                scope.launch {
                    state.progress.animateTo(1f, spring(dampingRatio = 0.5f, stiffness = 300f))
                }
                while (true) {
                                                       
                    val event = awaitPointerEvent(PointerEventPass.Initial)
                    val pressed = event.changes.filter { it.pressed }
                    pressed.maxByOrNull { it.uptimeMillis }?.let {
                        state.position = it.position
                    }
                    if (pressed.isEmpty()) break
                }
                scope.launch {
                    state.progress.animateTo(0f, spring(dampingRatio = 0.5f, stiffness = 300f))
                }
            }
        }
        .drawWithContent {
            drawContent()
            val p = state.progress.value
            if (p > 0f) {
                drawRect(Color.White.copy(alpha = 0.05f * p), blendMode = BlendMode.Plus)
                drawRect(
                    Brush.radialGradient(
                        colors = listOf(
                            Color.White.copy(alpha = 0.22f * p),
                            Color.Transparent,
                        ),
                        center = state.position,
                        radius = size.minDimension * 1.6f,
                    ),
                    blendMode = BlendMode.Plus,
                )
            }
        }
}

                                            
                                                    
                
                                             
                                      
                                             
                  
                               
                        
                                            

                
private class IslandStretchState {
                            
    var widthPx by mutableFloatStateOf(0f)

                                               
    var scale by mutableFloatStateOf(1f)
        private set

                                             
    var anchorFraction by mutableFloatStateOf(0f)

    private val releaseAnim = Animatable(1f)
    private var releaseJob: Job? = null

                              
    fun dragTo(value: Float) {
        releaseJob?.cancel()
        scale = value
    }

                                                       
    fun springBack(scope: CoroutineScope) {
        releaseJob?.cancel()
        releaseJob = scope.launch {
            releaseAnim.snapTo(scale)
            releaseAnim.animateTo(1f, spring(dampingRatio = 0.55f, stiffness = 420f)) {
                scale = value
            }
        }
    }
}

@Composable
private fun Modifier.islandStretchGesture(
    isLeftIsland: Boolean,
    state: IslandStretchState,
    scope: CoroutineScope,
    otherIslandWidthPx: () -> Float,
    contentWidthPx: Float,
    touchSlopPx: Float,
    sideMarginPx: Float,
    gapReservePx: Float,
    edgeReservePx: Float,
): Modifier {
    val haptic = LocalHapticFeedback.current
    return pointerInput(contentWidthPx) {
        awaitEachGesture {
            val down = awaitFirstDown(requireUnconsumed = false)
            InteractionBarHost.noteUserInteraction()
            val startX = down.position.x
            var active = false
            var peaked = false
            while (true) {
                val event = awaitPointerEvent(PointerEventPass.Initial)
                InteractionBarHost.noteUserInteraction()
                val pointer = event.changes
                    .filter { it.pressed }
                    .maxByOrNull { it.uptimeMillis }
                if (pointer == null) break
                val dx = pointer.position.x - startX
                if (!active && abs(dx) >= touchSlopPx) active = true
                if (!active) continue

                val selfW = state.widthPx.takeIf { it > 0f } ?: size.width.toFloat()
                val otherW = otherIslandWidthPx()
                                                
                                                   
                val inward = if (isLeftIsland) dx > 0f else dx < 0f
                val inwardCap = (contentWidthPx - selfW - otherW - gapReservePx)
                    .coerceAtLeast(0f)
                val outwardCap = (sideMarginPx - edgeReservePx).coerceAtLeast(0f)
                val maxExtraPx = if (inward) inwardCap else outwardCap
                val extraPx = abs(dx).coerceAtMost(maxExtraPx)
                                   
                state.anchorFraction = if (dx > 0f) 0f else 1f
                if (extraPx >= maxExtraPx - 0.5f && maxExtraPx > 0f && !peaked) {
                    peaked = true
                    haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                } else if (extraPx < maxExtraPx - 0.5f) {
                    peaked = false
                }
                state.dragTo(1f + extraPx / selfW.coerceAtLeast(1f))
            }
                                 
            state.springBack(scope)
        }
    }
}
