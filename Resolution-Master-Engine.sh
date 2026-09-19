#!/system/bin/sh
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                              ║
# ║   🌌 PROJECT GENESIS — RESOLUTION MASTER ENGINE (RME)                        ║
# ║   Universal Display Pipeline & Proportional DPI Downscale Engine            ║
# ║   Official Companion Series to Milkyway Equation                             ║
# ║                                                                              ║
# ║   Target : INFINIX · TECNO · ITEL · ALL ANDROID (60Hz / 120Hz / 144Hz)      ║
# ║   SoC    : MediaTek Helio G99 · G200 · Dimensity · Snapdragon · Exynos       ║
# ║   OS     : Android 11 · 12 · 13 · 14 · 15 · 16 (AOSP / XOS / HiOS / HyperOS) ║
# ║   Version: 1.0.0 PUBLIC RELEASE (B64 MASTER ARCHITECTURE)                   ║
# ║   Author : Aceng D Monk                                                     ║
# ║                                                                              ║
# ╠══════════════════════════════════════════════════════════════════════════════╣
# ║  HOW TO RUN / CARA MENJALANKAN (NO ROOT REQUIRED / TANPA ROOT)               ║
# ║  EN: Run this script using ADB, Shizuku (aShell/Termux), or Terminal:        ║
# ║      • ADB PC       → adb push RME.sh /data/local/tmp/ && adb shell          ║
# ║                       sh /data/local/tmp/RME.sh                              ║
# ║      • Shizuku/LADB → cp /sdcard/RME.sh /data/local/tmp/ &&                  ║
# ║                       sh /data/local/tmp/RME.sh                              ║
# ║                                                                              ║
# ║  ID: Jalankan script ini menggunakan ADB, Shizuku, LADB, atau Termux:        ║
# ║      • Salin berkas ke /data/local/tmp/ agar bebas blokir izin noexec.       ║
# ║      • Beri izin eksekusi: chmod +x /data/local/tmp/RME.sh                   ║
# ╠══════════════════════════════════════════════════════════════════════════════╣
# ║  🛡️  SAFETY WATCHDOG ACTIVE / SISTEM PENGAMAN LAYAR AKTIF                    ║
# ║  EN: Every preview automatically rolls back after 30s if unconfirmed.       ║
# ║  ID: Setiap preview otomatis kembali ke asal dalam 30 detik jika tidak di-   ║
# ║      konfirmasi. Aman 100% dari risiko layar mati / black screen.            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

echo ""
echo "┌──────────────────────────────────────────────────────────────────────┐"
echo "│  🌌 RAResolution MASTER ENGINE (RME) — v1.0 PUBLIC RELEASE           │"
echo "│  ⚡ INITIALIZING DISPLAY SCALER... / MEMULAI ENGINE RESOLUSI...       │"
echo "└──────────────────────────────────────────────────────────────────────┘"
sleep 1

# ══════════════════════════════════════════════════════════════════════
# BLOCK 0 ▸ GLOBAL CONFIGURATION & USER KNOBS
# Function: User-facing preset selector, execution mode, & runtime timers.
# ══════════════════════════════════════════════════════════════════════

# ┌─────────────────────────────────────────────────────────────────────┐
# │  [A]  DOWNSCALE PRESET PROFILE / PROFIL RESOLUSI                    │
# │  GOLDEN      → 66.67% Scale (720p Class) · -55.6% GPU Pixel Load    │
# │                Infinix Note 50 Pro Target: 720x1624 @ 293 DPI       │
# │  PERFORMANCE → 70.0% Scale · Moderate Gaming Balance                │
# │                Infinix Note 50 Pro Target: 756x1705 @ 308 DPI       │
# │  EXTREME     → 50.0% Scale · Tournament Tier · -75.0% GPU Load      │
# │                Infinix Note 50 Pro Target: 540x1218 @ 220 DPI       │
# │  NATIVE      → 100% Reset · Immediately restore physical defaults   │
# └─────────────────────────────────────────────────────────────────────┘
DEFAULT_PRESET="GOLDEN"

# ┌─────────────────────────────────────────────────────────────────────┐
# │  [B]  EXECUTION BEHAVIOR / METODE PENERAPAN                         │
# │  PREVIEW → Safe Mode. Applies with 30s auto-rollback guard.         │
# │  INSTANT → Direct Mode. Bypasses timer. Ideal for game launchers.   │
# └─────────────────────────────────────────────────────────────────────┘
DEFAULT_EXEC_MODE="PREVIEW"

# ┌─────────────────────────────────────────────────────────────────────┐
# │  [C]  WATCHDOG TIMEOUT & TRANSSION SYNC SWITCH                      │
# └─────────────────────────────────────────────────────────────────────┘
PREVIEW_SECONDS=30
SYNC_TRANSSION_XOS=1

VERSION="1.0.0-PUBLIC"
NOTICE_TEXT=""
LIVE_OUTCOME_JSON=""
SCRIPT_PATH_RESOLVED=""

# ══════════════════════════════════════════════════════════════════════
# BLOCK 1 ▸ CORE SYSTEM VALIDATORS & RUNTIME SENSORS
# Function: Numeric constraints, UUID tokens, PID verification & get-config.
# ══════════════════════════════════════════════════════════════════════
number() {
    case "$1" in ''|*[!0-9]*|0[0-9]*) return 1 ;; esac
    [ "${#1}" -le 8 ] && [ "$1" -ge "$2" ] && [ "$1" -le "$3" ]
}

identifier() {
    case "$1" in ''|*[!a-f0-9-]*) return 1 ;; esac
    [ "${#1}" -eq 36 ]
}

size_valid() {
    case "$1" in *x*) ;; *) return 1 ;; esac
    number "${1%x*}" 200 16384 && number "${1#*x}" 200 16384
}

size_setting() {
    [ "$1" = reset ] || size_valid "$1"
}

density_setting() {
    [ "$1" = reset ] || number "$1" 72 2000
}

error() {
    printf '{"ok":false,"error":"%s"}\n' "$1"
    return 1
}

platform_uid() {
    /system/bin/id -u 2>/dev/null || echo 2000
}

platform_user() {
    timeout -s KILL 2 /system/bin/am get-current-user 2>/dev/null || echo 0
}

wm_call() {
    if [ "$#" -eq 1 ]; then
        timeout -s KILL 2 /system/bin/wm "$@" 2>/dev/null
    else
        timeout -s KILL 3 /system/bin/wm "$@" 2>/dev/null
    fi
}

am_config() {
    timeout -s KILL 2 /system/bin/am get-config 2>/dev/null
}

read_runtime() {
    CONFIG_TEXT=$(am_config) || return 1
    CONFIG_VALUES=$(printf '%s\n' "$CONFIG_TEXT" | awk '
        /^config: / {
            count = split($2, parts, "-")
            for (i = 1; i <= count; i++) {
                part = parts[i]
                if (part ~ /^sw[0-9]+dp$/) { sub(/^sw/, "", part); sub(/dp$/, "", part); sw = part }
                else if (part ~ /^w[0-9]+dp$/) { sub(/^w/, "", part); sub(/dp$/, "", part); w = part }
                else if (part ~ /^h[0-9]+dp$/) { sub(/^h/, "", part); sub(/dp$/, "", part); h = part }
                else if (part ~ /^[0-9]+dpi$/) { sub(/dpi$/, "", part); d = part }
                else if (part == "ldpi") d = 120
                else if (part == "mdpi") d = 160
                else if (part == "tvdpi") d = 213
                else if (part == "hdpi") d = 240
                else if (part == "xhdpi") d = 320
                else if (part == "xxhdpi") d = 480
                else if (part == "xxxhdpi") d = 640
            }
            if (d && w && h && sw) printf "%s %s %s %s\n", d, w, h, sw
            exit
        }')
    read -r ACTIVE_DPI ACTIVE_WIDTH ACTIVE_HEIGHT ACTIVE_SMALLEST <<EOF
$CONFIG_VALUES
EOF
    number "$ACTIVE_DPI" 72 2000 && number "$ACTIVE_WIDTH" 1 65535 &&
        number "$ACTIVE_HEIGHT" 1 65535 && number "$ACTIVE_SMALLEST" 1 65535
}

clock_now() {
    read -r CLOCK_VALUE CLOCK_UNUSED < /proc/uptime 2>/dev/null || return 1
    CLOCK_VALUE=${CLOCK_VALUE%%.*}
    number "$CLOCK_VALUE" 0 99999999 || return 1
    printf '%s\n' "$CLOCK_VALUE"
}

boot_id() {
    read -r BOOT_VALUE < /proc/sys/kernel/random/boot_id 2>/dev/null || return 1
    identifier "$BOOT_VALUE" || return 1
    printf '%s\n' "$BOOT_VALUE"
}

new_token() {
    read -r TOKEN_VALUE < /proc/sys/kernel/random/uuid 2>/dev/null || return 1
    identifier "$TOKEN_VALUE" || return 1
    printf '%s\n' "$TOKEN_VALUE"
}

process_start() {
    sed 's/^.*) //' "/proc/$1/stat" 2>/dev/null | awk '{print $20}'
}

process_alive() {
    kill -0 "$1" 2>/dev/null
}

# ══════════════════════════════════════════════════════════════════════
# BLOCK 2 ▸ SCRIPT PATH RESOLVER & ATOMIC DIRECTORY LOCK
# Function: POSIX Atomic Lock without flock dependency & PID auto-purge.
# ══════════════════════════════════════════════════════════════════════
resolve_script_path() {
    if [ -n "$SCRIPT_PATH_RESOLVED" ] && [ -f "$SCRIPT_PATH_RESOLVED" ]; then
        return 0
    fi
    if [ -f "$0" ]; then
        case "$0" in
            /*) SCRIPT_PATH_RESOLVED="$0" ;;
            *) SCRIPT_PATH_RESOLVED="$(pwd)/$0" ;;
        esac
    fi
    if [ -z "$SCRIPT_PATH_RESOLVED" ] || [ ! -f "$SCRIPT_PATH_RESOLVED" ]; then
        for candidate in \
            "/data/local/tmp/Resolution-Master-Engine.sh" \
            "/data/local/tmp/RME.sh" \
            "/data/local/tmp/display.sh" \
            "/sdcard/Resolution-Master-Engine.sh" \
            "/sdcard/RME.sh" \
            "$MODDIR/Resolution-Master-Engine.sh"; do
            if [ -f "$candidate" ]; then
                SCRIPT_PATH_RESOLVED="$candidate"
                break
            fi
        done
    fi
    [ -f "$SCRIPT_PATH_RESOLVED" ] || SCRIPT_PATH_RESOLVED="/data/local/tmp/Resolution-Master-Engine.sh"
}

initialize() {
    CURRENT_UID=$(platform_uid)
    [ "$CURRENT_UID" = "2000" ] || [ "$CURRENT_UID" = "0" ] || {
        error "Access denied. Run via ADB Shell (UID 2000), Shizuku, or Root."
        return 1
    }

    umask 077

    # Path resolver: AxManager / Axora / Standalone ADB
    if [ -n "$MODDIR" ] && [ -d "${MODDIR%/*/*}" ]; then
        STATE="${MODDIR%/*/*}/var/raresolution"
    else
        STATE="/data/local/tmp/raresolution"
    fi

    [ ! -L "${STATE%/*}" ] && [ ! -L "$STATE" ] || {
        error "Invalid symbolic link in state directory"
        return 1
    }
    mkdir -p "$STATE" 2>/dev/null || {
        error "Cannot create state directory in $STATE"
        return 1
    }

    for ENTRY in pending original owned recovery outcome last; do
        [ ! -L "$STATE/$ENTRY" ] || {
            error "Security violation: symbolic link detected"
            return 1
        }
        [ ! -e "$STATE/$ENTRY" ] || [ -f "$STATE/$ENTRY" ] || {
            error "Corrupt state file"
            return 1
        }
    done
    BOOT=$(boot_id) || {
        error "Cannot read kernel boot identity"
        return 1
    }
}

take_lock() {
    LOCK_DIR="$STATE/lock.d"
    LOCK_TRIES=0

    while ! mkdir "$LOCK_DIR" 2>/dev/null; do
        LOCK_TRIES=$((LOCK_TRIES + 1))
        if [ "$LOCK_TRIES" -ge 40 ]; then
            # Clean up stale locks if process dead
            if [ -f "$LOCK_DIR/pid" ]; then
                read -r LPID < "$LOCK_DIR/pid" 2>/dev/null
                if [ -n "$LPID" ] && ! kill -0 "$LPID" 2>/dev/null; then
                    rm -rf "$LOCK_DIR" 2>/dev/null
                    continue
                fi
            else
                rm -rf "$LOCK_DIR" 2>/dev/null
                continue
            fi
            error "Display resource busy. Another instance is active."
            return 1
        fi
        sleep 0.1
    done
    echo "$$" > "$LOCK_DIR/pid" 2>/dev/null
}

release_lock() {
    rm -rf "$STATE/lock.d" 2>/dev/null
}

# ══════════════════════════════════════════════════════════════════════
# BLOCK 3 ▸ WINDOW MANAGER & ACONFIG DISPLAY FLAGS
# Function: AOSP Native DPI correction, Auto-scaling bypass, Letterbox
#           Aspect Ratio lock & Orientation Request Overrides.
# ═══════════════════════════════════════════════════════════════════
sync_window_manager_flags() {
    # 1. Failsafe: Verifikasi dimensi resolusi fisik layar agar tidak bernilai kosong atau nol
    NATIVE_WIDTH="${PHYSICAL_WIDTH}"
    NATIVE_HEIGHT="${PHYSICAL_HEIGHT}"

    if [ -z "$NATIVE_WIDTH" ] || [ -z "$NATIVE_HEIGHT" ] || [ "$NATIVE_WIDTH" -eq 0 ] || [ "$NATIVE_HEIGHT" -eq 0 ]; then
        NATIVE_RES_WM=$(wm size 2>/dev/null | grep -Ei 'Physical|Override' | grep -oE '[0-9]+x[0-9]+' | head -n 1)
        NATIVE_WIDTH=$(echo "$NATIVE_RES_WM" | cut -d'x' -f1)
        NATIVE_HEIGHT=$(echo "$NATIVE_RES_WM" | cut -d'x' -f2)
        # Standar fallback resolusi FHD+ jika penelusuran sysfs/wm gagal
        [ -z "$NATIVE_WIDTH" ] && NATIVE_WIDTH=1080
        [ -z "$NATIVE_HEIGHT" ] && NATIVE_HEIGHT=2436
    fi

    # 2. Kalkulasi Dinamis Aspek Rasio Asli Layar secara Real-Time (Presisi 6 Desimal)
    ASPECT_RATIO=$(awk "BEGIN {printf \"%.6f\", $NATIVE_HEIGHT/$NATIVE_WIDTH}" 2>/dev/null)
    if [ -z "$ASPECT_RATIO" ] || [ "$ASPECT_RATIO" = "0.000000" ]; then
        # Fallback matematika biner murni jika shell tidak mendukung awk
        INTEG=$(( NATIVE_HEIGHT / NATIVE_WIDTH ))
        FRAC=$(( (NATIVE_HEIGHT % NATIVE_WIDTH) * 1000000 / NATIVE_WIDTH ))
        FRAC_LEN=${#FRAC}
        while [ "$FRAC_LEN" -lt 6 ]; do
            FRAC="0$FRAC"
            FRAC_LEN=${#FRAC}
        done
        ASPECT_RATIO="${INTEG}.${FRAC}"
    fi

    # 3. Letterbox & Position Controls (Menyesuaikan Secara Dinamis terhadap Rasio Fisik Perangkat)
    cmd window set-letterbox-style --aspectRatio "$ASPECT_RATIO" >/dev/null 2>&1
    cmd window set-letterbox-style --minAspectRatioForUnresizable "$ASPECT_RATIO" >/dev/null 2>&1
    cmd window set-letterbox-style --horizontalPositionMultiplier 0.5 >/dev/null 2>&1
    cmd window set-letterbox-style --verticalPositionMultiplier 0.5 >/dev/null 2>&1

    # 4. Native Orientation Locking (Zero Compat Frame Overhead)
    wm set-ignore-orientation-request false >/dev/null 2>&1

    # 5. Direct Native Boundaries Rendering (Overscan & Auto-scale Bypass)
    wm scaling off >/dev/null 2>&1
    cmd window scaling off >/dev/null 2>&1
}

# ══════════════════════════════════════════════════════════════════════
# BLOCK 4 ▸ TRANSSION XOS / HIOS SYSTEM & HWC BUFFER SYNC
# Function: Keep Transsion display database & HWC framebuffer aligned.
# ═══════════════════════════════════════════════════════════════════
sync_transsion_system() {
    local w="$1" h="$2"
    [ "$SYNC_TRANSSION_XOS" = "1" ] || return 0
    local brand
    brand=$(getprop ro.product.brand 2>/dev/null | tr '[:upper:]' '[:lower:]')
    case "$brand" in
        *infinix*|*tecno*|*itel*|*transsion*)
            if [ "$w" = "reset" ]; then
                settings put system tran_resolution_size_0 "$PHYSICAL_SIZE" >/dev/null 2>&1
                settings put system tran_resolution_size_1 "$PHYSICAL_SIZE" >/dev/null 2>&1
                settings put system tran_resolution_default "$PHYSICAL_SIZE" >/dev/null 2>&1
                setprop debug.hwc.fbsize "$PHYSICAL_SIZE" 2>/dev/null
            else
                settings put system tran_resolution_size_0 "${w}x${h}" >/dev/null 2>&1
                settings put system tran_resolution_size_1 "${w}x${h}" >/dev/null 2>&1
                settings put system tran_resolution_default "${w}x${h}" >/dev/null 2>&1
                setprop debug.hwc.fbsize "${w}x${h}" 2>/dev/null
            fi
            ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════
# BLOCK 5 ▸ DISPLAY STATE RECORDERS & RECOVERY HELPERS
# Function: Manage backup files, verify runtime stability, & rollbacks.
# ═══════════════════════════════════════════════════════════════════
write_record() {
    RECORD_NAME=$1
    shift
    case "$RECORD_NAME" in pending|original|owned|recovery|outcome|last) ;; *) return 1 ;; esac
    RECORD_TEMP="$STATE/$RECORD_NAME.$$"
    [ ! -L "$RECORD_TEMP" ] || return 1
    if { printf '%s\n' "$*" > "$RECORD_TEMP" && mv -f "$RECORD_TEMP" "$STATE/$RECORD_NAME"; } 2>/dev/null; then
        return 0
    fi
    rm -f "$RECORD_TEMP" 2>/dev/null
    return 1
}

read_original() {
    [ -f "$STATE/original" ] || return 1
    [ "$(wc -l < "$STATE/original")" -eq 1 ] 2>/dev/null || return 2
    read -r ORIGINAL_SIZE ORIGINAL_DPI ORIGINAL_EXTRA < "$STATE/original" || return 2
    [ -z "$ORIGINAL_EXTRA" ] && size_setting "$ORIGINAL_SIZE" && density_setting "$ORIGINAL_DPI" || return 2
    [ "$(cat "$STATE/original")" = "$ORIGINAL_SIZE $ORIGINAL_DPI" ] || return 2
}

read_last() {
    [ -f "$STATE/last" ] || return 1
    [ "$(wc -l < "$STATE/last")" -eq 1 ] 2>/dev/null || return 2
    read -r L_SIZE L_DPI L_NATIVE L_NATIVE_DPI L_EXTRA < "$STATE/last" || return 2
    [ -z "$L_EXTRA" ] && size_valid "$L_SIZE" && number "$L_DPI" 72 1000 &&
        [ "$L_NATIVE" = "$PHYSICAL_SIZE" ] && [ "$L_NATIVE_DPI" = "$PHYSICAL_DPI" ] || return 2
    [ "$(cat "$STATE/last")" = "$L_SIZE $L_DPI $L_NATIVE $L_NATIVE_DPI" ] || return 2
}

read_display() {
    [ "$(platform_user)" = 0 ] || return 1
    SIZE_TEXT=$(wm_call size) || return 1
    DENSITY_TEXT=$(wm_call density) || return 1
    PHYSICAL_SIZE=$(printf '%s\n' "$SIZE_TEXT" | sed -n 's/^Physical size: *\([0-9][0-9]*x[0-9][0-9]*\)\r*$/\1/p')
    OVERRIDE_SIZE=$(printf '%s\n' "$SIZE_TEXT" | sed -n 's/^Override size: *\([0-9][0-9]*x[0-9][0-9]*\)\r*$/\1/p')
    PHYSICAL_DPI=$(printf '%s\n' "$DENSITY_TEXT" | sed -n 's/^Physical density: *\([0-9][0-9]*\)\r*$/\1/p')
    OVERRIDE_DPI=$(printf '%s\n' "$DENSITY_TEXT" | sed -n 's/^Override density: *\([0-9][0-9]*\)\r*$/\1/p')

    size_valid "$PHYSICAL_SIZE" && number "$PHYSICAL_DPI" 72 2000 || return 1
    [ -z "$OVERRIDE_SIZE" ] || size_valid "$OVERRIDE_SIZE" || return 1
    [ -z "$OVERRIDE_DPI" ] || number "$OVERRIDE_DPI" 72 2000 || return 1

    CURRENT_SIZE=${OVERRIDE_SIZE:-$PHYSICAL_SIZE}
    CURRENT_DPI=${OVERRIDE_DPI:-$PHYSICAL_DPI}
    PHYSICAL_WIDTH=${PHYSICAL_SIZE%x*}
    PHYSICAL_HEIGHT=${PHYSICAL_SIZE#*x}
}

read_pending() {
    [ -f "$STATE/pending" ] || return 1
    read -r P_TOKEN P_BOOT P_END P_SIZE P_DPI P_TARGET P_DENSITY P_EXTRA < "$STATE/pending" || return 2
    [ -z "$P_EXTRA" ] && identifier "$P_TOKEN" && identifier "$P_BOOT" &&
        number "$P_END" 0 99999999 && size_setting "$P_SIZE" && density_setting "$P_DPI" &&
        size_valid "$P_TARGET" && number "$P_DENSITY" 72 2000 || return 2
}

verify_pair() {
    VERIFY_SIZE=$1
    VERIFY_DPI=$2
    VERIFY_RUNTIME=${3:-2}
    VERIFY_COUNT=0
    VERIFY_STABLE=0
    until [ "$VERIFY_COUNT" -ge 4 ]; do
        VERIFY_COUNT=$((VERIFY_COUNT + 1))
        if read_display; then
            EXPECTED_SIZE=$VERIFY_SIZE
            EXPECTED_DPI=$VERIFY_DPI
            [ "$EXPECTED_SIZE" != reset ] || EXPECTED_SIZE=$PHYSICAL_SIZE
            [ "$EXPECTED_DPI" != reset ] || EXPECTED_DPI=$PHYSICAL_DPI
            if [ "$CURRENT_SIZE" = "$EXPECTED_SIZE" ] && [ "$CURRENT_DPI" = "$EXPECTED_DPI" ]; then
                VERIFY_MATCH=1
                [ "$VERIFY_SIZE" != reset ] || [ -z "$OVERRIDE_SIZE" ] || VERIFY_MATCH=0
                [ "$VERIFY_DPI" != reset ] || [ -z "$OVERRIDE_DPI" ] || VERIFY_MATCH=0
                if read_runtime; then
                    [ "$ACTIVE_DPI" = "$EXPECTED_DPI" ] || VERIFY_MATCH=0
                elif [ "$VERIFY_RUNTIME" = 1 ]; then
                    VERIFY_MATCH=0
                fi
                if [ "$VERIFY_MATCH" = 1 ]; then
                    VERIFY_STABLE=$((VERIFY_STABLE + 1))
                    [ "$VERIFY_STABLE" -lt 2 ] || return 0
                else
                    VERIFY_STABLE=0
                fi
            else
                VERIFY_STABLE=0
            fi
        else
            return 1
        fi
        [ "$VERIFY_COUNT" -ge 4 ] || sleep 0.25
    done
    return 1
}

set_pair() {
    SET_SIZE=$1
    SET_DPI=$2
    size_setting "$SET_SIZE" && density_setting "$SET_DPI" || return 1
    [ "$(platform_user)" = 0 ] || return 1
    wm_call size "$SET_SIZE" >/dev/null || return 1
    [ "$(platform_user)" = 0 ] || return 1
    wm_call density "$SET_DPI" >/dev/null || return 1

    # Injeksi Window Manager Flags (Letterbox, Scaling Off, Boundaries)
    sync_window_manager_flags

    # Injeksi Transsion XOS Database Sync
    if [ "$SET_SIZE" = "reset" ]; then
        sync_transsion_system reset reset
    else
        sync_transsion_system "${SET_SIZE%x*}" "${SET_SIZE#*x}"
    fi

    verify_pair "$SET_SIZE" "$SET_DPI" "${3:-2}"
}

record_outcome() {
    OUTCOME_KIND=$1
    case "$OUTCOME_KIND" in preview|kept|reverted|original|default) ;; *) return 1 ;; esac
    LIVE_OUTCOME_JSON=$(printf '{"kind":"%s","width":%s,"height":%s,"dpi":%s}' \
        "$OUTCOME_KIND" "${CURRENT_SIZE%x*}" "${CURRENT_SIZE#*x}" "$CURRENT_DPI")
    if OUTCOME_CLOCK=$(clock_now) && write_record outcome "$BOOT" "$OUTCOME_CLOCK" "$OUTCOME_KIND" "$CURRENT_SIZE" "$CURRENT_DPI"; then
        return 0
    fi
    rm -f "$STATE/outcome"
    return 1
}

read_recovery() {
    [ -f "$STATE/recovery" ] || return 1
    read -r R_TOKEN R_BOOT R_KIND R_SIZE R_DPI R_EXTRA < "$STATE/recovery" || return 2
    [ -z "$R_EXTRA" ] && identifier "$R_TOKEN" && identifier "$R_BOOT" &&
        size_setting "$R_SIZE" && density_setting "$R_DPI" || return 2
    case "$R_KIND" in previous|original|default) ;; *) return 2 ;; esac
}

queue_recovery() {
    write_record recovery "$1" "$BOOT" "$2" "$3" "$4"
}

attempt_recovery() {
    read_recovery || return 1
    set_pair "$R_SIZE" "$R_DPI" || return 1
    rm -f "$STATE/pending" || return 1
    case "$R_KIND" in
        original|default)
            rm -f "$STATE/original" "$STATE/owned" || return 1
            record_outcome "$R_KIND" || rm -f "$STATE/outcome"
            ;;
        previous) record_outcome reverted || rm -f "$STATE/outcome" ;;
    esac
    rm -f "$STATE/recovery"
}

rollback() {
    if [ ! -f "$STATE/recovery" ]; then
        read_pending || return 1
        queue_recovery "$P_TOKEN" previous "$P_SIZE" "$P_DPI" || return 1
    fi
    attempt_recovery
}

# ══════════════════════════════════════════════════════════════════════
# BLOCK 6 ▸ WATCHDOG RECOVERY DAEMON (30S SAFETY ROLLBACK)
# Function: Background guard process ensuring zero permanent black screens.
# ═══════════════════════════════════════════════════════════════════
guard_alive() {
    G_TOKEN=${1:-$P_TOKEN}
    [ -f "$STATE/ready.$G_TOKEN" ] || return 1
    [ ! -L "$STATE/ready.$G_TOKEN" ] || return 1
    read -r GUARD_PID GUARD_BOOT GUARD_START GUARD_EXTRA < "$STATE/ready.$G_TOKEN" 2>/dev/null || return 1
    [ -z "$GUARD_EXTRA" ] && number "$GUARD_PID" 1 99999999 && [ "$GUARD_BOOT" = "$BOOT" ] || return 1
    GUARD_ACTUAL=$(process_start "$GUARD_PID")
    [ -n "$GUARD_ACTUAL" ] && [ "$GUARD_ACTUAL" = "$GUARD_START" ] && process_alive "$GUARD_PID"
}

launch_guard() {
    resolve_script_path
    RUN_SHELL="${BB:-/system/bin/sh}"
    nohup "$RUN_SHELL" "$SCRIPT_PATH_RESOLVED" guard "$1" </dev/null >/dev/null 2>&1 &
}

ensure_guard() {
    ENSURE_TOKEN=$1
    guard_alive "$ENSURE_TOKEN" && return 0
    launch_guard "$ENSURE_TOKEN"
    READY_COUNT=0
    until guard_alive "$ENSURE_TOKEN"; do
        READY_COUNT=$((READY_COUNT + 1))
        [ "$READY_COUNT" -lt 30 ] || return 1
        sleep 0.1
    done
}

guard_loop() {
    WATCH_TOKEN=$1
    identifier "$WATCH_TOKEN" || return 1
    if read_recovery; then
        [ "$R_TOKEN" = "$WATCH_TOKEN" ] || return 1
    else
        read_pending && [ "$P_TOKEN" = "$WATCH_TOKEN" ] || return 1
    fi
    SELF_START=$(process_start "$$")
    case "$SELF_START" in ''|*[!0-9]*) return 1 ;; esac
    [ ! -L "$STATE/ready.$WATCH_TOKEN" ] || return 1
    printf '%s %s %s\n' "$$" "$BOOT" "$SELF_START" > "$STATE/ready.$WATCH_TOKEN" || return 1
    trap 'rm -f "$STATE/ready.$WATCH_TOKEN"' EXIT
    trap '' HUP
    RECOVERY_DELAY=1
    while [ -f "$STATE/pending" ] || [ -f "$STATE/recovery" ]; do
        take_lock || return 1
        if [ -f "$STATE/recovery" ]; then
            if ! read_recovery || [ "$R_TOKEN" != "$WATCH_TOKEN" ]; then
                release_lock
                return 0
            fi
            attempt_recovery && { release_lock; return 0; }
            RECOVERY_DELAY=5
        elif ! read_pending || [ "$P_TOKEN" != "$WATCH_TOKEN" ]; then
            release_lock
            return 0
        else
            NOW=$(clock_now) || NOW=$P_END
            if [ "$BOOT" != "$P_BOOT" ] || [ "$NOW" -ge "$P_END" ]; then
                rollback && { release_lock; return 0; }
                RECOVERY_DELAY=5
            fi
        fi
        release_lock
        sleep "$RECOVERY_DELAY"
    done
}

recover_pending() {
    if [ -f "$STATE/recovery" ]; then
        read_recovery || {
            error "Recovery state corrupted. Restoring default."
            return 1
        }
        if ! attempt_recovery; then
            ensure_guard "$R_TOKEN" >/dev/null 2>&1
            error "Restore in progress. Please wait."
            return 1
        fi
    fi
    [ -f "$STATE/pending" ] || return 0
    read_pending || {
        error "Recovery state corrupted. Restoring default."
        return 1
    }
    NOW=$(clock_now) || return 1
    if [ "$BOOT" != "$P_BOOT" ] || [ "$NOW" -ge "$P_END" ] || ! guard_alive; then
        if ! rollback; then
            read_recovery && ensure_guard "$R_TOKEN" >/dev/null 2>&1
            error "Rollback failed. Restoring physical default."
            return 1
        fi
    fi
}

# ══════════════════════════════════════════════════════════════════════
# BLOCK 7 ▸ DYNAMIC PRESET ENGINE (GOLDEN RATIO & UNIVERSAL MATH)
# Function: Hardcoded 1080x2436 logic + Universal GCD & Pythagorean DPI.
# ═══════════════════════════════════════════════════════════════════
detect_best_preset() {
    read_display || return 1
    MODE=${1:-$DEFAULT_PRESET}
    case "$MODE" in
        [gG][oO][lL][dD][eE][nN]|[bB][aA][lL][aA][nN][cC][eE][dD]|auto) MODE="golden" ;;
        [pP][eE][rR][fF][oO][rR][mM][aA][nN][cC][eE]) MODE="performance" ;;
        [eE][xX][tT][rR][eE][mM][eE]) MODE="extreme" ;;
        [nN][aA][tT][iI][vV][eE]|reset|default) MODE="native" ;;
        *) MODE="golden" ;;
    esac

    # 1. SPECIALIZED PROFILE: INFINIX NOTE 50 PRO (1080x2436 @ 440 DPI)
    if [ "$PHYSICAL_WIDTH" -eq 1080 ] && [ "$PHYSICAL_HEIGHT" -eq 2436 ]; then
        case "$MODE" in
            extreme)
                TARGET_W=540
                TARGET_H=1218
                TARGET_D=220
                PRESET_DESC="Infinix Note 50 Pro Extreme (540p / -75.0% GPU load)"
                ;;
            performance)
                TARGET_W=756
                TARGET_H=1705
                TARGET_D=308
                PRESET_DESC="Infinix Note 50 Pro Performance (70% Scale)"
                ;;
            golden|*)
                TARGET_W=720
                TARGET_H=1624
                TARGET_D=293
                PRESET_DESC="Infinix Note 50 Pro Golden Pro-Gaming (720p / -55.6% GPU load)"
                ;;
        esac
        return 0
    fi

    # 2. UNIVERSAL DYNAMIC ENGINE (ALL OTHER ANDROID DEVICES)
    case "$MODE" in
        extreme)
            # 50.0% Flat Scale Factor (Macroblock-aligned even integers)
            TARGET_W=$(( (PHYSICAL_WIDTH / 2 / 2) * 2 ))
            TARGET_H=$(( (PHYSICAL_HEIGHT / 2 / 2) * 2 ))
            PRESET_DESC="Universal Extreme Tier (50.0% Exact Downscale)"
            ;;
        performance)
            # 70.0% Scale Factor
            TARGET_W=$(( (PHYSICAL_WIDTH * 70 / 100 / 2) * 2 ))
            TARGET_H=$(( ((TARGET_W * PHYSICAL_HEIGHT / PHYSICAL_WIDTH) / 2) * 2 ))
            PRESET_DESC="Universal Performance Tier (70.0% Scale)"
            ;;
        golden|*)
            # Golden Ratio: 66.67% Scale Factor (Standard 720p class)
            TARGET_W=$(( (PHYSICAL_WIDTH * 2 / 3 / 2) * 2 ))
            TARGET_H=$(( ((TARGET_W * PHYSICAL_HEIGHT / PHYSICAL_WIDTH) / 2) * 2 ))
            PRESET_DESC="Universal Golden Pro-Gaming Tier (66.7% Balanced)"
            ;;
    esac

    # Proportional DPI calculation via diagonal pythagorean formula
    TARGET_D=$(awk -v w="$TARGET_W" -v h="$TARGET_H" \
                   -v nw="$PHYSICAL_WIDTH" -v nh="$PHYSICAL_HEIGHT" \
                   -v d="$PHYSICAL_DPI" \
        'BEGIN { printf "%d", d * sqrt(w*w + h*h) / sqrt(nw*nw + nh*nh) + 0.5 }')
}

# ══════════════════════════════════════════════════════════════════════
# BLOCK 8 ▸ USER ACTIONS, CLI DISPATCHER & STATUS REPORT
# Function: Preview countdown, token confirm, instant apply, & reset.
# ═══════════════════════════════════════════════════════════════════
preview() {
    [ "$#" -eq 3 ] || {
        error "Expected arguments: <width> <height> <dpi>"
        return 1
    }
    WIDTH=$1
    HEIGHT=$2
    DPI=$3

    number "$WIDTH" 200 8192 && number "$HEIGHT" 200 8192 && number "$DPI" 72 1000 || {
        error "Invalid resolution or DPI range"
        return 1
    }

    recover_pending || return 1
    [ ! -f "$STATE/pending" ] || {
        error "Confirm or restore the active preview first"
        return 1
    }

    if [ -f "$STATE/original" ]; then
        read_original || {
            error "Original display data invalid. Use 'reset' first"
            return 1
        }
    fi

    read_display || {
        error "Cannot read primary display output"
        return 1
    }
    read_runtime || {
        error "Cannot query active Android configuration. Reset display first"
        return 1
    }

    [ "$WIDTH" -le "$PHYSICAL_WIDTH" ] && [ "$HEIGHT" -le "$PHYSICAL_HEIGHT" ] || {
        error "Target resolution cannot exceed native dimensions"
        return 1
    }

    MIN_WIDTH=$(( (PHYSICAL_WIDTH * 30 + 50) / 100 ))
    MIN_HEIGHT=$(( (PHYSICAL_HEIGHT * 30 + 50) / 100 ))
    [ "$WIDTH" -ge "$MIN_WIDTH" ] && [ "$HEIGHT" -ge "$MIN_HEIGHT" ] || {
        error "Target resolution cannot fall below 30% of native dimensions"
        return 1
    }

    # Strict aspect ratio validation
    RATIO_ERROR=$(( WIDTH * PHYSICAL_HEIGHT - HEIGHT * PHYSICAL_WIDTH ))
    [ "$RATIO_ERROR" -ge 0 ] || RATIO_ERROR=$(( -RATIO_ERROR ))
    [ "$RATIO_ERROR" -le $(( (PHYSICAL_WIDTH + PHYSICAL_HEIGHT + 1) / 2 )) ] || {
        error "Dimensions violate native aspect ratio constraint"
        return 1
    }

    # Strict proportional DPI validation
    MATCHED_DPI=$(awk -v w="$WIDTH" -v h="$HEIGHT" \
                      -v nw="$PHYSICAL_WIDTH" -v nh="$PHYSICAL_HEIGHT" \
                      -v d="$PHYSICAL_DPI" \
        'BEGIN { printf "%d", d * sqrt(w*w + h*h) / sqrt(nw*nw + nh*nh) + 0.5 }')
    [ "$DPI" = "$MATCHED_DPI" ] || {
        error "DPI mismatch with native proportional calculation (Expected: $MATCHED_DPI)"
        return 1
    }

    [ "$CURRENT_SIZE" != "${WIDTH}x${HEIGHT}" ] || [ "$CURRENT_DPI" != "$DPI" ] || {
        status_json
        return
    }

    PREVIOUS_SIZE=${OVERRIDE_SIZE:-reset}
    PREVIOUS_DPI=${OVERRIDE_DPI:-reset}
    if [ ! -f "$STATE/original" ]; then
        write_record original "$PREVIOUS_SIZE" "$PREVIOUS_DPI" || {
            error "Cannot save initial display state"
            return 1
        }
    fi

    P_TOKEN=$(new_token) || return 1
    NOW=$(clock_now) || return 1
    P_END=$(( NOW + 90 ))
    write_record pending "$P_TOKEN" "$BOOT" "$P_END" "$PREVIOUS_SIZE" "$PREVIOUS_DPI" \
        "${WIDTH}x${HEIGHT}" "$DPI" || {
        error "Cannot commit pending recovery state"
        return 1
    }

    if ! ensure_guard "$P_TOKEN"; then
        rm -f "$STATE/pending"
        error "Safety recovery watchdog failed to spawn. Operation aborted."
        return 1
    fi

    if ! set_pair "${WIDTH}x${HEIGHT}" "$DPI" 1; then
        rollback
        error "SurfaceFlinger rejected the display change. Reverted."
        return 1
    fi

    NOW=$(clock_now) || return 1
    P_END=$(( NOW + PREVIEW_SECONDS ))
    write_record pending "$P_TOKEN" "$BOOT" "$P_END" "$PREVIOUS_SIZE" "$PREVIOUS_DPI" \
        "${WIDTH}x${HEIGHT}" "$DPI" || {
        rollback
        error "Watchdog timer update failed"
        return 1
    }

    record_outcome preview
    status_json
}

confirm_preview() {
    [ ! -f "$STATE/recovery" ] || {
        error "Display recovery is currently in progress"
        return 1
    }
    identifier "$1" || {
        error "Invalid confirmation token format"
        return 1
    }
    read_pending && [ "$1" = "$P_TOKEN" ] || {
        error "Preview session expired or invalid token"
        return 1
    }
    NOW=$(clock_now) || return 1
    if [ "$BOOT" != "$P_BOOT" ] || [ "$NOW" -ge "$P_END" ] || ! guard_alive; then
        rollback
        error "Preview window timed out. Screen reverted."
        return 1
    fi
    verify_pair "$P_TARGET" "$P_DENSITY" 1 || {
        error "Display state altered externally. Reverting."
        return 1
    }

    write_record owned "$P_TARGET" "$P_DENSITY" || {
        error "Failed to lock confirmed resolution"
        return 1
    }
    rm -f "$STATE/pending" || return 1
    record_outcome kept
    write_record last "$P_TARGET" "$P_DENSITY" "$PHYSICAL_SIZE" "$PHYSICAL_DPI"
    status_json
}

restore_target() {
    RESTORE_KIND=$1
    RESTORE_SIZE=$2
    RESTORE_DPI=$3
    RESTORE_TOKEN=$(new_token) || return 1
    queue_recovery "$RESTORE_TOKEN" "$RESTORE_KIND" "$RESTORE_SIZE" "$RESTORE_DPI" || return 1
    ensure_guard "$RESTORE_TOKEN" >/dev/null 2>&1
    attempt_recovery || {
        error "Failed to execute recovery sequence"
        return 1
    }
    status_json
}

restore_original() {
    if [ -f "$STATE/original" ]; then
        read_original || {
            error "Saved original state is unreadable"
            return 1
        }
        restore_target original "$ORIGINAL_SIZE" "$ORIGINAL_DPI"
        return
    fi
    recover_pending || return 1
    status_json
}

reset_default() {
    restore_target default reset reset
}

status_json() {
    read_display || {
        error "Cannot read active display frame"
        return 1
    }
    ACTIVE_JSON=null
    if read_runtime; then
        ACTIVE_JSON=$(printf '{"dpi":%s,"widthDp":%s,"heightDp":%s,"smallestWidthDp":%s}' \
            "$ACTIVE_DPI" "$ACTIVE_WIDTH" "$ACTIVE_HEIGHT" "$ACTIVE_SMALLEST")
    fi
    PENDING_JSON=null
    if read_pending; then
        NOW=$(clock_now) || return 1
        REMAINING=$(( P_END - NOW ))
        [ "$REMAINING" -ge 0 ] || REMAINING=0
        PENDING_JSON=$(printf '{"token":"%s","seconds":%s,"width":%s,"height":%s,"dpi":%s}' \
            "$P_TOKEN" "$REMAINING" "${P_TARGET%x*}" "${P_TARGET#*x}" "$P_DENSITY")
    fi
    ORIGINAL_JSON=false
    if [ -f "$STATE/original" ]; then
        read_original && ORIGINAL_JSON=true
    fi
    printf '{"ok":true,"version":"%s","physical":{"width":%s,"height":%s,"dpi":%s},"current":{"width":%s,"height":%s,"dpi":%s},"pending":%s,"original":%s,"active":%s,"notice":"%s"}\n' \
        "$VERSION" "$PHYSICAL_WIDTH" "$PHYSICAL_HEIGHT" "$PHYSICAL_DPI" \
        "${CURRENT_SIZE%x*}" "${CURRENT_SIZE#*x}" "$CURRENT_DPI" \
        "$PENDING_JSON" "$ORIGINAL_JSON" "$ACTIVE_JSON" "$NOTICE_TEXT"
}

# -----------------------------------------------------------------------------
# COMMAND DISPATCHER & LIFECYCLE ROUTER
# -----------------------------------------------------------------------------
rme_main() {
    COMMAND=${1:-default_action}
    [ "$#" -eq 0 ] || shift

    initialize || return 1

    case "$COMMAND" in
        guard)
            guard_loop "$1"
            return
            ;;

        default_action)
            take_lock || return 1
            if [ "$DEFAULT_PRESET" = "NATIVE" ]; then
                reset_default
                release_lock
                return 0
            fi
            detect_best_preset "$DEFAULT_PRESET" || { release_lock; return 1; }
            if [ "$DEFAULT_EXEC_MODE" = "INSTANT" ]; then
                set_pair "${TARGET_W}x${TARGET_H}" "$TARGET_D" 1 || {
                    release_lock
                    error "Instant execution rejected by SurfaceFlinger"
                    return 1
                }
                release_lock
                printf '{"ok":true,"mode":"instant","preset":"%s","applied":"%sx%s@%sdpi"}\n' \
                    "$PRESET_DESC" "$TARGET_W" "$TARGET_H" "$TARGET_D"
            else
                release_lock
                printf '{"info":"Applying %s → %sx%s @ %s DPI"}\n' \
                    "$PRESET_DESC" "$TARGET_W" "$TARGET_H" "$TARGET_D"
                take_lock || return 1
                preview "$TARGET_W" "$TARGET_H" "$TARGET_D"
                release_lock
            fi
            ;;

        auto|golden|apply-best|balanced)
            take_lock || return 1
            detect_best_preset "golden" || { release_lock; return 1; }
            printf '{"info":"Applying %s → %sx%s @ %s DPI"}\n' \
                "$PRESET_DESC" "$TARGET_W" "$TARGET_H" "$TARGET_D"
            preview "$TARGET_W" "$TARGET_H" "$TARGET_D"
            release_lock
            ;;

        performance|apply-performance)
            take_lock || return 1
            detect_best_preset "performance" || { release_lock; return 1; }
            printf '{"info":"Applying %s → %sx%s @ %s DPI"}\n' \
                "$PRESET_DESC" "$TARGET_W" "$TARGET_H" "$TARGET_D"
            preview "$TARGET_W" "$TARGET_H" "$TARGET_D"
            release_lock
            ;;

        extreme|apply-extreme)
            take_lock || return 1
            detect_best_preset "extreme" || { release_lock; return 1; }
            printf '{"info":"Applying %s → %sx%s @ %s DPI"}\n' \
                "$PRESET_DESC" "$TARGET_W" "$TARGET_H" "$TARGET_D"
            preview "$TARGET_W" "$TARGET_H" "$TARGET_D"
            release_lock
            ;;

        instant)
            take_lock || return 1
            detect_best_preset "golden" || { release_lock; return 1; }
            set_pair "${TARGET_W}x${TARGET_H}" "$TARGET_D" 1 || {
                release_lock
                error "Direct apply rejected by system"
                return 1
            }
            release_lock
            printf '{"ok":true,"mode":"instant","applied":"%sx%s@%sdpi","desc":"%s"}\n' \
                "$TARGET_W" "$TARGET_H" "$TARGET_D" "$PRESET_DESC"
            ;;

        apply)
            [ "$#" -eq 3 ] || {
                error "Usage: apply <width> <height> <dpi>"
                return 1
            }
            take_lock || return 1
            preview "$@"
            release_lock
            ;;

        confirm)
            [ "$#" -eq 1 ] || {
                error "Usage: confirm <token>"
                return 1
            }
            take_lock || return 1
            confirm_preview "$1"
            release_lock
            ;;

        revert)
            [ "$#" -eq 1 ] || {
                error "Usage: revert <token>"
                return 1
            }
            take_lock || return 1
            read_pending && [ "$1" = "$P_TOKEN" ] || {
                release_lock
                error "This preview session is no longer active"
                return 1
            }
            restore_target previous "$P_SIZE" "$P_DPI"
            release_lock
            ;;

        restore)
            take_lock || return 1
            restore_original
            release_lock
            ;;

        reset|default)
            take_lock || return 1
            reset_default
            release_lock
            ;;

        status)
            take_lock || return 1
            recover_pending && status_json
            release_lock
            ;;

        *)
            error "Invalid command. Available: auto | performance | extreme | instant | apply | confirm | revert | restore | reset | status"
            return 1
            ;;
    esac
}

rme_main "$@"
