# Really (Free) Freestyle

This script patches the NVIDIA Overlay's CEF main.js to bypass Freestyle restrictions imposed by NVIDIA.

Freestyle is NVIDIA's game filter system that allows applying real-time post-processing effects (sharpening, color adjustments, etc.) to games. It is more commonly known as 'NVIDIA Game Filters'.

# Running

Download `patch.ps1`, then run the following in CMD as administrator: `powershell.exe -ExecutionPolicy Bypass -File patch.ps1`

The patches are temporary until the Overlay updates or the main.js is changed for any reason. In that scenario, re-run the script.

**DISCLAIMER: This possibly breaks NVIDIA Terms of Service, use at your own risk.**

# Who jailed Freestyle?

## Setting 0x105E2A1D

This is a setting in the driver store (DRS), which can be configured with [NVIDIA Profile Inspector](https://github.com/Orbmu2k/nvidiaProfileInspector). It has no documented name and can only be seen if you enable `Show unknown values`, but we will call it 'Freestyle Whitelist'.

```
enum FreeStyle_Whitelist
{
    Blacklisted  = 0,  // Currently only on MSFS 2024, FIFA 18, Fortnite, Rust.
    Unrestricted = 1,
    Restricted   = 4   // Used on many games, especially multiplayer games.
}
```

If your game already had support for game filters before, then this is most likely set to `Restricted` and you don't need to modify it with NVIDIA Profile Inspector.

There is a commented patch in `patch.ps1` to unconditionally force this setting on. If you would like this behavior, uncomment it; however, it has not been tested extensively so use at your own risk.

## ChromaDB API

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
