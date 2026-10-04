package com.memz2345.navi.flash

import android.app.Activity
import android.graphics.Rect
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.PopupWindow
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.dp
import io.flutter.embedding.android.FlutterView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlin.math.roundToInt

   
                                                               
  
                                                      
                
  
                                                 
                                                  
                        
                                                                 
                                            
                                                     
                                               
                                 
  
                                                        
                                                            
  
                                                      
                        
   
object NativeTooltipHost {
    private const val TAG = "NativeTooltipHost"
    private const val CHANNEL_NAME = "com.memz2345.navi.flash/tooltip"

                                                    
    private const val FADE_MS = 90L

       
                                                     
                                     
      
                                                                  
                                                    
                            
       
    private fun windowRootOf(view: View): View {
        var root: View = view
        while (true) {
            root = (root.parent as? View) ?: return root
        }
    }

    private val handler = Handler(Looper.getMainLooper())

    private var channel: MethodChannel? = null
    private var popup: PopupWindow? = null
    private var hostRoot: ViewGroup? = null
    private var hostView: View? = null
    private var hostOwner: ComposeHostOwner? = null
    private var visibleState: MutableState<Boolean>? = null
    private var dismissTask: Runnable? = null

                                                    
    fun install(activity: Activity, messenger: BinaryMessenger) {
        val ch = MethodChannel(messenger, CHANNEL_NAME)
        channel = ch
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "show" -> result.success(show(activity, call.arguments as? Map<*, *>))
                "hide" -> {
                    hide()
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

                           
    fun hide() {
        val state = visibleState
        if (state == null) {
            dismiss()
            return
        }
        if (!state.value) return          
        state.value = false
        val task = Runnable { dismiss() }
        dismissTask = task
        handler.postDelayed(task, FADE_MS + 40L)
    }

                              
    private fun dismiss() {
        dismissTask?.let { handler.removeCallbacks(it) }
        dismissTask = null

        val p = popup
        val root = hostRoot
        val view = hostView
        val owner = hostOwner
        popup = null
        hostRoot = null
        hostView = null
        hostOwner = null
        visibleState = null

        try {
            if (p?.isShowing == true) p.dismiss()
        } catch (e: Exception) {
            Log.w(TAG, "dismiss popup failed: ${e.message}")
        }
        if (root != null && view != null && view.parent === root) {
            root.removeView(view)
        }
                                            
        owner?.destroy()
    }

    private fun show(activity: Activity, args: Map<*, *>?): Boolean {
        val text = args?.get("text") as? String ?: return false
        if (text.isEmpty()) return false
        val content = activity.findViewById<ViewGroup>(android.R.id.content) ?: return false
        val dark = args["dark"] as? Boolean ?: false

                                                              
                                    
                                                     
                                                  
        val flutterView = findFlutterView(content) ?: content
        val loc = IntArray(2)
        flutterView.getLocationOnScreen(loc)
        val density = activity.resources.displayMetrics.density
        val left = loc[0] + ((args["x"] as? Number)?.toDouble() ?: 0.0).times(density).roundToInt()
        val top = loc[1] + ((args["y"] as? Number)?.toDouble() ?: 0.0).times(density).roundToInt()
        val width = ((args["w"] as? Number)?.toDouble() ?: 0.0).times(density).roundToInt()
        val height = ((args["h"] as? Number)?.toDouble() ?: 0.0).times(density).roundToInt()
        val anchor = Rect(left, top, left + width, top + height)

        dismiss()

        val visible = mutableStateOf(false)                                         
        val view = ComposeView(activity)
        val owner = ComposeHostOwner()
        owner.start()
        owner.attachTo(view)
        view.setContent {
            MaterialTheme(colorScheme = tooltipColorScheme(dark)) {
                AnchorPlacedTooltip(anchor = anchor, visible = visible) {
                    AnimatedVisibility(
                        visible = visible.value,
                        enter = fadeIn(tween(FADE_MS.toInt())),
                        exit = fadeOut(tween(FADE_MS.toInt())),
                    ) {
                        TooltipBubble(text)
                    }
                }
            }
        }

        val pw = PopupWindow(
            view,
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT,
        ).apply {
                                                    
                                          
            isTouchable = false
            isFocusable = false
            isOutsideTouchable = false
            inputMethodMode = PopupWindow.INPUT_METHOD_NOT_NEEDED
            setBackgroundDrawable(null)                   
            elevation = 0f
        }
        try {
            pw.showAtLocation(content, Gravity.TOP or Gravity.START, 0, 0)
                                                               
                                                                         
                                                                              
                                                                                 
                                                                        
                                                                 
                                                                             
                                                          
                                                                          
                                                       
                                                                    
                               
            val windowRoot = windowRootOf(view)
            owner.attachTo(windowRoot)
            if (windowRoot === view) {
                                                    
                Log.w(TAG, "popup content is the window root; owner may be invisible")
            }
        } catch (e: Exception) {
            Log.w(TAG, "show popup failed: ${e.message}")
            owner.destroy()
            return false
        }

        popup = pw
        hostRoot = content
        hostView = view
        hostOwner = owner
        visibleState = visible
        return true
    }

                                                                  
    private fun findFlutterView(root: View): View? {
        if (root is FlutterView) return root
        if (root is ViewGroup) {
            for (i in 0 until root.childCount) {
                findFlutterView(root.getChildAt(i))?.let { return it }
            }
        }
        return null
    }

                                                       
    @Composable
    private fun tooltipColorScheme(dark: Boolean): ColorScheme {
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
    private fun TooltipBubble(text: String) {
        Surface(
            color = MaterialTheme.colorScheme.inverseSurface,
            contentColor = MaterialTheme.colorScheme.inverseOnSurface,
            shape = RoundedCornerShape(4.dp),
            tonalElevation = 0.dp,
            shadowElevation = 0.dp,
            modifier = Modifier.widthIn(max = 256.dp),
        ) {
            Text(
                text = text,
                style = MaterialTheme.typography.bodySmall,
                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
            )
        }
    }

       
                                                 
             
                               
                                
                                     
                                       
      
                                       
      
                                                         
                                                         
                                         
                                                              
                                                  
      
                                                     
                                                       
                                                                      
                                                      
                                             
                                           
      
                                                  
                                                                         
                                            
                                               
                        
       
    @Composable
    private fun AnchorPlacedTooltip(
        anchor: Rect,
        visible: MutableState<Boolean>,
        content: @Composable () -> Unit,
    ) {
        val localView = LocalView.current
        var origin by remember(localView) { mutableStateOf<Offset?>(null) }
        LaunchedEffect(localView) {
            withFrameNanos { }                                    
            val loc = IntArray(2)
            localView.getLocationOnScreen(loc)
            origin = Offset(loc[0].toFloat(), loc[1].toFloat())
            visible.value = true                      
        }

        val measured = origin
        Layout(content = content) { measurables, constraints ->
            val bubble = measurables.firstOrNull()?.measure(Constraints())
                                                   
                ?: return@Layout layout(0, 0) {}
            val gap = 4.dp.roundToPx()
            val margin = 8.dp.roundToPx()
            val maxW = constraints.maxWidth
            val maxH = constraints.maxHeight

                            
            val ox = measured?.x ?: 0f
            val oy = measured?.y ?: 0f
            val left = anchor.left - ox
            val top = anchor.top - oy
            val right = anchor.right - ox
            val bottom = anchor.bottom - oy
            val centerX = (left + right) / 2f

            var x = (centerX - bubble.width / 2f).roundToInt()
            x = x.coerceIn(margin, (maxW - bubble.width - margin).coerceAtLeast(margin))

            var y = (top - bubble.height - gap).roundToInt()
            if (y < margin) {
                                                 
                y = (bottom + gap).roundToInt()
            }
            if (y + bubble.height > maxH - margin) {
                y = (maxH - bubble.height - margin).coerceAtLeast(margin)
            }

            layout(maxW, maxH) { bubble.place(x, y) }
        }
    }
}
