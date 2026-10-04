package com.memz2345.navi.flash

import android.content.Context
import android.graphics.drawable.ColorDrawable
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material.icons.outlined.Restore
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LargeTopAppBar
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.material3.rememberTopAppBarState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.core.content.edit

   
                         
  
                                                  
                                                       
                 
  
                                                     
                                                      
                               
   
class ShortcutEditorActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        val colors = EditorColors.fromIntent(intent)

                                                   
                                       
                                        
                                             
        val transparent = android.graphics.Color.TRANSPARENT
        val barStyle = if (colors.isDark) {
            SystemBarStyle.dark(transparent)
        } else {
            SystemBarStyle.light(transparent, transparent)
        }
        enableEdgeToEdge(statusBarStyle = barStyle, navigationBarStyle = barStyle)

        super.onCreate(savedInstanceState)

                                                 
        window.setBackgroundDrawable(ColorDrawable(colors.surfaceContainer))

        setContent {
            ShortcutEditorTheme(colors = colors) {
                ShortcutEditorScreen(onFinish = { finish() })
            }
        }
    }
}

                      

data class EditorColors(
    val primary: Int,
    val onSurface: Int,
    val surface: Int,
    val surfaceContainer: Int,
    val surfaceContainerHigh: Int,
    val onSurfaceVariant: Int,
    val outline: Int,
    val isDark: Boolean,
) {
    companion object {
        fun fromIntent(intent: android.content.Intent): EditorColors {
            val b = intent.getBundleExtra("colors")
            fun argb(key: String, fallback: Int) = b?.getInt(key) ?: fallback
                                      
            val dark = (b?.getBoolean("dark", true) ?: true)
            return EditorColors(
                primary = argb("primary", if (dark) 0xFF90CAF9.toInt() else 0xFF1565C0.toInt()),
                onSurface = argb("onSurface", if (dark) 0xFFE6E6E6.toInt() else 0xFF1A1C1E.toInt()),
                surface = argb("surface", if (dark) 0xFF121316.toInt() else 0xFFFEF7FF.toInt()),
                surfaceContainer = argb(
                    "surfaceContainer",
                    if (dark) 0xFF15171A.toInt() else 0xFFF3EDF7.toInt(),
                ),
                surfaceContainerHigh = argb(
                    "surfaceContainerHigh",
                    if (dark) 0xFF1E2024.toInt() else 0xFFECE6F0.toInt(),
                ),
                onSurfaceVariant = argb(
                    "onSurfaceVariant",
                    if (dark) 0xFFC3C7CF.toInt() else 0xFF49454F.toInt(),
                ),
                outline = argb(
                    "outline",
                    if (dark) 0xFF8D9199.toInt() else 0xFF79747E.toInt(),
                ),
                isDark = dark,
            )
        }

                                                  
        fun fromMap(m: Map<*, *>): EditorColors {
            fun argb(key: String, fallback: Int) =
                (m[key] as? Number)?.toInt() ?: fallback
            val dark = m["dark"] as? Boolean ?: true
            return EditorColors(
                primary = argb("primary", if (dark) 0xFF90CAF9.toInt() else 0xFF1565C0.toInt()),
                onSurface = argb("onSurface", if (dark) 0xFFE6E6E6.toInt() else 0xFF1A1C1E.toInt()),
                surface = argb("surface", if (dark) 0xFF121316.toInt() else 0xFFFEF7FF.toInt()),
                surfaceContainer = argb(
                    "surfaceContainer",
                    if (dark) 0xFF15171A.toInt() else 0xFFF3EDF7.toInt(),
                ),
                surfaceContainerHigh = argb(
                    "surfaceContainerHigh",
                    if (dark) 0xFF1E2024.toInt() else 0xFFECE6F0.toInt(),
                ),
                onSurfaceVariant = argb(
                    "onSurfaceVariant",
                    if (dark) 0xFFC3C7CF.toInt() else 0xFF49454F.toInt(),
                ),
                outline = argb(
                    "outline",
                    if (dark) 0xFF8D9199.toInt() else 0xFF79747E.toInt(),
                ),
                isDark = dark,
            )
        }
    }
}

@Composable
private fun ShortcutEditorTheme(colors: EditorColors, content: @Composable () -> Unit) {
                                              
                                       
    val scheme = if (colors.isDark) {
        darkColorScheme(
            primary = Color(colors.primary),
            onSurface = Color(colors.onSurface),
            surface = Color(colors.surface),
            surfaceContainer = Color(colors.surfaceContainer),
            surfaceContainerHigh = Color(colors.surfaceContainerHigh),
            onSurfaceVariant = Color(colors.onSurfaceVariant),
            outline = Color(colors.outline),
        )
    } else {
        lightColorScheme(
            primary = Color(colors.primary),
            onSurface = Color(colors.onSurface),
            surface = Color(colors.surface),
            surfaceContainer = Color(colors.surfaceContainer),
            surfaceContainerHigh = Color(colors.surfaceContainerHigh),
            onSurfaceVariant = Color(colors.onSurfaceVariant),
            outline = Color(colors.outline),
        )
    }
    MaterialTheme(colorScheme = scheme, content = content)
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ShortcutEditorScreen(onFinish: () -> Unit) {
    val context = LocalContext.current
    val prefs = remember {
        context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
    }

    var ids by remember {
        mutableStateOf(
            prefs.getString(ShortcutCatalog.PREFS_KEY, null)
                ?.split(",")?.map { it.trim() }?.filter { it.isNotEmpty() }?.distinct()
                ?.filter { ShortcutCatalog.entryOf(it) != null }
                ?: ShortcutCatalog.DEFAULT_IDS,
        )
    }

    fun persist(next: List<String>) {
        ids = next
                                                       
        prefs.edit(commit = true) {
            putString(ShortcutCatalog.PREFS_KEY, next.joinToString(","))
        }
                                                 
                           
        DynamicShortcutPublisher.publish(context.applicationContext)
    }

                                        
                                            
    val scrollBehavior = TopAppBarDefaults.exitUntilCollapsedScrollBehavior(
        rememberTopAppBarState()
    )

    Scaffold(
        containerColor = MaterialTheme.colorScheme.surfaceContainer,
        modifier = Modifier
            .fillMaxSize()
            .nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            LargeTopAppBar(
                title = {
                    Text(
                        "长按快捷菜单",
                        fontWeight = FontWeight.SemiBold,
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onFinish) {
                        Icon(
                            Icons.AutoMirrored.Rounded.ArrowBack,
                            contentDescription = "返回",
                        )
                    }
                },
                actions = {
                    IconButton(onClick = { persist(ShortcutCatalog.DEFAULT_IDS) }) {
                        Icon(Icons.Outlined.Restore, contentDescription = "重置为默认")
                    }
                },
                colors = TopAppBarDefaults.largeTopAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surfaceContainer,
                    scrolledContainerColor = MaterialTheme.colorScheme.surfaceContainerHigh,
                ),
                scrollBehavior = scrollBehavior,
            )
        },
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
                                                                            
                                                 
                             
            contentPadding = PaddingValues(
                start = 20.dp,
                end = 20.dp,
                top = innerPadding.calculateTopPadding() + 8.dp,
                bottom = innerPadding.calculateBottomPadding() + 40.dp,
            ),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            item {
                InfoCard(
                    "最多 ${ShortcutCatalog.MAX_SHORTCUTS} 项 · 改动即时生效",
                )
            }

            item { SectionTitle("当前菜单（${ids.size}）") }

            if (ids.isEmpty()) {
                item { EmptyHint("还没有快捷方式，从下面添加") }
            } else {
                items(ids.size, key = { "cur_$it" }) { index ->
                    val id = ids[index]
                    val entry = ShortcutCatalog.entryOf(id) ?: return@items
                    ShortcutRow(
                        iconRes = entry.icon,
                        title = context.getString(entry.shortLabel),
                        actionLabel = "移除",
                        actionIcon = Icons.Outlined.DeleteOutline,
                        onAction = {
                            persist(ids.filterIndexed { i, _ -> i != index })
                        },
                    )
                }
            }

            item { Spacer(Modifier.height(12.dp)) }
            item { SectionTitle("可添加") }

            val available = ShortcutCatalog.entries.filter { it.id !in ids }
            if (available.isEmpty() || ids.size >= ShortcutCatalog.MAX_SHORTCUTS) {
                item {
                    EmptyHint(
                        if (ids.size >= ShortcutCatalog.MAX_SHORTCUTS) {
                            "已达上限，先移除一项"
                        } else {
                            "全部候选都已添加"
                        },
                    )
                }
            } else {
                items(available.size, key = { "add_${available[it].id}" }) { index ->
                    val entry = available[index]
                    ShortcutRow(
                        iconRes = entry.icon,
                        title = context.getString(entry.shortLabel),
                        actionLabel = "添加",
                        actionIcon = Icons.Outlined.Add,
                        onAction = {
                            persist(ids + entry.id)
                        },
                    )
                }
            }

            item { Spacer(Modifier.height(40.dp)) }
        }
    }
}

@Composable
private fun SectionTitle(title: String) {
    Text(
        title,
        style = MaterialTheme.typography.titleSmall,
        fontWeight = FontWeight.SemiBold,
        color = MaterialTheme.colorScheme.primary,
        modifier = Modifier.padding(start = 4.dp, top = 12.dp, bottom = 4.dp),
    )
}

@Composable
private fun InfoCard(text: String) {
    Card(
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceContainerHigh,
        ),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Text(
            text,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(16.dp),
        )
    }
}

@Composable
private fun EmptyHint(text: String) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ShortcutRow(
    iconRes: Int,
    title: String,
    actionLabel: String,
    actionIcon: androidx.compose.ui.graphics.vector.ImageVector,
    onAction: () -> Unit,
) {
    Card(
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface,
        ),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(start = 16.dp, end = 8.dp)
                .height(56.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(
                painter = painterResource(iconRes),
                contentDescription = null,
                modifier = Modifier.size(28.dp),
                tint = MaterialTheme.colorScheme.primary,
            )
            Spacer(Modifier.width(14.dp))
            Text(
                title,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.weight(1f),
            )
            IconButton(onClick = onAction) {
                Icon(
                    actionIcon,
                    contentDescription = actionLabel,
                    tint = MaterialTheme.colorScheme.primary,
                )
            }
        }
    }
}
