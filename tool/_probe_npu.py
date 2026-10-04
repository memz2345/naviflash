"""NPU 实测采样器（Windows 侧驱动）。
判据核心：推理若真在 Hexagon NPU，host 侧 CPU 时间应平缓增长（只是提交+等待）；
若回退 CPU，进程累计 CPU 时间会随合成字数线性暴涨。
不依赖 logcat —— vivo ROM 屏蔽第三方应用的 flutter/stderr 输出。
"""
import subprocess
import sys
import time

ADB = r"C:\Users\memz2345\AppData\Local\Android\Sdk\platform-tools\adb.exe"
PKG = "com.memz2345.navi.flash"
OUT = r"C:\Users\memz2345\AppData\Local\Temp\navi_probe.log"

CMDS = r"""PID=$(pidof PKGNAME)
echo "PID=$PID"
echo "MODS=$(run-as PKGNAME cat /proc/$PID/maps 2>/dev/null | grep -oE 'libggml[a-zA-Z0-9_.-]*\.so|libllam[a-zA-Z0-9_.-]*\.so|libcdsprpc\.so' | sort -u | tr '\n' ',')"
echo "FD_ADSPRPC=$(run-as PKGNAME ls -l /proc/$PID/fd 2>/dev/null | grep -c adsprpc)"
echo "NTHR=$(run-as PKGNAME ls /proc/$PID/task 2>/dev/null | wc -l)"
echo "CPUTIME=$(run-as PKGNAME cat /proc/$PID/stat 2>/dev/null | awk '{print $14+$15}')"
echo "NPUTHR=$(for t in /proc/$PID/task/*; do cat $t/comm 2>/dev/null; echo; done 2>/dev/null | sort -u | grep -icE 'htp|hex|rpc|dsp')"
echo "RSS=$(run-as PKGNAME cat /proc/$PID/status 2>/dev/null | awk '/VmRSS/{print $2}')"
""".replace("PKGNAME", PKG)


def sample():
    r = subprocess.run([ADB, "shell", CMDS], capture_output=True, text=True, timeout=40)
    return r.stdout.strip().replace("\n", " ")


def main():
    minutes = float(sys.argv[1]) if len(sys.argv) > 1 else 25
    end = time.time() + minutes * 60
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(f"# probe start {time.strftime('%H:%M:%S')} for {minutes} min\n")
        f.flush()
        while time.time() < end:
            ts = time.strftime("%H:%M:%S")
            try:
                line = sample()
            except Exception as e:
                line = f"ERR {e}"
            f.write(f"{ts} {line}\n")
            f.flush()
            print(f"{ts} {line}", flush=True)
            time.sleep(2)
    print("PROBE DONE", flush=True)


if __name__ == "__main__":
    main()
