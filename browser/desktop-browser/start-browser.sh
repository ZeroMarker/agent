#!/usr/bin/env bash
set -Eeuo pipefail

display_number="${DISPLAY_NUMBER:-99}"
screen_width="${SCREEN_WIDTH:-1440}"
screen_height="${SCREEN_HEIGHT:-900}"
screen_depth="${SCREEN_DEPTH:-24}"
vnc_password="${VNC_PASSWORD:-browser}"
start_url="${START_URL:-about:blank}"
browser_home="${HOME:-/home/browser}"
profile_dir="${BROWSER_PROFILE_DIR:-${browser_home}/.config/chromium}"
runtime_dir="${BROWSER_RUNTIME_DIR:-/run/browser}"
log_dir="${BROWSER_LOG_DIR:-${runtime_dir}}"
novnc_address="${NOVNC_LISTEN_ADDRESS:-0.0.0.0}"
novnc_port="${NOVNC_LISTEN_PORT:-6080}"
cdp_address="${CDP_LISTEN_ADDRESS:-0.0.0.0}"
cdp_port="${CDP_LISTEN_PORT:-9222}"
chromium_bin="${CHROMIUM_BIN:-}"

if [[ -z "$chromium_bin" ]]; then
    for candidate in chromium chromium-browser; do
        if command -v "$candidate" >/dev/null 2>&1; then
            chromium_bin="$(command -v "$candidate")"
            break
        fi
    done
fi
if [[ -z "$chromium_bin" ]]; then
    echo "Chromium executable not found; set CHROMIUM_BIN explicitly" >&2
    exit 127
fi

for value in "$display_number" "$screen_width" "$screen_height" "$screen_depth" "$novnc_port" "$cdp_port"; do
    if [[ ! "$value" =~ ^[0-9]+$ ]]; then
        echo "Display and screen settings must be positive integers" >&2
        exit 2
    fi
done

if [[ -z "$vnc_password" ]]; then
    echo "VNC_PASSWORD must not be empty" >&2
    exit 2
fi
if ((${#vnc_password} > 8)); then
    echo "VNC_PASSWORD must be at most 8 characters (VNC protocol limit)" >&2
    exit 2
fi

export DISPLAY=":${display_number}"
mkdir -p "$runtime_dir" "$profile_dir" "$log_dir"

pids=()
cleanup() {
    trap - EXIT INT TERM
    if ((${#pids[@]})); then
        kill "${pids[@]}" 2>/dev/null || true
        wait "${pids[@]}" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

Xvfb "$DISPLAY" \
    -screen 0 "${screen_width}x${screen_height}x${screen_depth}" \
    -ac +extension GLX +render -noreset &
pids+=("$!")

for _ in {1..50}; do
    if xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
        break
    fi
    sleep 0.1
done
if ! xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
    echo "Xvfb did not become ready" >&2
    exit 1
fi

fluxbox >"${log_dir}/fluxbox.log" 2>&1 &
pids+=("$!")

vnc_password_file="${runtime_dir}/vnc.pass"
x11vnc -storepasswd "$vnc_password" "$vnc_password_file" >/dev/null
x11vnc \
    -display "$DISPLAY" \
    -rfbauth "$vnc_password_file" \
    -forever -shared -localhost -rfbport 5900 \
    >"${log_dir}/x11vnc.log" 2>&1 &
pids+=("$!")

websockify \
    --web=/usr/share/novnc/ \
    "${novnc_address}:${novnc_port}" localhost:5900 \
    >"${log_dir}/novnc.log" 2>&1 &
pids+=("$!")

chromium_args=(
    "--user-data-dir=${profile_dir}"
    --no-first-run
    --no-default-browser-check
    --disable-dev-shm-usage
    --disable-gpu
    --password-store=basic
    "--remote-debugging-address=${cdp_address}"
    "--remote-debugging-port=${cdp_port}"
    --start-maximized
)

if [[ "${ENABLE_CHROME_SANDBOX:-false}" != "true" ]]; then
    chromium_args+=(--no-sandbox)
fi

if [[ -n "${CHROMIUM_FLAGS:-}" ]]; then
    read -r -a extra_chromium_args <<<"$CHROMIUM_FLAGS"
    chromium_args+=("${extra_chromium_args[@]}")
fi

dbus-run-session -- "$chromium_bin" "${chromium_args[@]}" "$start_url" \
    >"${log_dir}/chromium.log" 2>&1 &
pids+=("$!")

echo "Browser ready: noVNC on ${novnc_address}:${novnc_port}, CDP on ${cdp_address}:${cdp_port}"

# The browser service should restart if any core process exits unexpectedly.
set +e
wait -n "${pids[@]}"
exit_code=$?
set -e
echo "A browser process exited with status ${exit_code}" >&2
exit "$exit_code"
