#!/usr/bin/env bash
set -Eeuo pipefail

novnc_version="${NOVNC_VERSION:-1.7.0}"
novnc_sha256="${NOVNC_SHA256:-b1003a11b6e6e8d8f7f5e5586daae7f8ca651d8aee0aa155ff9ac841c48f52c6}"
install_root="${NOVNC_INSTALL_ROOT:-/opt/browser-desktop}"
archive_url="https://github.com/novnc/noVNC/archive/refs/tags/v${novnc_version}.tar.gz"
version_dir="${install_root}/novnc-${novnc_version}"
temp_dir="$(mktemp -d)"

cleanup() {
    rm -rf -- "$temp_dir"
}
trap cleanup EXIT

curl -fL --retry 3 --output "${temp_dir}/novnc.tar.gz" "$archive_url"
printf '%s  %s\n' "$novnc_sha256" "${temp_dir}/novnc.tar.gz" | sha256sum --check --status

install -d -m0755 "$install_root" "$version_dir"
tar -xzf "${temp_dir}/novnc.tar.gz" \
    --strip-components=1 \
    --directory "$version_dir"
ln -sfn "novnc-${novnc_version}" "${install_root}/novnc"

printf 'Installed noVNC %s in %s\n' "$novnc_version" "$version_dir"
