# Fabric client AFK bot (real Minecraft client, headless)

Runs the real Minecraft client with Fabric Loader + Fabric API + your mods inside
Docker (virtual screen), joins your server and idles. Works with servers that
require Fabric/mods, which Mineflayer cannot do.

## Mods
- `mods/` holds the jars copied into the client on every start.
- Fabric API is downloaded automatically from Modrinth.
- IMPORTANT: put the SAME mods as your server (every mod that adds blocks/items,
  Create itself, etc.). Missing mods = "registry sync" kick again.

## Deploy on Railway (paid plan, give the service >= 3 GB RAM)
1. Push the CONTENTS of this folder to a GitHub repo (Dockerfile in the root).
2. Railway -> New -> Deploy from GitHub.
3. Variables: MC_HOST, MC_PORT, MC_VERSION=26.1, BOT_USERNAME=pampa,
   optional AUTH_PASSWORD, optional MC_HEAP_MB.
4. Make sure the Aternos server is online, then deploy.

Aternos changes the port on each restart - update MC_PORT when it changes.
