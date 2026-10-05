# App icon

The primary app icon is a PNG-generated asset catalog, not the Icon Composer
(`.icon`) bundle that ships by default.

## Source

`docs/assets/icon-1024.png`. Note: the file on disk is 512x512 RGBA with a
transparent rounded-corner mask, not 1024x1024 opaque as first described. The
script flattens that transparency onto the image's average opaque colour and
upscales to 1024 for the marketing slot.

## Regenerate

From the repo root:

```sh
python3 scripts/generate_app_icon.py
```

It writes every required size into
`Telegram/Telegram-iOS/DefaultAppIcon.xcassets/AppIconLLC.appiconset/` and
rewrites that set's `Contents.json`.

## Wiring

`Telegram/BUILD` sets `app_icons = [":DefaultAppIcon"]`, which points at
`DefaultAppIcon.xcassets/AppIconLLC.appiconset` (name matches the Info.plist
`CFBundlePrimaryIcon` -> `CFBundleIconName = AppIconLLC`). The default
paper-plane Icon Composer (`Telegram.icon`) is left on disk but no longer
referenced. Alternate icons (the in-app picker) are untouched.

The CI verify step asserts `Assets.car` is present in the built `.app`, which is
where `actool` compiles the asset catalog.
