package com.memz2345.navi.flash

import android.os.Build
import android.view.View
import android.view.Window
import android.view.WindowManager
import androidx.activity.BackEventCompat
import androidx.activity.OnBackPressedCallback
import androidx.activity.OnBackPressedDispatcher
import androidx.activity.OnBackPressedDispatcherOwner
import androidx.compose.runtime.MutableFloatState
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.lifecycle.LifecycleOwner
import kotlin.math.roundToInt

   
                              
  
                                                          
                                                      
                                                                
                                                  
                                                                  
                                           
                                                             
                                                   
                                                  
                                     
   
internal class WindowBlurController(
    private val window: Window,
    private val windowManager: WindowManager,
) {
                         
    val canBlurBehind: Boolean
        get() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            runCatching { windowManager.isCrossWindowBlurEnabled }.getOrDefault(false)

                                                  
    fun apply(fraction: Float, maxRadiusPx: Float, maxDim: Float) {
        val f = fraction.coerceIn(0f, 1f)
        val lp = window.attributes
        lp.dimAmount = (maxDim * f).coerceIn(0f, 1f)
        if (canBlurBehind) {
            window.addFlags(WindowManager.LayoutParams.FLAG_BLUR_BEHIND)
            window.addFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND)
            lp.blurBehindRadius = (maxRadiusPx * f).roundToInt()
        }
        window.attributes = lp
    }

    fun clear() {
        val lp = window.attributes
        lp.dimAmount = 0f
        if (canBlurBehind) {
            lp.blurBehindRadius = 0
            window.clearFlags(WindowManager.LayoutParams.FLAG_BLUR_BEHIND)
        }
        window.attributes = lp
    }
}

   
                                      
  
                                                  
   
internal class MenuWindowState {
                                        
    val visible: MutableState<Boolean> = mutableStateOf(false)

                            
    val exiting: MutableState<Boolean> = mutableStateOf(false)

                                    
    val backProgress: MutableFloatState = mutableFloatStateOf(0f)

                            
    var closing = false
}

   
             
  
                                                                    
                                                                
                                                      
                                                  
                                                       
   
internal class MenuBackDispatcherOwner(
    lifecycleOwner: LifecycleOwner,
) : OnBackPressedDispatcherOwner, LifecycleOwner by lifecycleOwner {
    override val onBackPressedDispatcher: OnBackPressedDispatcher = OnBackPressedDispatcher()
}

   
                                                 
  
                                                                         
                                                           
                                                         
   
internal fun MenuBackDispatcherOwner.registerMenuBackCallback(
    state: MenuWindowState,
    onConfirmed: () -> Unit,
): OnBackPressedCallback {
    val callback = object : OnBackPressedCallback(enabled = true) {
        override fun handleOnBackStarted(backEvent: BackEventCompat) {
            state.backProgress.floatValue = backEvent.progress
        }

        override fun handleOnBackProgressed(backEvent: BackEventCompat) {
            state.backProgress.floatValue = backEvent.progress
        }

        override fun handleOnBackCancelled() {
            state.backProgress.floatValue = 0f
        }

        override fun handleOnBackPressed() {
            state.backProgress.floatValue = 0f
            onConfirmed()
        }
    }
    onBackPressedDispatcher.addCallback(this, callback)
    return callback
}

                                                               
internal fun Window.setEdgeToEdgeCompat() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
        setDecorFitsSystemWindows(false)
    }
}

                                                           
internal fun windowOfDialogContent(contentView: View): Window? =
    (contentView.parent as? androidx.compose.ui.window.DialogWindowProvider)?.window
