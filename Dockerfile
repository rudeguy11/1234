FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:99 \
    LIBGL_ALWAYS_SOFTWARE=1 \
    MC_VERSION=26.1 \
    MC_DIR=/data/minecraft

RUN apt-get update && apt-get install -y --no-install-recommends \
      python3 python3-pip ca-certificates curl jq \
      xvfb xdotool x11-utils \
      libgl1 libglx-mesa0 libgl1-mesa-dri libegl1 libopenal1 \
      libxrandr2 libxcursor1 libxinerama1 libxi6 libxxf86vm1 libxext6 libxrender1 \
      libpulse0 fontconfig fonts-dejavu-core \
    && pip3 install --break-system-packages --no-cache-dir portablemc \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY start.sh /app/start.sh
COPY *.jar /app/mods/
RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]
