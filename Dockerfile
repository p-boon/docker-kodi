FROM debian:trixie-slim
# Alternative: FROM n4jm4/raspberry-pi-os (doesn't require Pre 1 and Pre 2 below)

LABEL version="1.0"

ENV KODI_START_CMD="kodi --standalone"
ENV KODI_PROC_NAME="kodi.bin"

# Pre 1: See https://github.com/mcandre/raspberry-pi-os/blob/main/Dockerfile
RUN mkdir -p /etc/crypto-policies/back-ends && \
    cat /usr/share/apt/default-sequoia.config | \
        sed 's/sha1.second_preimage_resistance = 2026-02-01/sha1.second_preimage_resistance = 2036-02-01/' \
        >/etc/crypto-policies/back-ends/apt-sequoia.config

# Pre 2: Add Raspberry PI OS to apt sources to get Kodi patched for RPI.
RUN apt update && \
    apt install --no-install-recommends -y \
        ca-certificates \
        curl \
        gpg && \
    curl -L https://archive.raspberrypi.org/debian/raspberrypi.gpg.key | \
        gpg --dearmor -o /etc/apt/trusted.gpg.d/raspberrypi.gpg && \
    apt remove --autoremove --purge -y \
        ca-certificates \
        curl && \
    echo "deb http://archive.raspberrypi.org/debian/ trixie main" > /etc/apt/sources.list.d/raspi.list

# Install kodi, kodi-send and v41-utils for cec-follower.
RUN apt update && \
    apt install --no-install-recommends -y \
        kodi \
        kodi-repository-kodi \
        kodi-eventclients-kodi-send \
        v4l-utils && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

COPY cec_monitor.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/cec_monitor.sh

COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]