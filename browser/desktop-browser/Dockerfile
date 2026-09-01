FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

COPY --chmod=755 install-novnc.sh /usr/local/bin/install-novnc

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        chromium \
        curl \
        dbus-x11 \
        fluxbox \
        fonts-noto-cjk \
        fonts-noto-color-emoji \
        websockify \
        x11-utils \
        x11vnc \
        xvfb \
    && /usr/local/bin/install-novnc \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --uid 1000 --shell /bin/bash browser \
    && mkdir -p /home/browser/.config/chromium /run/browser \
    && chown -R browser:browser /home/browser /run/browser

COPY --chmod=755 --chown=browser:browser start-browser.sh /usr/local/bin/start-browser

USER browser
WORKDIR /home/browser

EXPOSE 6080 9222

HEALTHCHECK --interval=10s --timeout=3s --start-period=20s --retries=3 \
    CMD curl --fail --silent http://127.0.0.1:6080/vnc.html >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/start-browser"]
