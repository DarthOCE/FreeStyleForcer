# Really (Free) Freestyle

This script patches the NVIDIA Overlay's CEF main.js to bypass Freestyle restrictions imposed by NVIDIA.

# Who jailed Freestyle?

## Setting 0x105E2A1D

This is a setting in the driver store (DRS), which can be configured with nvidiaProfileInspector. It has no documented name and can only be seen if you enable `Show unknown values`, but we will call it 'Freestyle Whitelist'.

```
enum FreeStyle_Whitelist
{
    Blacklisted  = 0,  // Currently only on MSFS 2024, FIFA 18, Fortnite, Rust.
    Unrestricted = 1,
    Restricted   = 4   // Used on many games, especially multiplayer games.
}
```

If your game already had support for game filters and it was disabled afterwards by NVIDIA, then this is most likely set to `Restricted` and you don't need to modify it with nvidiaProfileInspector.

There is a commented patch in `patch.ps1` to unconditionally force this setting on, if you would like this behavior uncomment it, however it has not been tested extensively so use at your own risk.

## ChromaDB API

Game metadata is provided to NVIDIA services by a GraphQL API linked to their ChromaDB, it's used to describe feature support, images, titles and more. This API has been described in more detail [here](https://github.com/woctezuma/geforce-leak) and [here](https://ighor.medium.com/i-unlocked-nvidia-geforce-now-and-stumbled-upon-pirates-dc48a3f8ff7).

The set of features in the metadata are these:

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

So, they can disable any of these features dynamically at any time by just setting the field to false. However, we can do the same by just setting the field to true!

More details about the innerworkings of the script are in comments inside `patch.ps1`.