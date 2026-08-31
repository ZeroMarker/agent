#!/usr/bin/env bash
set -Eeuo pipefail

if ((EUID != 0)); then
    echo "Run this installer as root: sudo ./install-systemd.sh" >&2
    exit 1
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
service_user=browser-desktop

if ! command -v apt-get >/dev/null 2>&1; then
    echo "This installer currently supports Debian and Ubuntu (apt-get)." >&2
    exit 1
fi

source /etc/os-release
case "${ID:-}" in
    ubuntu)
        chromium_package=chromium-browser
        ;;
    debian)
        chromium_package=chromium
        ;;
    *)
        echo "Unsupported apt distribution: ${ID:-unknown}" >&2
        exit 1
        ;;
esac

apt-get update
apt-get install -y --no-install-recommends \
    ca-certificates \
    "$chromium_package" \
    dbus-x11 \
    fluxbox \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    novnc \
    websockify \
    x11-utils \
    x11vnc \
    xvfb

if ! id "$service_user" >/dev/null 2>&1; then
    useradd \
        --system \
        --create-home \
        --home-dir /home/browser-desktop \
        --shell /usr/sbin/nologin \
        "$service_user"
fi

install -Dm0755 \
    "${script_dir}/start-browser.sh" \
    /usr/local/libexec/browser-desktop/start-browser.sh
install -Dm0644 \
    "${script_dir}/systemd/browser-desktop.service" \
    /etc/systemd/system/browser-desktop.service
install -Dm0644 \
    "${script_dir}/README.md" \
    /usr/local/share/doc/browser-desktop/README.md

if [[ ! -e /etc/default/browser-desktop ]]; then
    generated_password="$(od -An -N4 -tx4 /dev/urandom | tr -d ' \n')"
    temp_config="$(mktemp)"
    trap 'rm -f "$temp_config"' EXIT
    sed \
        "s/^VNC_PASSWORD=.*/VNC_PASSWORD=${generated_password}/" \
        "${script_dir}/systemd/browser-desktop.env.example" \
        >"$temp_config"
    install -m0600 "$temp_config" /etc/default/browser-desktop
    echo "Generated VNC password: ${generated_password}"
else
    echo "Keeping existing /etc/default/browser-desktop"
fi

systemctl daemon-reload
systemctl enable --now browser-desktop.service
systemctl --no-pager --full status browser-desktop.service

echo "Open http://127.0.0.1:6080/vnc.html?autoconnect=1&resize=scale"
