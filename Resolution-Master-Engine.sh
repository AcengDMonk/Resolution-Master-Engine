#!/system/bin/sh
# SPDX-License-Identifier: MIT
# =============================================================================
# RESOLUTION MASTER ENGINE (RME)
# Autonomous Display Scaling & Proportional Density Subsystem for Android
#
# GitHub Repository: https://github.com/AcengDMonk/Resolution-Master-Engine
# Architecture    : POSIX Shell / Standard Android Linux Subsystem
# Privileges      : Universal Shell (UID 2000 / ADB / Shizuku / Root UID 0)
# Target Stack    : Android 11.0 - 16.0+ (AOSP & Downstream OEM Compositors)
# =============================================================================

set -u

# =============================================================================
# MODULE 00: USER CONFIGURATION & SUBSYSTEM CONSTANTS
# =============================================================================

# Default execution profile when invoked without command-line arguments
# Values: "GOLDEN" (66.7%) | "PERFORMANCE" (70.0%) | "EXTREME" (50.0%) | "NATIVE" (Reset)
DEFAULT_PRESET="GOLDEN"

# Operational execution strategy
# Values: "PREVIEW" (30s guarded transaction) | "INSTANT" (Direct un-guarded commit)
DEFAULT_EXEC_MODE="PREVIEW"

# Watchdog timeout window in seconds
PREVIEW_SECONDS=30

# Synchronize vendor-specific display databases and hardware composer framebuffers
# 1 = Enabled (Transsion XOS/HiOS hardware coupling) | 0 = Disabled (Pure AOSP only)
SYNC_VENDOR_HWC=1

ENGINE_VERSION="1.1.0"
STATE_DIR=""
ACTIVE_SCRIPT_PATH=""
NOTICE_MESSAGE=""
TRANSACTION_OUTCOME_JSON=""

# =============================================================================
# MODULE 01: SYSTEM PRIMITIVES, VALIDATORS & TELEMETRY
# =============================================================================

rme_err() {
    printf '{"ok":false,"error":"%s"}\n' "$1"
    return 1
}

is_uint() {
    case "$1" in ''|*[!0-9]*|0[0-9]*) return 1 ;; esac
    [ "${#1}" -le 8 ] && [ "$1" -ge "$2" ] && [ "$1" -le "$3" ]
}

is_uuid() {
    case "$1" in ''|*[!a-f0-9-]*) return 1 ;; esac
    [ "${#1}" -eq 36 ]
}

is_geometry_valid() {
    case "$1" in *x*) ;; *) return 1 ;; esac
    is_uint "${1%x*}" 200 16384 && is_uint "${1#*x}" 200 16384
}

get_platform_uid() {
    /system/bin/id -u 2>/dev/null || echo 2000
}

get_platform_user() {
    timeout -s KILL 2 /system/bin/am get-current-user 2>/dev/null || echo 0
}

call_wm() {
    if [ "$#" -eq 1 ]; then
        timeout -s KILL 2 /system/bin/wm "$@" 2>/dev/null
    else
        timeout -s KILL 3 /system/bin/wm "$@" 2>/dev/null
    fi
}

get_monotonic_clock() {
    read -r clock_raw _ < /proc/uptime 2>/dev/null || return 1
    clock_sec="${clock_raw%%.*}"
    is_uint "$clock_sec" 0 99999999 || return 1
    printf '%s\n' "$clock_sec"
}

get_system_boot_id() {
    read -r sys_boot_id < /proc/sys/kernel/random/boot_id 2>/dev/null || return 1
    is_uuid "$sys_boot_id" || return 1
    printf '%s\n' "$sys_boot_id"
}

generate_transaction_token() {
    read -r gen_token < /proc/sys/kernel/random/uuid 2>/dev/null || return 1
    is_uuid "$gen_token" || return 1
    printf '%s\n' "$gen_token"
}

get_process_start_tick() {
    sed 's/^.*) //' "/proc/$1/stat" 2>/dev/null | awk '{print $20}'
}

is_process_active() {
    kill -0 "$1" 2>/dev/null
}

# =============================================================================
# MODULE 02: POSIX ATOMIC CONCURRENCY ENGINE
# =============================================================================

resolve_self_binary() {
    if [ -n "$ACTIVE_SCRIPT_PATH" ] && [ -f "$ACTIVE_SCRIPT_PATH" ]; then
        return 0
    fi
    if [ -f "$0" ]; then
        case "$0" in
            /*) ACTIVE_SCRIPT_PATH="$0" ;;
            *)  ACTIVE_SCRIPT_PATH="$(pwd)/$0" ;;
        esac
    fi
    if [ -z "$ACTIVE_SCRIPT_PATH" ] || [ ! -f "$ACTIVE_SCRIPT_PATH" ]; then
        for path_candidate in \
            "/data/local/tmp/Resolution-Master-Engine.sh" \
            "/data/local/tmp/RME.sh" \
            "/sdcard/Resolution-Master-Engine.sh" \
            "/sdcard/RME.sh"; do
            if [ -f "$path_candidate" ]; then
                ACTIVE_SCRIPT_PATH="$path_candidate"
                break
            fi
        done
    fi
    [ -f "$ACTIVE_SCRIPT_PATH" ] || ACTIVE_SCRIPT_PATH="/data/local/tmp/Resolution-Master-Engine.sh"
}

initialize_runtime() {
    caller_uid=$(get_platform_uid)
    [ "$caller_uid" = "2000" ] || [ "$caller_uid" = "0" ] || {
        rme_err "Privilege check failed. Execute via ADB Shell (UID 2000), Shizuku, or Root."
        return 1
    }

    umask 077

    # Establish canonical state directory with unprivileged write guarantee
    if [ -n "${MODDIR:-}" ] && [ -d "${MODDIR%/*/*}" ]; then
        STATE_DIR="${MODDIR%/*/*}/var/raresolution"
    else
        STATE_DIR="/data/local/tmp/raresolution"
    fi

    [ ! -L "${STATE_DIR%/*}" ] && [ ! -L "$STATE_DIR" ] || {
        rme_err "Security violation: Insecure symlink detected in state hierarchy."
        return 1
    }

    mkdir -p "$STATE_DIR" 2>/dev/null || {
        rme_err "VFS error: Unable to create runtime directory in $STATE_DIR."
        return 1
    }

    for state_leaf in pending original owned recovery outcome last; do
        [ ! -L "$STATE_DIR/$state_leaf" ] || {
            rme_err "Security violation: Symbolic link node detected in $state_leaf."
            return 1
        }
    done

    BOOT_SESSION_ID=$(get_system_boot_id) || {
        rme_err "Subsystem fault: Failed to read kernel boot sequence identity."
        return 1
    }
}

acquire_atomic_lock() {
    atomic_lock_node="$STATE_DIR/lock.d"
    lock_cycle=0

    while ! mkdir "$atomic_lock_node" 2>/dev/null; do
        lock_cycle=$((lock_cycle + 1))
        if [ "$lock_cycle" -ge 40 ]; then
            # Evaluate active stale PID locks
            if [ -f "$atomic_lock_node/pid" ]; then
                read -r current_lock_pid < "$atomic_lock_node/pid" 2>/dev/null
                if [ -n "$current_lock_pid" ] && ! is_process_active "$current_lock_pid"; then
                    rm -rf "$atomic_lock_node" 2>/dev/null
                    continue
                fi
            else
                rm -rf "$atomic_lock_node" 2>/dev/null
                continue
            fi
            rme_err "Display pipeline busy: Contention on active transaction lock."
            return 1
        fi
        sleep 0.1
    done
    echo "$$" > "$atomic_lock_node/pid" 2>/dev/null
}

release_atomic_lock() {
    rm -rf "$STATE_DIR/lock.d" 2>/dev/null
}

# =============================================================================
# MODULE 03: DISPLAY HARDWARE ABSTRACTION & GEOMETRIC ENGINE
# =============================================================================

query_display_pipeline() {
    [ "$(get_platform_user)" = 0 ] || return 1
    size_dump=$(call_wm size) || return 1
    density_dump=$(call_wm density) || return 1

    PHYS_GEOMETRY=$(printf '%s\n' "$size_dump" | sed -n 's/^Physical size: *\([0-9][0-9]*x[0-9][0-9]*\)\r*$/\1/p')
    OVERRIDE_GEOMETRY=$(printf '%s\n' "$size_dump" | sed -n 's/^Override size: *\([0-9][0-9]*x[0-9][0-9]*\)\r*$/\1/p')
    PHYS_DENSITY=$(printf '%s\n' "$density_dump" | sed -n 's/^Physical density: *\([0-9][0-9]*\)\r*$/\1/p')
    OVERRIDE_DENSITY=$(printf '%s\n' "$density_dump" | sed -n 's/^Override density: *\([0-9][0-9]*\)\r*$/\1/p')

    is_geometry_valid "$PHYS_GEOMETRY" && is_uint "$PHYS_DENSITY" 72 2000 || return 1
    [ -z "$OVERRIDE_GEOMETRY" ] || is_geometry_valid "$OVERRIDE_GEOMETRY" || return 1
    [ -z "$OVERRIDE_DENSITY" ] || is_uint "$OVERRIDE_DENSITY" 72 2000 || return 1

    CURRENT_GEOMETRY=${OVERRIDE_GEOMETRY:-$PHYS_GEOMETRY}
    CURRENT_DENSITY=${OVERRIDE_DENSITY:-$PHYS_DENSITY}
    PHYS_WIDTH=${PHYS_GEOMETRY%x*}
    PHYS_HEIGHT=${PHYS_GEOMETRY#*x}
}

query_runtime_metrics() {
    am_config_dump=$(timeout -s KILL 2 /system/bin/am get-config 2>/dev/null) || return 1
    parsed_metrics=$(printf '%s\n' "$am_config_dump" | awk '
        /^config: / {
            cnt = split($2, chunks, "-")
            for (idx = 1; idx <= cnt; idx++) {
                chk = chunks[idx]
                if (chk ~ /^sw[0-9]+dp$/) { sub(/^sw/, "", chk); sub(/dp$/, "", chk); sw_val = chk }
                else if (chk ~ /^w[0-9]+dp$/) { sub(/^w/, "", chk); sub(/dp$/, "", chk); w_val = chk }
                else if (chk ~ /^h[0-9]+dp$/) { sub(/^h/, "", chk); sub(/dp$/, "", chk); h_val = chk }
                else if (chk ~ /^[0-9]+dpi$/) { sub(/dpi$/, "", chk); d_val = chk }
                else if (chk == "ldpi") d_val = 120
                else if (chk == "mdpi") d_val = 160
                else if (chk == "tvdpi") d_val = 213
                else if (chk == "hdpi") d_val = 240
                else if (chk == "xhdpi") d_val = 320
                else if (chk == "xxhdpi") d_val = 480
                else if (chk == "xxxhdpi") d_val = 640
            }
            if (d_val && w_val && h_val && sw_val) printf "%s %s %s %s\n", d_val, w_val, h_val, sw_val
            exit
        }')

    read -r RUNTIME_DPI RUNTIME_WIDTH RUNTIME_HEIGHT RUNTIME_SW <<EOF
$parsed_metrics
EOF
    is_uint "$RUNTIME_DPI" 72 2000 && is_uint "$RUNTIME_WIDTH" 1 65535 &&
        is_uint "$RUNTIME_HEIGHT" 1 65535 && is_uint "$RUNTIME_SW" 1 65535
}

compute_euclidean_dpi() {
    awk -v w="$1" -v h="$2" -v nw="$PHYS_WIDTH" -v nh="$PHYS_HEIGHT" -v d="$PHYS_DENSITY" \
        'BEGIN { printf "%d", d * sqrt(w*w + h*h) / sqrt(nw*nw + nh*nh) + 0.5 }'
}

compute_aspect_ratio() {
    aspect_calc=$(awk -v h="$PHYS_HEIGHT" -v w="$PHYS_WIDTH" 'BEGIN { printf "%.6f", h / w }' 2>/dev/null)
    if [ -z "$aspect_calc" ] || [ "$aspect_calc" = "0.000000" ]; then
        int_part=$(( PHYS_HEIGHT / PHYS_WIDTH ))
        frac_part=$(( (PHYS_HEIGHT % PHYS_WIDTH) * 1000000 / PHYS_WIDTH ))
        frac_len=${#frac_part}
        while [ "$frac_len" -lt 6 ]; do
            frac_part="0$frac_part"
            frac_len=${#frac_part}
        done
        aspect_calc="${int_part}.${frac_part}"
    fi
    printf '%s\n' "$aspect_calc"
}

# =============================================================================
# MODULE 04: WINDOW MANAGER & HARDWARE COMPOSER EXTENSIONS
# =============================================================================

apply_window_manager_invariants() {
    ratio_metric=$(compute_aspect_ratio)

    # 1. Enforce geometric letterbox boundary rules
    cmd window set-letterbox-style --aspectRatio "$ratio_metric" >/dev/null 2>&1
    cmd window set-letterbox-style --minAspectRatioForUnresizable "$ratio_metric" >/dev/null 2>&1
    cmd window set-letterbox-style --horizontalPositionMultiplier 0.5 >/dev/null 2>&1
    cmd window set-letterbox-style --verticalPositionMultiplier 0.5 >/dev/null 2>&1

    # 2. Lock orientation request compliance
    call_wm set-ignore-orientation-request false >/dev/null 2>&1

    # 3. Bypass compositor scaling blits (Force native coordinate mapping)
    call_wm scaling off >/dev/null 2>&1
    cmd window scaling off >/dev/null 2>&1
}

synchronize_vendor_hwc() {
    [ "$SYNC_VENDOR_HWC" = "1" ] || return 0
    device_brand=$(getprop ro.product.brand 2>/dev/null | tr '[:upper:]' '[:lower:]')

    case "$device_brand" in
        *infinix*|*tecno*|*itel*|*transsion*)
            if [ "$1" = "reset" ]; then
                settings put system tran_resolution_size_0 "$PHYS_GEOMETRY" >/dev/null 2>&1
                settings put system tran_resolution_size_1 "$PHYS_GEOMETRY" >/dev/null 2>&1
                settings put system tran_resolution_default "$PHYS_GEOMETRY" >/dev/null 2>&1
                setprop debug.hwc.fbsize "$PHYS_GEOMETRY" 2>/dev/null
            else
                settings put system tran_resolution_size_0 "$1" >/dev/null 2>&1
                settings put system tran_resolution_size_1 "$1" >/dev/null 2>&1
                settings put system tran_resolution_default "$1" >/dev/null 2>&1
                setprop debug.hwc.fbsize "$1" 2>/dev/null
            fi
            ;;
    esac
}

commit_display_pair() {
    target_pair_size="$1"
    target_pair_dpi="$2"

    [ "$target_pair_size" = "reset" ] || is_geometry_valid "$target_pair_size" || return 1
    [ "$target_pair_dpi" = "reset" ] || is_uint "$target_pair_dpi" 72 2000 || return 1

    [ "$(get_platform_user)" = 0 ] || return 1
    call_wm size "$target_pair_size" >/dev/null || return 1
    [ "$(get_platform_user)" = 0 ] || return 1
    call_wm density "$target_pair_dpi" >/dev/null || return 1

    # Apply boundary rules and OEM hardware composer synchronization
    apply_window_manager_invariants
    synchronize_vendor_hwc "$target_pair_size"

    verify_display_pair "$target_pair_size" "$target_pair_dpi" "${3:-2}"
}

verify_display_pair() {
    expected_geom="$1"
    expected_density="$2"
    verify_tolerance=${3:-2}
    poll_iteration=0
    poll_stable_count=0

    until [ "$poll_iteration" -ge 4 ]; do
        poll_iteration=$((poll_iteration + 1))
        if query_display_pipeline; then
            check_geom="$expected_geom"
            check_density="$expected_density"
            [ "$check_geom" != "reset" ] || check_geom="$PHYS_GEOMETRY"
            [ "$check_density" != "reset" ] || check_density="$PHYS_DENSITY"

            if [ "$CURRENT_GEOMETRY" = "$check_geom" ] && [ "$CURRENT_DENSITY" = "$check_density" ]; then
                metric_match=1
                [ "$expected_geom" != "reset" ] || [ -z "$OVERRIDE_GEOMETRY" ] || metric_match=0
                [ "$expected_density" != "reset" ] || [ -z "$OVERRIDE_DENSITY" ] || metric_match=0

                if query_runtime_metrics; then
                    [ "$RUNTIME_DPI" = "$check_density" ] || metric_match=0
                elif [ "$verify_tolerance" = 1 ]; then
                    metric_match=0
                fi

                if [ "$metric_match" = 1 ]; then
                    poll_stable_count=$((poll_stable_count + 1))
                    [ "$poll_stable_count" -lt 2 ] || return 0
                else
                    poll_stable_count=0
                fi
            else
                poll_stable_count=0
            fi
        else
            return 1
        fi
        [ "$poll_iteration" -ge 4 ] || sleep 0.25
    done
    return 1
}

# =============================================================================
# MODULE 05: TRANSACTION RECORDS & PERSISTENCE
# =============================================================================

persist_state_record() {
    record_key="$1"
    shift
    case "$record_key" in pending|original|owned|recovery|outcome|last) ;; *) return 1 ;; esac
    atomic_tmp="$STATE_DIR/$record_key.$$"
    [ ! -L "$atomic_tmp" ] || return 1
    if { printf '%s\n' "$*" > "$atomic_tmp" && mv -f "$atomic_tmp" "$STATE_DIR/$record_key"; } 2>/dev/null; then
        return 0
    fi
    rm -f "$atomic_tmp" 2>/dev/null
    return 1
}

read_original_record() {
    [ -f "$STATE_DIR/original" ] || return 1
    read -r orig_sz orig_dpi orig_extra < "$STATE_DIR/original" || return 2
    [ -z "$orig_extra" ] || return 2
    [ "$orig_sz" = "reset" ] || is_geometry_valid "$orig_sz" || return 2
    [ "$orig_dpi" = "reset" ] || is_uint "$orig_dpi" 72 2000 || return 2
    ORIGINAL_SIZE="$orig_sz"
    ORIGINAL_DPI="$orig_dpi"
}

read_pending_record() {
    [ -f "$STATE_DIR/pending" ] || return 1
    read -r p_tok p_boot p_deadline p_prev_sz p_prev_dpi p_tgt_sz p_tgt_dpi p_extra < "$STATE_DIR/pending" || return 2
    [ -z "$p_extra" ] && is_uuid "$p_tok" && is_uuid "$p_boot" &&
        is_uint "$p_deadline" 0 99999999 && is_geometry_valid "$p_tgt_sz" && is_uint "$p_tgt_dpi" 72 2000 || return 2
    PENDING_TOKEN="$p_tok"
    PENDING_BOOT="$p_boot"
    PENDING_DEADLINE="$p_deadline"
    PENDING_PREV_SIZE="$p_prev_sz"
    PENDING_PREV_DPI="$p_prev_dpi"
    PENDING_TARGET_SIZE="$p_tgt_sz"
    PENDING_TARGET_DPI="$p_tgt_dpi"
}

read_recovery_record() {
    [ -f "$STATE_DIR/recovery" ] || return 1
    read -r r_tok r_boot r_kind r_sz r_dpi r_extra < "$STATE_DIR/recovery" || return 2
    [ -z "$r_extra" ] && is_uuid "$r_tok" && is_uuid "$r_boot" || return 2
    case "$r_kind" in previous|original|default) ;; *) return 2 ;; esac
    RECOVERY_TOKEN="$r_tok"
    RECOVERY_BOOT="$r_boot"
    RECOVERY_KIND="$r_kind"
    RECOVERY_SIZE="$r_sz"
    RECOVERY_DPI="$r_dpi"
}

# =============================================================================
# MODULE 06: ASYNCHRONOUS SAFETY WATCHDOG DAEMON
# =============================================================================

is_guard_daemon_running() {
    query_token="${1:-$PENDING_TOKEN}"
    guard_ready_node="$STATE_DIR/ready.$query_token"
    [ -f "$guard_ready_node" ] && [ ! -L "$guard_ready_node" ] || return 1

    read -r daemon_pid daemon_boot daemon_start _ < "$guard_ready_node" 2>/dev/null || return 1
    is_uint "$daemon_pid" 1 99999999 && [ "$daemon_boot" = "$BOOT_SESSION_ID" ] || return 1

    actual_start_tick=$(get_process_start_tick "$daemon_pid")
    [ -n "$actual_start_tick" ] && [ "$actual_start_tick" = "$daemon_start" ] && is_process_active "$daemon_pid"
}

spawn_guard_daemon() {
    resolve_self_binary
    shell_interpreter="${BB:-/system/bin/sh}"
    nohup "$shell_interpreter" "$ACTIVE_SCRIPT_PATH" guard "$1" </dev/null >/dev/null 2>&1 &
}

ensure_guard_daemon() {
    target_token="$1"
    is_guard_daemon_running "$target_token" && return 0
    spawn_guard_daemon "$target_token"

    guard_retry=0
    until is_guard_daemon_running "$target_token"; do
        guard_retry=$((guard_retry + 1))
        [ "$guard_retry" -lt 30 ] || return 1
        sleep 0.1
    done
}

watchdog_daemon_loop() {
    active_token="$1"
    is_uuid "$active_token" || return 1

    if read_recovery_record; then
        [ "$RECOVERY_TOKEN" = "$active_token" ] || return 1
    else
        read_pending_record && [ "$PENDING_TOKEN" = "$active_token" ] || return 1
    fi

    self_tick=$(get_process_start_tick "$$")
    case "$self_tick" in ''|*[!0-9]*) return 1 ;; esac

    guard_ready_node="$STATE_DIR/ready.$active_token"
    [ ! -L "$guard_ready_node" ] || return 1
    printf '%s %s %s\n' "$$" "$BOOT_SESSION_ID" "$self_tick" > "$guard_ready_node" || return 1

    trap 'rm -f "$STATE_DIR/ready.$active_token"' EXIT
    trap '' HUP

    loop_delay=1
    while [ -f "$STATE_DIR/pending" ] || [ -f "$STATE_DIR/recovery" ]; do
        acquire_atomic_lock || return 1
        if [ -f "$STATE_DIR/recovery" ]; then
            if ! read_recovery_record || [ "$RECOVERY_TOKEN" != "$active_token" ]; then
                release_atomic_lock
                return 0
            fi
            execute_recovery_action && { release_atomic_lock; return 0; }
            loop_delay=5
        elif ! read_pending_record || [ "$PENDING_TOKEN" != "$active_token" ]; then
            release_atomic_lock
            return 0
        else
            current_clock=$(get_monotonic_clock) || current_clock=$PENDING_DEADLINE
            if [ "$BOOT_SESSION_ID" != "$PENDING_BOOT" ] || [ "$current_clock" -ge "$PENDING_DEADLINE" ]; then
                trigger_rollback && { release_atomic_lock; return 0; }
                loop_delay=5
            fi
        fi
        release_atomic_lock
        sleep "$loop_delay"
    done
}

trigger_rollback() {
    if [ ! -f "$STATE_DIR/recovery" ]; then
        read_pending_record || return 1
        persist_state_record recovery "$PENDING_TOKEN" "$BOOT_SESSION_ID" previous "$PENDING_PREV_SIZE" "$PENDING_PREV_DPI" || return 1
    fi
    execute_recovery_action
}

execute_recovery_action() {
    read_recovery_record || return 1
    commit_display_pair "$RECOVERY_SIZE" "$RECOVERY_DPI" || return 1
    rm -f "$STATE_DIR/pending" || return 1

    case "$RECOVERY_KIND" in
        original|default)
            rm -f "$STATE_DIR/original" "$STATE_DIR/owned" || return 1
            record_transaction_outcome "$RECOVERY_KIND" || rm -f "$STATE_DIR/outcome"
            ;;
        previous)
            record_transaction_outcome reverted || rm -f "$STATE_DIR/outcome"
            ;;
    esac
    rm -f "$STATE_DIR/recovery"
}

recover_stale_transactions() {
    if [ -f "$STATE_DIR/recovery" ]; then
        read_recovery_record || {
            rme_err "State corrupted: Manual recovery required via 'reset'."
            return 1
        }
        if ! execute_recovery_action; then
            ensure_guard_daemon "$RECOVERY_TOKEN" >/dev/null 2>&1
            rme_err "Recovery operation in progress. Please wait."
            return 1
        fi
    fi

    [ -f "$STATE_DIR/pending" ] || return 0
    read_pending_record || {
        rme_err "State corrupted: Manual recovery required via 'reset'."
        return 1
    }

    current_clock=$(get_monotonic_clock) || return 1
    if [ "$BOOT_SESSION_ID" != "$PENDING_BOOT" ] || [ "$current_clock" -ge "$PENDING_DEADLINE" ] || ! is_guard_daemon_running; then
        if ! trigger_rollback; then
            read_recovery_record && ensure_guard_daemon "$RECOVERY_TOKEN" >/dev/null 2>&1
            rme_err "Watchdog fault: Automatic rollback failed. Issuing factory reset."
            return 1
        fi
    fi
}

record_transaction_outcome() {
    outcome_mode="$1"
    case "$outcome_mode" in preview|kept|reverted|original|default) ;; *) return 1 ;; esac
    TRANSACTION_OUTCOME_JSON=$(printf '{"kind":"%s","width":%s,"height":%s,"dpi":%s}' \
        "$outcome_mode" "${CURRENT_GEOMETRY%x*}" "${CURRENT_GEOMETRY#*x}" "$CURRENT_DENSITY")
    if clock_metric=$(get_monotonic_clock) && persist_state_record outcome "$BOOT_SESSION_ID" "$clock_metric" "$outcome_mode" "$CURRENT_GEOMETRY" "$CURRENT_DENSITY"; then
        return 0
    fi
    rm -f "$STATE_DIR/outcome"
    return 1
}

# =============================================================================
# MODULE 07: MATHEMATICAL RESOLUTION & PRESET ENGINE
# =============================================================================

resolve_optimal_geometry() {
    query_display_pipeline || return 1
    selected_tier=${1:-$DEFAULT_PRESET}

    case "$selected_tier" in
        [gG][oO][lL][dD][eE][nN]|[bB][aA][lL][aA][nN][cC][eE][dD]|auto) profile_key="golden" ;;
        [pP][eE][rR][fF][oO][rR][mM][aA][nN][cC][eE])                 profile_key="performance" ;;
        [eE][xX][tT][rR][eE][mM][eE])                                 profile_key="extreme" ;;
        [nN][aA][tT][iI][vV][eE]|reset|default)                       profile_key="native" ;;
        *)                                                             profile_key="golden" ;;
    esac

    # 1. Deterministic Calibration Profile: 1080x2436 Geometry
    if [ "$PHYS_WIDTH" -eq 1080 ] && [ "$PHYS_HEIGHT" -eq 2436 ]; then
        case "$profile_key" in
            extreme)
                CALCULATED_W=540
                CALCULATED_H=1218
                CALCULATED_DPI=220
                CALCULATED_DESC="Calibrated 1080x2436 Extreme (540p / -75.0% Pixel Load)"
                ;;
            performance)
                CALCULATED_W=756
                CALCULATED_H=1705
                CALCULATED_DPI=308
                CALCULATED_DESC="Calibrated 1080x2436 Performance (70.0% Metric Scale)"
                ;;
            golden|*)
                CALCULATED_W=720
                CALCULATED_H=1624
                CALCULATED_DPI=293
                CALCULATED_DESC="Calibrated 1080x2436 Golden Baseline (720p / -55.6% Pixel Load)"
                ;;
        esac
        return 0
    fi

    # 2. Universal Mathematical Scaler (Arbitrary Display Panels)
    case "$profile_key" in
        extreme)
            # 50.0% Macroblock-aligned downscale factor
            CALCULATED_W=$(( (PHYS_WIDTH / 2 / 2) * 2 ))
            CALCULATED_H=$(( (PHYS_HEIGHT / 2 / 2) * 2 ))
            CALCULATED_DESC="Universal Extreme Tier (50.0% Macroblock Aligned)"
            ;;
        performance)
            # 70.0% Scaling Factor
            CALCULATED_W=$(( (PHYS_WIDTH * 70 / 100 / 2) * 2 ))
            CALCULATED_H=$(( ((CALCULATED_W * PHYS_HEIGHT / PHYS_WIDTH) / 2) * 2 ))
            CALCULATED_DESC="Universal Performance Tier (70.0% Aligned)"
            ;;
        golden|*)
            # 66.67% Optimal Fill-Rate Reduction (Standard 720p Class)
            CALCULATED_W=$(( (PHYS_WIDTH * 2 / 3 / 2) * 2 ))
            CALCULATED_H=$(( ((CALCULATED_W * PHYS_HEIGHT / PHYS_WIDTH) / 2) * 2 ))
            CALCULATED_DESC="Universal Golden Baseline (66.7% Balanced Fill-Rate)"
            ;;
    esac

    CALCULATED_DPI=$(compute_euclidean_dpi "$CALCULATED_W" "$CALCULATED_H")
}

# =============================================================================
# MODULE 08: USER TRANSACTIONS & DISPATCHER
# =============================================================================

rme_execute_preview() {
    [ "$#" -eq 3 ] || {
        rme_err "Parameter fault: Expected <width> <height> <dpi>."
        return 1
    }
    target_w="$1"
    target_h="$2"
    target_dpi="$3"

    is_uint "$target_w" 200 8192 && is_uint "$target_h" 200 8192 && is_uint "$target_dpi" 72 1000 || {
        rme_err "Out of bounds: Requested geometry or density exceeds platform constraints."
        return 1
    }

    recover_stale_transactions || return 1
    [ ! -f "$STATE_DIR/pending" ] || {
        rme_err "Transaction conflict: An unconfirmed preview session is currently armed."
        return 1
    }

    if [ -f "$STATE_DIR/original" ]; then
        read_original_record || {
            rme_err "State corrupted: Original display baseline unreadable. Issue 'reset'."
            return 1
        }
    fi

    query_display_pipeline || {
        rme_err "HAL fault: Unable to inspect primary display metrics."
        return 1
    }
    query_runtime_metrics || {
        rme_err "Framework fault: WindowManager runtime metrics query failed."
        return 1
    }

    [ "$target_w" -le "$PHYS_WIDTH" ] && [ "$target_h" -le "$PHYS_HEIGHT" ] || {
        rme_err "Geometric violation: Target dimensions exceed physical viewport limits."
        return 1
    }

    min_allowed_w=$(( (PHYS_WIDTH * 30 + 50) / 100 ))
    min_allowed_h=$(( (PHYS_HEIGHT * 30 + 50) / 100 ))
    [ "$target_w" -ge "$min_allowed_w" ] && [ "$target_h" -ge "$min_allowed_h" ] || {
        rme_err "Threshold violation: Scaling lower than 30% of physical viewport is rejected."
        return 1
    }

    # Strict aspect-ratio invariance check
    ratio_delta=$(( target_w * PHYS_HEIGHT - target_h * PHYS_WIDTH ))
    [ "$ratio_delta" -ge 0 ] || ratio_delta=$(( -ratio_delta ))
    [ "$ratio_delta" -le $(( (PHYS_WIDTH + PHYS_HEIGHT + 1) / 2 )) ] || {
        rme_err "Geometry error: Specified parameters violate native aspect-ratio invariance."
        return 1
    }

    # Strict proportional density check
    expected_matched_dpi=$(compute_euclidean_dpi "$target_w" "$target_h")
    [ "$target_dpi" = "$expected_matched_dpi" ] || {
        rme_err "Density error: DPI mismatch with Euclidean metric (Expected: $expected_matched_dpi)."
        return 1
    }

    [ "$CURRENT_GEOMETRY" != "${target_w}x${target_h}" ] || [ "$CURRENT_DENSITY" != "$target_dpi" ] || {
        emit_status_json
        return
    }

    prev_size_record=${OVERRIDE_GEOMETRY:-reset}
    prev_dpi_record=${OVERRIDE_DENSITY:-reset}
    if [ ! -f "$STATE_DIR/original" ]; then
        persist_state_record original "$prev_size_record" "$prev_dpi_record" || {
            rme_err "IO error: Failed to serialize original display baseline."
            return 1
        }
    fi

    session_token=$(generate_transaction_token) || return 1
    session_clock=$(get_monotonic_clock) || return 1
    session_deadline=$(( session_clock + 90 ))

    persist_state_record pending "$session_token" "$BOOT_SESSION_ID" "$session_deadline" \
        "$prev_size_record" "$prev_dpi_record" "${target_w}x${target_h}" "$target_dpi" || {
        rme_err "IO error: Failed to serialize transaction record."
        return 1
    }

    if ! ensure_guard_daemon "$session_token"; then
        rm -f "$STATE_DIR/pending"
        rme_err "Watchdog fault: Failed to spawn background guard daemon. Aborting."
        return 1
    fi

    if ! commit_display_pair "${target_w}x${target_h}" "$target_dpi" 1; then
        trigger_rollback
        rme_err "Hardware reject: Compositor rejected viewport adjustment. Rolled back."
        return 1
    fi

    session_clock=$(get_monotonic_clock) || return 1
    session_deadline=$(( session_clock + PREVIEW_SECONDS ))
    persist_state_record pending "$session_token" "$BOOT_SESSION_ID" "$session_deadline" \
        "$prev_size_record" "$prev_dpi_record" "${target_w}x${target_h}" "$target_dpi" || {
        trigger_rollback
        rme_err "IO error: Failed to update watchdog deadline timer."
        return 1
    }

    record_transaction_outcome preview
    emit_status_json
}

rme_execute_confirm() {
    [ ! -f "$STATE_DIR/recovery" ] || {
        rme_err "State conflict: Recovery operation is currently executing."
        return 1
    }
    is_uuid "$1" || {
        rme_err "Parameter fault: Invalid confirmation token structure."
        return 1
    }
    read_pending_record && [ "$1" = "$PENDING_TOKEN" ] || {
        rme_err "Session expired: Confirmation token rejected or preview expired."
        return 1
    }
    current_clock=$(get_monotonic_clock) || return 1
    if [ "$BOOT_SESSION_ID" != "$PENDING_BOOT" ] || [ "$current_clock" -ge "$PENDING_DEADLINE" ] || ! is_guard_daemon_running; then
        trigger_rollback
        rme_err "Transaction expired: Window closed before confirmation. Reverted."
        return 1
    fi
    verify_display_pair "$PENDING_TARGET_SIZE" "$PENDING_TARGET_DPI" 1 || {
        rme_err "State conflict: Viewport modified externally during preview. Aborted."
        return 1
    }

    persist_state_record owned "$PENDING_TARGET_SIZE" "$PENDING_TARGET_DPI" || {
        rme_err "IO error: Failed to persist owned state lock."
        return 1
    }
    rm -f "$STATE_DIR/pending" || return 1
    record_transaction_outcome kept
    persist_state_record last "$PENDING_TARGET_SIZE" "$PENDING_TARGET_DPI" "$PHYS_GEOMETRY" "$PHYS_DENSITY"
    emit_status_json
}

rme_execute_restore() {
    target_kind="$1"
    target_sz="$2"
    target_dpi="$3"
    op_token=$(generate_transaction_token) || return 1

    persist_state_record recovery "$op_token" "$BOOT_SESSION_ID" "$target_kind" "$target_sz" "$target_dpi" || return 1
    ensure_guard_daemon "$op_token" >/dev/null 2>&1
    execute_recovery_action || {
        rme_err "Pipeline fault: Display recovery sequence failed."
        return 1
    }
    emit_status_json
}

rme_restore_original() {
    if [ -f "$STATE_DIR/original" ]; then
        read_original_record || {
            rme_err "State corrupted: Baseline record damaged. Executing 'reset'."
            return 1
        }
        rme_execute_restore original "$ORIGINAL_SIZE" "$ORIGINAL_DPI"
        return
    fi
    recover_stale_transactions || return 1
    emit_status_json
}

emit_status_json() {
    query_display_pipeline || {
        rme_err "HAL fault: Unable to read display parameters."
        return 1
    }
    runtime_json=null
    if query_runtime_metrics; then
        runtime_json=$(printf '{"dpi":%s,"widthDp":%s,"heightDp":%s,"smallestWidthDp":%s}' \
            "$RUNTIME_DPI" "$RUNTIME_WIDTH" "$RUNTIME_HEIGHT" "$RUNTIME_SW")
    fi
    pending_json=null
    if read_pending_record; then
        now_clock=$(get_monotonic_clock) || return 1
        rem_sec=$(( PENDING_DEADLINE - now_clock ))
        [ "$rem_sec" -ge 0 ] || rem_sec=0
        pending_json=$(printf '{"token":"%s","seconds":%s,"width":%s,"height":%s,"dpi":%s}' \
            "$PENDING_TOKEN" "$rem_sec" "${PENDING_TARGET_SIZE%x*}" "${PENDING_TARGET_SIZE#*x}" "$PENDING_TARGET_DPI")
    fi
    original_state=false
    if [ -f "$STATE_DIR/original" ]; then
        read_original_record && original_state=true
    fi

    printf '{"ok":true,"version":"%s","physical":{"width":%s,"height":%s,"dpi":%s},"current":{"width":%s,"height":%s,"dpi":%s},"pending":%s,"original":%s,"active":%s,"notice":"%s"}\n' \
        "$ENGINE_VERSION" "$PHYS_WIDTH" "$PHYS_HEIGHT" "$PHYS_DENSITY" \
        "${CURRENT_GEOMETRY%x*}" "${CURRENT_GEOMETRY#*x}" "$CURRENT_DENSITY" \
        "$pending_json" "$original_state" "$runtime_json" "$NOTICE_MESSAGE"
}

# =============================================================================
# MODULE 09: DISPATCHER GATEWAY
# =============================================================================

rme_main() {
    cmd_directive=${1:-default_action}
    [ "$#" -eq 0 ] || shift

    initialize_runtime || return 1

    case "$cmd_directive" in
        guard)
            watchdog_daemon_loop "$1"
            return
            ;;

        default_action)
            acquire_atomic_lock || return 1
            if [ "$DEFAULT_PRESET" = "NATIVE" ]; then
                rme_execute_restore default reset reset
                release_atomic_lock
                return 0
            fi
            resolve_optimal_geometry "$DEFAULT_PRESET" || { release_atomic_lock; return 1; }
            if [ "$DEFAULT_EXEC_MODE" = "INSTANT" ]; then
                commit_display_pair "${CALCULATED_W}x${CALCULATED_H}" "$CALCULATED_DPI" 1 || {
                    release_atomic_lock
                    rme_err "Hardware reject: Direct commit failed."
                    return 1
                }
                release_atomic_lock
                printf '{"ok":true,"mode":"instant","profile":"%s","geometry":"%sx%s@%sdpi"}\n' \
                    "$CALCULATED_DESC" "$CALCULATED_W" "$CALCULATED_H" "$CALCULATED_DPI"
            else
                release_atomic_lock
                printf '{"info":"Arming %s -> %sx%s @ %s DPI"}\n' \
                    "$CALCULATED_DESC" "$CALCULATED_W" "$CALCULATED_H" "$CALCULATED_DPI"
                acquire_atomic_lock || return 1
                rme_execute_preview "$CALCULATED_W" "$CALCULATED_H" "$CALCULATED_DPI"
                release_atomic_lock
            fi
            ;;

        auto|golden|balanced|apply-best)
            acquire_atomic_lock || return 1
            resolve_optimal_geometry "golden" || { release_atomic_lock; return 1; }
            printf '{"info":"Arming %s -> %sx%s @ %s DPI"}\n' \
                "$CALCULATED_DESC" "$CALCULATED_W" "$CALCULATED_H" "$CALCULATED_DPI"
            rme_execute_preview "$CALCULATED_W" "$CALCULATED_H" "$CALCULATED_DPI"
            release_atomic_lock
            ;;

        performance|apply-performance)
            acquire_atomic_lock || return 1
            resolve_optimal_geometry "performance" || { release_atomic_lock; return 1; }
            printf '{"info":"Arming %s -> %sx%s @ %s DPI"}\n' \
                "$CALCULATED_DESC" "$CALCULATED_W" "$CALCULATED_H" "$CALCULATED_DPI"
            rme_execute_preview "$CALCULATED_W" "$CALCULATED_H" "$CALCULATED_DPI"
            release_atomic_lock
            ;;

        extreme|apply-extreme)
            acquire_atomic_lock || return 1
            resolve_optimal_geometry "extreme" || { release_atomic_lock; return 1; }
            printf '{"info":"Arming %s -> %sx%s @ %s DPI"}\n' \
                "$CALCULATED_DESC" "$CALCULATED_W" "$CALCULATED_H" "$CALCULATED_DPI"
            rme_execute_preview "$CALCULATED_W" "$CALCULATED_H" "$CALCULATED_DPI"
            release_atomic_lock
            ;;

        instant)
            acquire_atomic_lock || return 1
            resolve_optimal_geometry "golden" || { release_atomic_lock; return 1; }
            commit_display_pair "${CALCULATED_W}x${CALCULATED_H}" "$CALCULATED_DPI" 1 || {
                release_atomic_lock
                rme_err "Hardware reject: Direct commit rejected by compositor."
                return 1
            }
            release_atomic_lock
            printf '{"ok":true,"mode":"instant","profile":"%s","geometry":"%sx%s@%sdpi"}\n' \
                "$CALCULATED_DESC" "$CALCULATED_W" "$CALCULATED_H" "$CALCULATED_DPI"
            ;;

        apply)
            [ "$#" -eq 3 ] || {
                rme_err "Syntax error: Usage 'apply <width> <height> <dpi>'."
                return 1
            }
            acquire_atomic_lock || return 1
            rme_execute_preview "$@"
            release_atomic_lock
            ;;

        confirm)
            [ "$#" -eq 1 ] || {
                rme_err "Syntax error: Usage 'confirm <token>'."
                return 1
            }
            acquire_atomic_lock || return 1
            rme_execute_confirm "$1"
            release_atomic_lock
            ;;

        revert)
            [ "$#" -eq 1 ] || {
                rme_err "Syntax error: Usage 'revert <token>'."
                return 1
            }
            acquire_atomic_lock || return 1
            read_pending_record && [ "$1" = "$PENDING_TOKEN" ] || {
                release_atomic_lock
                rme_err "Session expired: Preview record no longer active."
                return 1
            }
            rme_execute_restore previous "$PENDING_PREV_SIZE" "$PENDING_PREV_DPI"
            release_atomic_lock
            ;;

        restore)
            acquire_atomic_lock || return 1
            rme_restore_original
            release_atomic_lock
            ;;

        reset|default)
            acquire_atomic_lock || return 1
            rme_execute_restore default reset reset
            release_atomic_lock
            ;;

        status)
            acquire_atomic_lock || return 1
            recover_stale_transactions && emit_status_json
            release_atomic_lock
            ;;

        *)
            rme_err "Invalid directive. Available: auto | performance | extreme | instant | apply | confirm | revert | restore | reset | status"
            return 1
            ;;
    esac
}

rme_main "$@"
