package com.memz2345.navi.flash

import android.app.Activity
import android.graphics.Typeface
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import androidx.activity.compose.LocalOnBackPressedDispatcherOwner
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.material3.ColorScheme
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

   
                                    
  
                                                          
                                       
   
data class NativeMenuItem(
    val text: String,
    val iconCodePoint: Int?,
    val iconFontFamily: String?,
    val checked: Boolean,
    val destructive: Boolean,
    val enabled: Boolean,
    val subtitle: String? = null,
    val closeAfter: Boolean = true,
)

   
                                                    
  
                        
                                                       
                                                
                                           
                                 
                                           
  
                                    
                                                      
                                                                      
                                             
                                                 
                        
                                                                  
  
                                                    
                                            
   
object NativeMenuHost {

    private const val TAG = "NativeMenuHost"
    const val CHANNEL_NAME = "com.memz2345.navi.flash/native_menu"
    private const val ITEM_HEIGHT_DP = 48f
    private const val EDGE_DP = 8f

                                              
    private const val DROPDOWN_BLUR_PX = 32f
    private const val SHEET_BLUR_PX = 56f

                                   
    private const val MENU_DIM_AMOUNT = 0.32f

                           
    private const val ENTER_EXIT_MS = 320

    private val handler = Handler(Looper.getMainLooper())
    private var channel: MethodChannel? = null
    private var hostRoot: ViewGroup? = null
    private var hostView: View? = null
    private var hostOwner: ComposeHostOwner? = null
    private var dismissPosted = false

                                               
    private var activeMenuId: Int? = null
    private var itemsState: MutableState<List<NativeMenuItem>>? = null

                                    
    private var menuWindowState: MenuWindowState? = null

       
                                   
                                                
       
    private fun closeWithAnimation(onClosed: () -> Unit) {
        val st = menuWindowState
        if (st == null) {
            dismiss()
            onClosed()
            return
        }
        if (st.closing) return
        st.closing = true
        st.backProgress.floatValue = 0f
        st.exiting.value = true
        handler.postDelayed({
            dismiss()
            onClosed()
        }, ENTER_EXIT_MS.toLong())
    }

                                                
    private fun postFromCompose(block: () -> Unit) {
        if (dismissPosted) return
        dismissPosted = true
        handler.post {
            dismissPosted = false
            block()
        }
    }

                                                    
    fun install(activity: Activity, messenger: BinaryMessenger) {
        val ch = MethodChannel(messenger, CHANNEL_NAME)
        channel = ch
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "showMenu" -> {
                    val ok = show(activity, call.arguments as? Map<*, *>)
                    result.success(ok)
                }
                "hideMenu" -> {
                    dismiss()
                    result.success(null)
                }
                "updateItems" -> {
                                                             
                                                
                    val menuId = (call.arguments as? Map<*, *>?)?.get("menuId") as? Number
                    val items = parseItems(
                        (call.arguments as? Map<*, *>?)?.get("items"),
                    )
                    if (menuId?.toInt() == activeMenuId && items.isNotEmpty()) {
                        itemsState?.value = items
                    }
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
        val root = hostRoot
        val view = hostView
        val owner = hostOwner
        hostRoot = null
        hostView = null
        hostOwner = null
        activeMenuId = null
        itemsState = null
        menuWindowState = null
        if (root != null && view != null && view.parent === root) {
            root.removeView(view)
        }
        owner?.destroy()
    }

    private fun show(activity: Activity, args: Map<*, *>?): Boolean {
        if (args == null) return false
        val items = parseItems(args["items"])
        if (items.isEmpty()) return false
        val menuId = (args["menuId"] as? Number)?.toInt() ?: 0
        val width = (args["width"] as? Number)?.toFloat() ?: 220f
        val dark = args["dark"] as? Boolean ?: false
        val style = args["style"] as? String ?: "dropdown"
        val title = args["title"] as? String ?: ""

        dismiss()

        val root = activity.findViewById<ViewGroup>(android.R.id.content) ?: return false
                                                 
        val density = activity.resources.displayMetrics.density
        val loc = IntArray(2)
        root.getLocationOnScreen(loc)
        val baseX = (args["x"] as? Number)?.toFloat() ?: 0f
        val baseY = (args["y"] as? Number)?.toFloat() ?: 0f
        val xDp = baseX + loc[0] / density
        val yDp = baseY + loc[1] / density

                                                     
        val state = mutableStateOf(items)
        val windowState = MenuWindowState()
        activeMenuId = menuId
        itemsState = state
        menuWindowState = windowState

        val ch = channel
        val view = ComposeView(activity)
        val owner = ComposeHostOwner()
        owner.start()
        owner.attachTo(view)
                                                             
                                                               
                        
                                                          
                                                         
        val backOwner = MenuBackDispatcherOwner(owner)
        val isSheet = style == "bottomSheet"
        view.setContent {
            MaterialTheme(colorScheme = menuColorScheme(dark)) {
                val onSelect: (Int) -> Unit = { index ->
                                                    
                                                              
                    postFromCompose {
                        dismiss()
                        ch?.invokeMethod(
                            "onSelect",
                            mapOf("menuId" to menuId, "index" to index),
                        )
                    }
                }
                                                 
                val requestDismiss: () -> Unit = {
                    postFromCompose {
                        closeWithAnimation {
                            ch?.invokeMethod("onDismiss", mapOf("menuId" to menuId))
                        }
                    }
                }
                MenuDialog(
                    state = windowState,
                    backOwner = backOwner,
                    alignment = if (isSheet) Alignment.BottomCenter else Alignment.TopStart,
                    maxBlurPx = if (isSheet) SHEET_BLUR_PX else DROPDOWN_BLUR_PX,
                                                   
                                                                   
                                                
                                                        
                    dismissOnBackPress = true,
                    onDismissRequest = requestDismiss,
                    onBackConfirmed = requestDismiss,
                ) { effect, back ->
                    if (isSheet) {
                        SheetCard(
                            itemsState = state,
                            title = title,
                            effect = effect,
                            back = back,
                            onSelect = onSelect,
                            onClose = requestDismiss,
                        )
                    } else {
                        DropdownCard(
                            items = state.value,
                            xDp = xDp,
                            yDp = yDp,
                            widthDp = width,
                            effect = effect,
                            back = back,
                            onSelect = onSelect,
                        )
                    }
                }
            }
        }
        root.addView(
            view,
            ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )
        hostRoot = root
        hostView = view
        hostOwner = owner
        return true
    }

    private fun parseItems(raw: Any?): List<NativeMenuItem> {
        val list = raw as? List<*> ?: return emptyList()
        return list.mapNotNull { any ->
            val m = any as? Map<*, *> ?: return@mapNotNull null
            NativeMenuItem(
                text = m["text"] as? String ?: return@mapNotNull null,
                iconCodePoint = (m["iconCodePoint"] as? Number)?.toInt(),
                iconFontFamily = m["iconFontFamily"] as? String,
                checked = m["checked"] as? Boolean ?: false,
                destructive = m["destructive"] as? Boolean ?: false,
                subtitle = m["subtitle"] as? String,
                closeAfter = m["closeAfter"] as? Boolean ?: true,
                enabled = m["enabled"] as? Boolean ?: true,
            )
        }
    }

    @Composable
    private fun menuColorScheme(dark: Boolean): ColorScheme {
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
    private fun MenuDialog(
        state: MenuWindowState,
        backOwner: MenuBackDispatcherOwner,
        alignment: Alignment,
        maxBlurPx: Float,
        dismissOnBackPress: Boolean,
        onDismissRequest: () -> Unit,
        onBackConfirmed: () -> Unit,
        content: @Composable (Float, Float) -> Unit,
    ) {
        Dialog(
            onDismissRequest = onDismissRequest,
            properties = DialogProperties(
                dismissOnBackPress = dismissOnBackPress,
                dismissOnClickOutside = true,
                                                      
                usePlatformDefaultWidth = false,
                decorFitsSystemWindows = false,
            ),
        ) {
            val contentView = LocalView.current
            val window = remember(contentView) { windowOfDialogContent(contentView) }
            val windowManager = remember(contentView) {
                contentView.context.getSystemService(WindowManager::class.java)
            }
            val blurController = remember(window, windowManager) {
                if (window != null && windowManager != null) {
                    WindowBlurController(window, windowManager)
                } else {
                    null
                }
            }

                                                       
            DisposableEffect(Unit) {
                state.visible.value = true
                onDispose { blurController?.clear() }
            }

                                                              
                                                           
            DisposableEffect(window) {
                val callback = if (window != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    runCatching {
                        backOwner.onBackPressedDispatcher.setOnBackInvokedDispatcher(
                            window.onBackInvokedDispatcher,
                        )
                    }
                    backOwner.registerMenuBackCallback(state) { onBackConfirmed() }
                } else {
                    null
                }
                onDispose { callback?.remove() }
            }

            val enterExit by animateFloatAsState(
                targetValue = if (state.visible.value && !state.exiting.value) 1f else 0f,
                animationSpec = tween(ENTER_EXIT_MS, easing = FastOutSlowInEasing),
                label = "menuWindowEffect",
            )
            val back = state.backProgress.floatValue
            val effect = (enterExit * (1f - back)).coerceIn(0f, 1f)

                                       
            SideEffect { blurController?.apply(effect, maxBlurPx, MENU_DIM_AMOUNT) }

            CompositionLocalProvider(LocalOnBackPressedDispatcherOwner provides backOwner) {
                                     
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .pointerInput(Unit) { detectTapGestures { onDismissRequest() } },
                    contentAlignment = alignment,
                ) {
                    content(effect, back)
                }
            }
        }
    }

                                             
    @Composable
    private fun DropdownCard(
        items: List<NativeMenuItem>,
        xDp: Float,
        yDp: Float,
        widthDp: Float,
        effect: Float,
        back: Float,
        onSelect: (Int) -> Unit,
    ) {
        val cfg = LocalConfiguration.current
        val contentHeight = items.size * ITEM_HEIGHT_DP + 16f
        val maxHeight = (cfg.screenHeightDp.toFloat() - EDGE_DP * 2)
            .coerceAtLeast(ITEM_HEIGHT_DP * 2)
            .coerceAtMost(contentHeight)
                                   
        val x = xDp.coerceIn(EDGE_DP, (cfg.screenWidthDp - widthDp - EDGE_DP).coerceAtLeast(EDGE_DP))
        val y = yDp.coerceIn(EDGE_DP, (cfg.screenHeightDp - maxHeight - EDGE_DP).coerceAtLeast(EDGE_DP))
                                                 
        val scale = (1f - 0.10f * back) * (0.92f + 0.08f * effect)

        Surface(
            modifier = Modifier
                .offset(x = x.dp, y = y.dp)
                .width(widthDp.dp)
                .heightIn(max = maxHeight.dp)
                .graphicsLayer(
                    scaleX = scale,
                    scaleY = scale,
                    alpha = effect.coerceIn(0f, 1f),
                    transformOrigin = TransformOrigin(0f, 0f),
                )
                                   
                .pointerInput(Unit) { detectTapGestures { } },
            shape = RoundedCornerShape(12.dp),
            color = MaterialTheme.colorScheme.surfaceContainerHigh,
            tonalElevation = 3.dp,
            shadowElevation = 8.dp,
        ) {
            Column(
                modifier = Modifier
                    .padding(vertical = 8.dp)
                    .verticalScroll(rememberScrollState()),
            ) {
                items.forEachIndexed { index, item ->
                    MenuRow(item = item, onClick = { onSelect(index) })
                }
            }
        }
    }

       
                                            
      
                                                                 
                                         
                         
       
    @Composable
    private fun SheetCard(
        itemsState: MutableState<List<NativeMenuItem>>,
        title: String,
        effect: Float,
        back: Float,
        onSelect: (Int) -> Unit,
        onClose: () -> Unit,
    ) {
        val cfg = LocalConfiguration.current
        val maxHeight = (cfg.screenHeightDp * 0.85f).dp
        val slidePx = with(LocalDensity.current) { 96.dp.toPx() }

        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(max = maxHeight)
                .graphicsLayer(
                    translationY = (1f - effect) * slidePx,
                    alpha = effect.coerceIn(0f, 1f),
                )
                                   
                .pointerInput(Unit) { detectTapGestures { } },
            shape = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp),
            color = MaterialTheme.colorScheme.surfaceContainerLow,
        ) {
            Column(Modifier.padding(bottom = 16.dp)) {
                      
                Box(
                    Modifier
                        .fillMaxWidth()
                        .padding(top = 10.dp, bottom = 4.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    Box(
                        Modifier
                            .width(32.dp)
                            .height(4.dp)
                            .clip(RoundedCornerShape(2.dp))
                            .background(
                                MaterialTheme.colorScheme.onSurfaceVariant
                                    .copy(alpha = 0.4f),
                            ),
                    )
                }
                if (title.isNotEmpty()) {
                    SheetHeader(title = title, onClose = onClose)
                }
                Column(Modifier.verticalScroll(rememberScrollState())) {
                    itemsState.value.forEachIndexed { index, item ->
                        SheetRow(item = item, onClick = { onSelect(index) })
                    }
                }
            }
        }
    }

    @Composable
    private fun SheetHeader(title: String, onClose: () -> Unit) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(start = 16.dp, end = 6.dp, top = 2.dp, bottom = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = title,
                modifier = Modifier.weight(1f),
                fontSize = 15.sp,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurface,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .clickable { onClose() },
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    imageVector = Icons.Filled.Close,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
    }

    @Composable
    private fun SheetRow(item: NativeMenuItem, onClick: () -> Unit) {
        val cs = MaterialTheme.colorScheme
        val fg = if (!item.enabled) cs.onSurface.copy(alpha = 0.38f) else cs.onSurface
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = 48.dp)
                .clickable(enabled = item.enabled) { onClick() }
                .padding(horizontal = 16.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            MenuIcon(item = item, tint = cs.onSurfaceVariant)
            Spacer(Modifier.size(14.dp))
            Column(Modifier.weight(1f)) {
                Text(
                    text = item.text,
                    fontSize = 14.sp,
                    color = fg,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                item.subtitle?.let {
                    Text(
                        text = it,
                        fontSize = 11.sp,
                        color = cs.onSurfaceVariant,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }
            if (item.checked) {
                Icon(
                    imageVector = Icons.Filled.Check,
                    contentDescription = null,
                    tint = cs.primary,
                    modifier = Modifier.size(18.dp),
                )
            }
        }
    }

    @Composable
    private fun MenuRow(item: NativeMenuItem, onClick: () -> Unit) {
        val cs = MaterialTheme.colorScheme
        val fg = when {
            !item.enabled -> cs.onSurface.copy(alpha = 0.38f)
            item.destructive -> cs.error
            else -> cs.onSurface
        }
        val bg = if (item.checked) cs.secondaryContainer else Color.Transparent
        val shape = RoundedCornerShape(8.dp)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(ITEM_HEIGHT_DP.dp)
                .padding(horizontal = 8.dp)
                .clip(shape)
                .background(bg)
                .clickable(enabled = item.enabled) { onClick() }
                .padding(horizontal = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            MenuIcon(item = item, tint = fg)
            Spacer(Modifier.size(12.dp))
            Text(
                text = item.text,
                modifier = Modifier.weight(1f),
                style = MaterialTheme.typography.bodyLarge,
                color = fg,
                fontSize = 15.sp,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            if (item.checked) {
                Icon(
                    imageVector = Icons.Filled.Check,
                    contentDescription = null,
                    tint = cs.primary,
                    modifier = Modifier.size(20.dp),
                )
            }
        }
    }

    @Composable
    private fun MenuIcon(item: NativeMenuItem, tint: androidx.compose.ui.graphics.Color) {
        val codePoint = item.iconCodePoint
        val context = LocalContext.current
        val typeface = if (codePoint == null) {
            null
        } else {
            remember(item.iconFontFamily) { IconFonts.load(context, item.iconFontFamily) }
        }
        Box(Modifier.size(24.dp), contentAlignment = Alignment.Center) {
            if (codePoint != null && typeface != null) {
                Text(
                    text = String(Character.toChars(codePoint)),
                    fontFamily = FontFamily(typeface),
                    color = tint,
                    fontSize = 20.sp,
                )
            }
        }
    }
}

   
                                   
  
                                                
                                                   
                                                        
                               
   
internal object IconFonts {
    private val cache = HashMap<String, Typeface?>()

    fun load(context: android.content.Context, family: String?): Typeface? {
        val key = family ?: "MaterialIcons"
        synchronized(cache) {
            if (cache.containsKey(key)) return cache[key]
        }
        val tf = runCatching { resolve(context, key) }.getOrNull()
        synchronized(cache) { cache[key] = tf }
        return tf
    }

    private fun resolve(context: android.content.Context, family: String): Typeface? {
        val assets = context.assets
                                       
        if (family.startsWith("MaterialIcons")) {
            return Typeface.createFromAsset(assets, "flutter_assets/fonts/MaterialIcons-Regular.otf")
        }
                                                                 
        val wanted = family.lowercase().filter { it.isLetterOrDigit() }
        val dirs = listOf(
            "flutter_assets/fonts",
            "flutter_assets/assets/fonts",
            "flutter_assets",
        )
        for (dir in dirs) {
            val names = assets.list(dir) ?: continue
            for (name in names) {
                if (!name.endsWith(".ttf", true) && !name.endsWith(".otf", true)) continue
                val stem = name.substringBeforeLast('.').lowercase().filter { it.isLetterOrDigit() }
                if (stem == wanted || stem.startsWith(wanted)) {
                    return Typeface.createFromAsset(assets, "$dir/$name")
                }
            }
        }
        Log.w("NativeMenuHost", "icon font not found: $family")
        return null
    }
}
