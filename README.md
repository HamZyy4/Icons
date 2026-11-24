# ForktUI Icons

The companion icon-data repository for [ForktUI](https://github.com/HamZyy4/ForktUI). Keep the existing icon asset directories and their license/credit files when applying updates.

## Load

```lua
local Icons = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/HamZyy4/Icons/main/Main-v2.lua"
))()

Icons.SetIconsType("lucide")
local iconAsset = Icons.GetIcon("house")
```

Available icon packs include Lucide, Solar, Craft, Geist, SF Symbols, and Gravity UI.

## ForktUI integration

ForktUI expects the icon repository as a submodule at `src/Icons` and loads `Main-v2` from that local module tree. Standard Rojo deployments do not need an icon server bridge or RemoteFunction.

Maintainer: `sukitovone`. Original icon assets remain credited to their creators in the source project.
