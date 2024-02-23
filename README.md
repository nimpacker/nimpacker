# nimpacker

Build and packaging nimble binary package for Windows, macOS and Linux.

## Usage

## Build

`nimpacker build --target <windows|linux|macos> --icon data/logo.png --release`

on Windows will generate `.ico` and embedd into `.exe` via `rcedit`.

on macOS will generate `.icns` and put into `.app` directory.

on Linux just binary.

Produced files under `./build`

### Packaging

`nimpacker pack --target <windows|linux|macos> --icon data/logo.png --release`

Packaging nimble binary package into (`.exe`, `.dmg`, `.deb`)

on Windows will generate installer exe via `Inno Setup`, `APPID.txt` is required.

on macOS will generate `.dmg` via `create-dmg`.

on Linux will generate `.deb` via `dpkg-dev` tools.

Produced files under `./dist`

example directory structure.

``` sh
.
├── APPID.txt
├── .nimpacker_cache/
├── VERSION.txt
├── build
│   ├── linux
│   │   └── Release
│   │       ├── debian
│   │       │   └── control
│   │       └── usr
│   │           ├── bin
│   │           │   └── package_name
│   │           └── share
│   │               ├── applications
│   │               │   └── package_name.desktop
│   │               └── icons
│   │                   └── package_name.png
│   ├── windows
│   │   └── Release
│   │       └── package_name.exe
│   └── macos
│       └── Release
│           └── package_name.app
│               └── Contents
│                   ├── Info.plist
│                   ├── MacOS
│                   │   └── package_name
│                   └── Resources
│                       └── app.icns
├── dist
├── package_name.nimble
├── nimpacker
│   └── post_build.nims

```

`.nimpacker_cache/` is cache direcotry for nimpack

`nimpacker/post_build.nims` is nimscript executed after build.

example `post_build.nims`

```nim
#!/usr/bin/env nim

mode = ScriptMode.Verbose # or .Silent

import std/[os, strformat]

const APP_DIR {.strdefine.} = ""

echo "Build directory: " & APP_DIR

when defined(macosx):
  cpDir "data", fmt"{APP_DIR}/Contents/Resources/data"
  mkDir fmt"{APP_DIR}/Contents/Resources/drivers/"
  cpFile "drivers/chromedriver-mac-arm64/chromedriver", fmt"{APP_DIR}/Contents/Resources/drivers/chromedriver"
elif defined(windows):
  mkDir APP_DIR / "drivers"
  cpDir "data", APP_DIR / "data"
  cpFile "drivers" / "chromedriver-win64" / "chromedriver.exe", APP_DIR / "drivers" / "chromedriver.exe"
elif defined(linux):
  mkDir APP_DIR / "usr" / "share" / "package_name"
  cpDir "data", APP_DIR / "usr" / "share" / "package_name" / "data"
  cpFile "drivers/chromedriver-linux64/chromedriver", APP_DIR / "usr" / "bin" / "chromedriver"
  exec "chmod +x " & APP_DIR / "usr" / "bin" / "chromedriver"
```

`APP_DIR` is defined via `nimpacker`
