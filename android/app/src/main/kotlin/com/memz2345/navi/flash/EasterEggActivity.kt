package com.memz2345.navi.flash

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.*
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.math.sin
import kotlin.math.cos

class EasterEggActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM) {
            enableEdgeToEdge()
        }
        setContent {
            EasterEggTheme {
                EasterEggScreen(onFinish = { finish() })
            }
        }
    }
}

// ================= Theme =================

@Composable
fun EasterEggTheme(content: @Composable () -> Unit) {
    val darkTheme = isSystemInDarkTheme()
    val colorScheme = if (darkTheme) darkColorScheme(
        primary = Color(0xFF90CAF9),
        onPrimary = Color(0xFF0D47A1),
        primaryContainer = Color(0xFF1565C0),
        secondary = Color(0xFFCE93D8),
        tertiary = Color(0xFF80DEEA),
        background = Color(0xFF0F0F1A),
        surface = Color(0xFF1A1A2E),
        surfaceVariant = Color(0xFF252540),
    ) else lightColorScheme(
        primary = Color(0xFF1565C0),
        secondary = Color(0xFF7B1FA2),
        tertiary = Color(0xFF00838F),
        background = Color(0xFFF5F5FF),
        surface = Color(0xFFFFFFFF),
        surfaceVariant = Color(0xFFECECFA),
    )

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography(
            titleLarge = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold),
            titleMedium = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold),
        ),
        content = content
    )
}

// ================= Screen =================

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EasterEggScreen(onFinish: () -> Unit) {
    val ctx = LocalContext.current
    val prefs = ctx.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

    // State mirrors Flutter SettingsService keys
    var fontSizeW by remember { mutableStateOf(prefs.getFloat("flutter.fontWeight", 400f)) }
    var isPureBlack by remember { mutableStateOf(prefs.getBoolean("flutter.isPureBlackMode", false)) }
    var useDynamic by remember { mutableStateOf(prefs.getBoolean("flutter.useDynamicColor", true)) }
    var fragmentRendering by remember { mutableStateOf(prefs.getBoolean("flutter.enableFragmentRendering", false)) }
    var bgOpacity by remember { mutableStateOf(prefs.getFloat("flutter.backgroundImageOpacity", 1f)) }
    var displayScale by remember { mutableStateOf(prefs.getFloat("flutter.displayScale", 1f)) }
    val isLocked = prefs.getBoolean("flutter.isLocked", false)
    val nickname = prefs.getString("flutter.nickname", null) ?: "未设置"
    val themeMode = prefs.getString("flutter.themeMode", null) ?: "system"
    val webDavEnabled = prefs.getBoolean("flutter.webdav_enabled", false)

    // Easter egg counters
    var tapCount by remember { mutableStateOf(0) }
    var showSecret by remember { mutableStateOf(false) }
    var starRotation by remember { mutableStateOf(0f) }

    val infRotation = rememberInfiniteTransition()
    val bgHue by infRotation.animateFloat(
        initialValue = 240f, targetValue = 320f,
        animationSpec = infiniteRepeatable(tween(8000, easing = LinearEasing))
    )
    val animatedBg = Brush.linearGradient(
        listOf(
            Color.hsl(bgHue, 0.35f, 0.12f),
            Color.hsl(bgHue + 30f, 0.25f, 0.08f),
            Color.hsl(bgHue + 60f, 0.3f, 0.06f),
        ),
        start = Offset(0f, 0f), end = Offset(1000f, 2000f)
    )

    fun save(key: String, value: Any) {
        prefs.edit().apply {
            when (value) {
                is Boolean -> putBoolean("flutter.$key", value)
                is Float -> putFloat("flutter.$key", value)
                is String -> putString("flutter.$key", value)
                is Int -> putInt("flutter.$key", value)
                is Long -> putLong("flutter.$key", value)
            }
            apply()
        }
    }

    Box(modifier = Modifier.fillMaxSize().background(animatedBg)) {
        Column(modifier = Modifier.fillMaxSize()) {
            // Top bar
            TopAppBar(
                title = {
                    Row {
                        if (tapCount >= 7) {
                            Icon(
                                Icons.Filled.AutoAwesome,
                                contentDescription = null,
                                modifier = Modifier.rotate(starRotation).scale(1f + (tapCount % 3) * 0.15f),
                                tint = Color(0xFFFFD700)
                            )
                            Spacer(Modifier.width(8.dp))
                        }
                        Text(if (showSecret) "✨ 你发现了秘密" else "Navi 实验室")
                    }
                },
                actions = {
                    IconButton(onClick = onFinish) {
                        Icon(Icons.Filled.Close, contentDescription = "关闭")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.7f)
                )
            )

            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // --- Secret section ---
                item {
                    AnimatedVisibility(visible = showSecret, enter = fadeIn() + slideInVertically()) {
                        Card(
                            colors = CardDefaults.cardColors(
                                containerColor = Color(0xFFFFD700).copy(alpha = 0.15f)
                            ),
                            shape = RoundedCornerShape(16.dp)
                        ) {
                            Column(Modifier.padding(16.dp)) {
                                Text("🏆 你找到了隐藏实验室！", style = MaterialTheme.typography.titleMedium)
                                Spacer(Modifier.height(4.dp))
                                Text("连点标题 ${tapCount} 次", style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f))
                            }
                        }
                    }
                }

                // --- Profile ---
                item { SectionHeader("个人资料") }
                item {
                    SettingCard {
                        SettingRow(Icons.Filled.Person, "昵称", nickname)
                    }
                }
                item {
                    SettingCard {
                        SettingRow(Icons.Filled.Lock, "锁定状态", if (isLocked) "已锁定" else "未锁定")
                    }
                }

                // --- Display ---
                item { SectionHeader("显示") }
                item {
                    SettingCard {
                        SettingRow(Icons.Filled.Palette, "主题模式",
                            when(themeMode) { "light" -> "浅色" "dark" -> "深色" else -> "跟随系统" })
                    }
                }
                item {
                    SettingCard {
                        ToggleRow(Icons.Filled.AutoFixHigh, "动态取色", useDynamic) {
                            useDynamic = it; save("useDynamicColor", it)
                        }
                    }
                }
                item {
                    SettingCard {
                        ToggleRow(Icons.Filled.DarkMode, "纯黑模式", isPureBlack) {
                            isPureBlack = it; save("isPureBlackMode", it)
                        }
                    }
                }
                item {
                    SettingCard {
                        SliderRow(Icons.Filled.FormatSize, "字体粗细", fontSizeW, 100f..900f, 100f) {
                            fontSizeW = it; save("fontWeight", it)
                        }
                    }
                }
                item {
                    SettingCard {
                        SliderRow(Icons.Filled.ZoomIn, "显示缩放", displayScale, 0.5f..2f, 0.25f) {
                            displayScale = it; save("displayScale", it)
                        }
                    }
                }
                item {
                    SettingCard {
                        SliderRow(Icons.Filled.Opacity, "背景图透明度", bgOpacity, 0f..1f, 0.1f) {
                            bgOpacity = it; save("backgroundImageOpacity", it)
                        }
                    }
                }

                // --- Features ---
                item { SectionHeader("功能") }
                item {
                    SettingCard {
                        ToggleRow(Icons.Filled.ViewCarousel, "磁贴碎片渲染", fragmentRendering) {
                            fragmentRendering = it; save("enableFragmentRendering", it)
                        }
                    }
                }
                item {
                    SettingCard {
                        SettingRow(
                            Icons.Filled.Cloud,
                            "WebDAV 备份",
                            if (webDavEnabled) "已启用" else "未启用"
                        )
                    }
                }

                // --- Secret toggle ---
                item {
                    AnimatedVisibility(visible = showSecret) {
                        Card(
                            shape = RoundedCornerShape(16.dp),
                            modifier = Modifier.clickable {
                                // Playful: open Flutter settings
                                ctx.startActivity(Intent(ctx, EasterEggActivity::class.java).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                })
                            }
                        ) {
                            Column(Modifier.padding(16.dp)) {
                                Text("🎮 开发者彩蛋", style = MaterialTheme.typography.titleSmall)
                                Text("无限循环中，请勿退出", style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f))
                            }
                        }
                    }
                }

                // Device info
                item { SectionHeader("设备信息") }
                item {
                    SettingCard {
                        DeviceInfoRow()
                    }
                }

                // Spacer bottom
                item { Spacer(Modifier.height(32.dp)) }
            }
        }

        // Floating easter egg star
        if (showSecret) {
            Icon(
                Icons.Filled.AutoAwesome,
                contentDescription = null,
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .padding(24.dp)
                    .scale(1.5f)
                    .rotate(starRotation),
                tint = Color(0xFFFFD700)
            )
        }

        // Tap handler on header
        Box(
            modifier = Modifier
                .align(Alignment.TopCenter)
                .fillMaxWidth()
                .height(64.dp)
                .clickable {
                    tapCount++
                    starRotation += 72f
                    if (tapCount >= 7) showSecret = true
                }
        )
    }
}

// ================= Composable Helpers =================

@Composable
fun SectionHeader(title: String) {
    Text(
        title,
        style = MaterialTheme.typography.labelLarge,
        color = MaterialTheme.colorScheme.primary,
        modifier = Modifier.padding(top = 12.dp, bottom = 4.dp, start = 4.dp)
    )
}

@Composable
fun SettingCard(content: @Composable () -> Unit) {
    Card(
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.75f)),
    ) {
        content()
    }
}

@Composable
fun SettingRow(icon: ImageVector, title: String, value: String) {
    Row(
        modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(22.dp))
        Spacer(Modifier.width(12.dp))
        Text(title, modifier = Modifier.weight(1f))
        Text(value, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f), fontSize = 14.sp)
    }
}

@Composable
fun ToggleRow(icon: ImageVector, title: String, checked: Boolean, onToggle: (Boolean) -> Unit) {
    Row(
        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(22.dp))
        Spacer(Modifier.width(12.dp))
        Text(title, modifier = Modifier.weight(1f))
        Switch(checked = checked, onCheckedChange = onToggle)
    }
}

@Composable
fun SliderRow(icon: ImageVector, title: String, value: Float, range: ClosedFloatingPointRange<Float>, step: Float, onChange: (Float) -> Unit) {
    Column(modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(22.dp))
            Spacer(Modifier.width(12.dp))
            Text(title, modifier = Modifier.weight(1f))
            Text(String.format("%.2f", value), color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f), fontSize = 13.sp)
        }
        Slider(
            value = value,
            onValueChange = onChange,
            valueRange = range,
            steps = if (step > 0) ((range.endInclusive - range.start) / step).toInt() - 1 else 0,
            modifier = Modifier.padding(horizontal = 8.dp)
        )
    }
}

@Composable
fun DeviceInfoRow() {
    Column(Modifier.padding(16.dp)) {
        Row {
            Text("品牌", modifier = Modifier.weight(1f), color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f), fontSize = 13.sp)
            Text(Build.BRAND, fontSize = 13.sp)
        }
        Spacer(Modifier.height(4.dp))
        Row {
            Text("型号", modifier = Modifier.weight(1f), color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f), fontSize = 13.sp)
            Text(Build.MODEL, fontSize = 13.sp)
        }
        Spacer(Modifier.height(4.dp))
        Row {
            Text("系统", modifier = Modifier.weight(1f), color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f), fontSize = 13.sp)
            Text("Android ${Build.VERSION.SDK_INT}", fontSize = 13.sp)
        }
        Spacer(Modifier.height(4.dp))
        Row {
            Text("包名", modifier = Modifier.weight(1f), color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f), fontSize = 13.sp)
            Text("com.memz2345.navi.flash", fontSize = 13.sp)
        }
    }
}
