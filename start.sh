#!/usr/bin/env bash
# Headless real Minecraft client (Fabric + mods) that joins a server and idles.
set -u

: "${MC_HOST:?Set MC_HOST in Railway Variables}"
MC_PORT="${MC_PORT:-25565}"
MC_VERSION="${MC_VERSION:-26.1}"
BOT_USERNAME="${BOT_USERNAME:-pampa}"
MC_HEAP_MB="${MC_HEAP_MB:-1536}"
MC_DIR="${MC_DIR:-/data/minecraft}"
export JAVA_TOOL_OPTIONS="-Xms512m -Xmx${MC_HEAP_MB}m"

log() { echo "[$(date +%T)] [bot] $*"; }

mkdir -p "$MC_DIR/mods"
# Always sync the mods you shipped in the repo
cp -f /app/mods/*.jar "$MC_DIR/mods/" 2>/dev/null || true

# Fabric API (required by the server) - download latest for this MC version if missing
if ! ls "$MC_DIR"/mods/fabric-api-*.jar >/dev/null 2>&1; then
  log "Downloading Fabric API for $MC_VERSION from Modrinth..."
  URL=$(curl -fsSL "https://api.modrinth.com/v2/project/fabric-api/version?loaders=%5B%22fabric%22%5D&game_versions=%5B%22${MC_VERSION}%22%5D" \
        | jq -r '.[0].files[] | select(.primary==true) | .url' | head -n1)
  if [ -n "${URL:-}" ] && [ "$URL" != "null" ]; then
    curl -fsSL -o "$MC_DIR/mods/$(basename "$URL")" "$URL" && log "Got $(basename "$URL")"
  else
    log "WARNING: couldn't find Fabric API for $MC_VERSION. Put fabric-api-*.jar in the mods/ folder of the repo."
  fi
fi

# Very light video settings so software rendering stays cheap
write_options() {
  cat > "$MC_DIR/options.txt" <<OPT
renderDistance:2
simulationDistance:5
maxFps:10
graphicsMode:0
particles:2
entityShadows:false
enableVsync:false
pauseOnLostFocus:false
musicVolume:0.0
soundCategory_master:0.0
OPT
}
[ -f "$MC_DIR/options.txt" ] || write_options

# Virtual screen
start_xvfb() {
  pgrep Xvfb >/dev/null || { Xvfb :99 -screen 0 854x480x24 -nolisten tcp >/dev/null 2>&1 & sleep 2; }
}

# Keeps the player "active" and sends /login if AUTH_PASSWORD is set
afk_loop() {
  sleep 60
  if [ -n "${AUTH_PASSWORD:-}" ]; then
    log "Sending /login"
    xdotool key t; sleep 1
    xdotool type --delay 80 "/login ${AUTH_PASSWORD}"; xdotool key Return
  fi
  while true; do
    sleep 45
    xdotool mousemove_relative -- 30 0 2>/dev/null; sleep 1
    xdotool mousemove_relative -- -30 0 2>/dev/null
    xdotool key space 2>/dev/null
  done
}

delay=10
while true; do
  start_xvfb
  afk_loop & AFK_PID=$!
  log "Launching Minecraft $MC_VERSION (Fabric) -> $MC_HOST:$MC_PORT as $BOT_USERNAME"
  START=$(date +%s)
  portablemc --main-dir "$MC_DIR" --work-dir "$MC_DIR" start "fabric:${MC_VERSION}" \
    -u "$BOT_USERNAME" -s "$MC_HOST" -p "$MC_PORT" --resolution 854x480
  CODE=$?
  kill "$AFK_PID" 2>/dev/null
  RAN=$(( $(date +%s) - START ))
  # Reset backoff if it stayed up a while, otherwise back off (max 5 min)
  if [ "$RAN" -gt 300 ]; then delay=10; else delay=$(( delay * 2 > 300 ? 300 : delay * 2 )); fi
  log "Client exited (code $CODE) after ${RAN}s. Restarting in ${delay}s..."
  sleep "$delay"
done
