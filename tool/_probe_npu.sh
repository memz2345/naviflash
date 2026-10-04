#!/system/bin/sh
# NPU 实测采样器 —— 不依赖 logcat（vivo ROM 屏蔽第三方日志），
# 只从 /proc 拿硬证据：后端模块是否加载、有没有 HTP/DSP 线程、
# 有没有 FastRPC/dmabuf 句柄、CPU 算力落点。
PKG=com.memz2345.navi.flash
END=$(( $(date +%s) + 1500 ))   # 采样 25 分钟
while [ "$(date +%s)" -lt "$END" ]; do
  PID=$(pidof "$PKG")
  TS=$(date +%H:%M:%S)
  if [ -z "$PID" ]; then
    echo "$TS NOPROC"
    sleep 2
    continue
  fi
  echo "=== $TS pid=$PID ==="
  MAPS=$(run-as "$PKG" cat /proc/$PID/maps 2>/dev/null)
  echo "--mods-- $(echo "$MAPS" | grep -oE 'lib[a-zA-Z0-9_.-]+\.so' | sort -u | grep -E 'ggml|llama|htp|cdsprpc|qnn' | tr '\n' ' ')"
  echo "--thr-- $(for t in /proc/$PID/task/*; do cat $t/comm 2>/dev/null; echo; done | sort -u | grep -iE 'htp|hex|dsp|rpc|fast|npu' | tr '\n' ' ')"
  echo "--dev-- $(run-as "$PKG" ls -l /proc/$PID/fd 2>/dev/null | grep -oE '/dev/[a-zA-Z0-9_-]+' | sort -u | tr '\n' ' ')"
  echo "--rss-- $(run-as "$PKG" cat /proc/$PID/status 2>/dev/null | grep -E 'VmRSS' | tr -s ' ')"
  echo "--top-- $(top -b -n 1 -p $PID -H 2>/dev/null | tail -n +6 | head -6 | tr -s ' ' | tr '\n' '|')"
  sleep 2
done
echo "=== PROBE DONE ==="
