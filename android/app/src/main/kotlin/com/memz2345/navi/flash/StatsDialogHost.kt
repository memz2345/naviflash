package com.memz2345.navi.flash

import android.app.Activity
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.ViewGroup
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import io.flutter.plugin.common.MethodChannel

   
                                                
  
                                                                   
                             
                                 
                                               
  
                                             
                                                            
                                                  
                                   
  
                                    
                                                                 
                                                        
                                                         
                                                                  
                                                                   
                                            
                                                         
                                            
  
                                                    
                                                   
   
object StatsDialogHost {
    private const val REFRESH_MS = 500L

    private val handler = Handler(Looper.getMainLooper())
    private var hostRoot: ViewGroup? = null
    private var hostView: View? = null
    private var hostOwner: ComposeHostOwner? = null
    private var poll: Runnable? = null

                            
    fun dismiss() {
        poll?.let { handler.removeCallbacks(it) }
        poll = null
        val root = hostRoot
        val view = hostView
        hostRoot = null
        hostView = null
        val owner = hostOwner
        hostOwner = null
        if (root != null && view != null && view.parent === root) {
            root.removeView(view)
        }
                                            
        owner?.destroy()
    }

    fun show(
        activity: Activity,
        channel: MethodChannel,
        title: String,
        entries: List<Pair<String, String>>,
        copyLabel: String,
        closeLabel: String,
    ) {
        dismiss()

        val root = activity.findViewById<ViewGroup>(android.R.id.content) ?: return
                                            
                        
        val entriesState: MutableState<List<Pair<String, String>>> =
            mutableStateOf(entries)

        val view = ComposeView(activity)
                                             
                                                     
                                                    
        val owner = ComposeHostOwner()
        owner.start()
        owner.attachTo(view)
        view.setContent {
            MaterialTheme(
                colorScheme = if (isSystemInDarkTheme()) {
                    darkColorScheme()
                } else {
                    lightColorScheme()
                },
            ) {
                StatsDialog(
                    title = title,
                    entries = entriesState.value,
                    copyLabel = copyLabel,
                    closeLabel = closeLabel,
                    onDismiss = { dismiss() },
                )
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

                                       
        val tick = object : Runnable {
            override fun run() {
                if (poll !== this) return         
                channel.invokeMethod(
                    "getStats",
                    null,
                    object : MethodChannel.Result {
                        override fun success(result: Any?) {
                            val parsed = parseStats(result)
                            if (parsed.isNotEmpty()) entriesState.value = parsed
                        }

                        override fun error(
                            errorCode: String,
                            errorMessage: String?,
                            errorDetails: Any?,
                        ) = Unit

                        override fun notImplemented() = Unit
                    },
                )
                handler.postDelayed(this, REFRESH_MS)
            }
        }
        poll = tick
        handler.postDelayed(tick, REFRESH_MS)
    }

    private fun parseStats(result: Any?): List<Pair<String, String>> {
        val rows = result as? List<*> ?: return emptyList()
        return rows.mapNotNull { row ->
            val pair = row as? List<*> ?: return@mapNotNull null
            val label = pair.getOrNull(0) as? String ?: return@mapNotNull null
            val value = pair.getOrNull(1) as? String ?: return@mapNotNull null
            label to value
        }
    }
}

@Composable
private fun StatsDialog(
    title: String,
    entries: List<Pair<String, String>>,
    copyLabel: String,
    closeLabel: String,
    onDismiss: () -> Unit,
) {
    val context = LocalContext.current
    Dialog(onDismissRequest = onDismiss) {
        Surface(
            shape = RoundedCornerShape(24.dp),
            color = MaterialTheme.colorScheme.surface,
            tonalElevation = 6.dp,
        ) {
            Column(Modifier.padding(20.dp)) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                )
                Spacer(Modifier.height(12.dp))
                Column(
                    Modifier
                        .heightIn(max = 360.dp)
                        .verticalScroll(rememberScrollState()),
                ) {
                    entries.forEach { (label, value) ->
                        Row(
                            Modifier
                                .fillMaxWidth()
                                .padding(vertical = 4.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(
                                text = label,
                                modifier = Modifier.weight(1f),
                                fontSize = 13.sp,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                            Spacer(Modifier.width(12.dp))
                            Text(
                                text = value,
                                fontSize = 13.sp,
                                color = MaterialTheme.colorScheme.onSurface,
                            )
                        }
                    }
                }
                Spacer(Modifier.height(14.dp))
                Row(
                    Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End,
                ) {
                    TextButton(onClick = { copyStats(context, entries) }) {
                        Icon(
                            Icons.Filled.ContentCopy,
                            contentDescription = null,
                            modifier = Modifier.size(18.dp),
                        )
                        Spacer(Modifier.width(6.dp))
                        Text(copyLabel)
                    }
                    Spacer(Modifier.width(8.dp))
                    Button(onClick = onDismiss) { Text(closeLabel) }
                }
            }
        }
    }
}

                                                           
private fun copyStats(context: Context, entries: List<Pair<String, String>>) {
    if (entries.isEmpty()) return
    val clipboard =
        context.getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
            ?: return
    val text = entries.joinToString("\n") { (label, value) -> "$label: $value" }
    clipboard.setPrimaryClip(ClipData.newPlainText("playback-stats", text))
}
