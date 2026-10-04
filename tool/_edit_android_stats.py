# -*- coding: utf-8 -*-
"""Android：注册 stats_dialog 通道（Compose 播放信息对话框）+ 卸载时清理。"""
import io

P = 'android/app/src/main/kotlin/com/memz2345/navi/flash/MainActivity.kt'
s = io.open(P, encoding='utf-8').read()


def rep(old, new, count=1):
    global s
    n = s.count(old)
    assert n == count, ('count=%d expect=%d' % (n, count), old[:90])
    s = s.replace(old, new, count)


# 1. 通道名常量
rep(
    '    private val EXPORT_FILE_CHANNEL = "com.memz2345.navi.flash/export_file"\n',
    '    private val EXPORT_FILE_CHANNEL = "com.memz2345.navi.flash/export_file"\n'
    '    private val STATS_CHANNEL = "com.memz2345.navi.flash/stats_dialog"\n',
)

# 2. 注册（接在 15 号通道后面）
rep(
    """                exportFileExecutor.execute {
                    try {
                        val saved = saveExportFileToDownloads(src, name, mime)
                        runOnUiThread { result.success(saved) }
                    } catch (e: Exception) {
                        runOnUiThread { result.error("SAVE_FAILED", e.message, null) }
                    }
                }
            } else {
                result.notImplemented()
            }
        }
    }
""",
    """                exportFileExecutor.execute {
                    try {
                        val saved = saveExportFileToDownloads(src, name, mime)
                        runOnUiThread { result.success(saved) }
                    } catch (e: Exception) {
                        runOnUiThread { result.error("SAVE_FAILED", e.message, null) }
                    }
                }
            } else {
                result.notImplemented()
            }
        }

        // 16. 播放信息对话框：Windows 那边是原生 TaskDialog，Android 这边用
        //     Jetpack Compose 对话框显示同一份数据（见 StatsDialogHost.kt）。
        //     对话框打开期间每 500ms 回调 Dart 的 getStats 实时刷新。
        val statsChannel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STATS_CHANNEL)
        statsChannel.setMethodCallHandler { call, result ->
            if (call.method == "showStats") {
                val title = call.argument<String>("title") ?: ""
                val copyLabel = call.argument<String>("copyLabel") ?: "复制"
                val closeLabel = call.argument<String>("closeLabel") ?: "关闭"
                val entries = (call.argument<List<*>>("entries") ?: emptyList<Any>())
                    .mapNotNull { row ->
                        val pair = row as? List<*> ?: return@mapNotNull null
                        val label = pair.getOrNull(0) as? String ?: return@mapNotNull null
                        val value = pair.getOrNull(1) as? String ?: return@mapNotNull null
                        label to value
                    }
                StatsDialogHost.show(this, statsChannel, title, entries, copyLabel, closeLabel)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
""",
)

# 3. Activity 销毁时移除浮层，避免视图泄漏
rep(
    """    // 把导出文件写入公共下载目录，返回用户可见的位置描述。""",
    """    override fun onDestroy() {
        // 播放信息对话框是挂在 content 子树下的 ComposeView，Activity 销毁时
        // 必须摘掉，否则会连着旧的 decorView 一起泄漏。
        StatsDialogHost.dismiss()
        super.onDestroy()
    }

    // 把导出文件写入公共下载目录，返回用户可见的位置描述。""",
)

io.open(P, 'w', encoding='utf-8', newline='').write(s)
print('ok')
