# Really (Free) Freestyle
# THIS IS A FORK THAT AUTOMATICALLY APPLIES THE NVIDIA PROFILE INSPECTOR PATCHES WITHOUT THE SOFTWARE

This script patches the NVIDIA Overlay's CEF main.js to bypass Freestyle restrictions imposed by NVIDIA.

Freestyle is NVIDIA's game filter system that allows applying real-time post-processing effects (sharpening, color adjustments, etc.) to games. It is more commonly known as 'NVIDIA Game Filters'.

# Running

**Make sure your NVIDIA App is updated to the latest version.**

Open PowerShell as Administrator then run: `irm https://raw.githubusercontent.com/haram/ReallyFreeStyle/refs/heads/main/patch.ps1 | iex`

The patches are temporary until the Overlay updates or the main.js is changed for any reason. In that case, re-run the script.

This may not work if your game is not correctly assigned Ansel rights in DRS, to fix this, download [NVIDIA Profile Inspector](https://github.com/Orbmu2k/nvidiaProfileInspector) and change the following settings:

- "Ansel - Enabled" -> 0x1
- "Ansel flags for enabled applications" -> 0x1
- "NVIDIA Predefined Ansel Usage" -> 0x1
- "Toggle to Enable/Disable Game Filters" -> 0x1
- 0x105E2A1D -> 0x4
- 0x100D51F7 -> 'Buffers=(Depth)' `If you are playing a multiplayer game, or a game with an anticheat`

**DISCLAIMER: This possibly breaks NVIDIA Terms of Service, use at your own risk.**

# Who jailed Freestyle? The ChromaDB.

Game metadata is provided to NVIDIA services by a GraphQL API linked to their ChromaDB. It describes feature support, images, titles, and more. This API has been analyzed in detail by [Ighor July](https://ighor.medium.com/i-unlocked-nvidia-geforce-now-and-stumbled-upon-pirates-dc48a3f8ff7).

The feature flags in the metadata are:

```
PHOTO_MODE
FREESTYLE
RTXDVC
REFLEX
REFLEXFLASHINDICATOR
REFLEXFIAUTO
REFLEXSTATS
GAMEASSIST
```

If the `FREESTYLE` feature is `false`, this setting takes precedence over DRS and disables Freestyle for the game.

More details about the inner workings of the script are in comments inside `patch.ps1`.
