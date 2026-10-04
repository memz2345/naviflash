# NaviFlash 默认打包脚本（以后打正式包就跑这个）。
#
#   powershell -ExecutionPolicy Bypass -File tool/build-apk.ps1
#
# 默认 = release 最小体积 + 自带压缩 + 混淆（`flutter build apk` 默认即 release，
# 配上下面的 gradle 改动，裸命令也是这套）：
#   --target-platform=android-arm64  仅 arm64 单包（体积最小；老 32 位机装不上，
#                                 要兼容改成 --split-per-abi 一次打 3 个包）
#   --shrink                        R8 代码压缩 + res 资源收缩（gradle 里已默认开，
#                                 这里再显式传一次，双保险）
#   --obfuscate                     Dart 代码混淆（flutter 不支持写进配置文件默认开启，
#                                 只能走命令行，所以才有这个脚本）
#   --split-debug-info              符号表外置：APK 更小，且崩溃堆栈可用符号表还原
#   --tree-shake-icons              裁剪未用图标字体（release 默认即开，显式声明）
#
# AVD 联调要 x86_64 全架构 debug 包时，把 $apkArgs 换成下面注释那组
#（target-platform 显式写全三个 arch，不依赖默认值；gradle 那边 debug
# buildType 已配全架构 abiFilters，无需再改 gradle）：
#   $apkArgs = @(
#       'build',
#       'apk',
#       '--debug',
#       '--target-platform=android-arm,android-arm64,android-x64'
#   )
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $root

# 每次构建前清掉上次的符号表目录，避免混入旧版本符号
$debugInfo = Join-Path $root 'build/app/debug-info'
if (Test-Path -LiteralPath $debugInfo) {
    Remove-Item -LiteralPath $debugInfo -Recurse -Force
}

# 注：故意不用反引号续行（Win PS5.1 配 LF 换行时续行可能失效导致参数丢失），改用数组 splatting
$apkArgs = @(
    'build',
    'apk',
    '--release',
    '--target-platform=android-arm64',
    '--shrink',
    '--obfuscate',
    '--split-debug-info=build/app/debug-info',
    '--tree-shake-icons'
)
& flutter @apkArgs

Write-Host ''
Write-Host '产物：'
$apkDir = Join-Path $root 'build/app/outputs/flutter-apk'
Get-ChildItem -LiteralPath $apkDir -Filter *.apk | ForEach-Object {
    $mb = [math]::Round($_.Length / 1MB, 1)
    Write-Host ("  {0}  {1} MB  {2}" -f $_.Name, $mb, $_.LastWriteTime)
}
