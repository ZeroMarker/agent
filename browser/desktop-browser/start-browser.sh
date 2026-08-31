#!/usr/bin/env bash
set -Eeuo pipefail

display_number="${DISPLAY_NUMBER:-99}"
screen_width="${SCREEN_WIDTH:-1440}"
screen_height="${SCREEN_HEIGHT:-900}"
screen_depth="${SCREEN_DEPTH:-24}"
vnc_password="${VNC_PASSWORD:-browser}"
start_url="${START_URL:-about:blank}"

for value in "$display_number" "$screen_width" "$screen_height" "$screen_depth"; do
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
mkdir -p /run/browser /home/browser/.config/chromium

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

fluxbox >/run/browser/fluxbox.log 2>&1 &
pids+=("$!")

vnc_password_file=/run/browser/vnc.pass
x11vnc -storepasswd "$vnc_password" "$vnc_password_file" >/dev/null
x11vnc \
    -display "$DISPLAY" \
    -rfbauth "$vnc_password_file" \
    -forever -shared -localhost -rfbport 5900 \
    >/run/browser/x11vnc.log 2>&1 &
pids+=("$!")

websockify \
    --web=/usr/share/novnc/ \
    0.0.0.0:6080 localhost:5900 \
    >/run/browser/novnc.log 2>&1 &
pids+=("$!")

chromium_args=(
    --user-data-dir=/home/browser/.config/chromium
    --no-first-run
    --no-default-browser-check
    --disable-dev-shm-usage
    --disable-gpu
    --password-store=basic
    --remote-debugging-address=0.0.0.0
    --remote-debugging-port=9222
    --start-maximized
)

if [[ "${ENABLE_CHROME_SANDBOX:-false}" != "true" ]]; then
    chromium_args+=(--no-sandbox)
fi

if [[ -n "${CHROMIUM_FLAGS:-}" ]]; then
    read -r -a extra_chromium_args <<<"$CHROMIUM_FLAGS"
    chromium_args+=("${extra_chromium_args[@]}")
fi

dbus-run-session -- chromium "${chromium_args[@]}" "$start_url" \
    >/run/browser/chromium.log 2>&1 &
pids+=("$!")

echo "Browser ready: noVNC on :6080, Chrome DevTools Protocol on :9222"

# The browser service should restart if any core process exits unexpectedly.
wait -n "${pids[@]}"
exit_code=$?
echo "A browser process exited with status ${exit_code}" >&2
exit "$exit_code"
