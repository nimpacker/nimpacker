# nimpacker  ![Build Status](https://github.com/nimpacker/nimpacker/workflows/build/badge.svg) 

Build and packaging nimble binary package for Windows, macOS and Linux.

## Usage

## Build

`nimpacker build --target <windows|linux|macos> --icon data/logo.png --release`

on Windows will generate `.ico` and embedd into `.exe` via `rcedit`.

on macOS will generate `.icns` and put into `.app` directory. Supports universal binaries for both Intel and Apple Silicon Macs with `--format universal`.

on Linux just binary.

Produced files under `./build`

### Packaging

`nimpacker pack --target <windows|linux|macos> --icon data/logo.png --release`

Packaging nimble binary package into (`.exe`, `.dmg`, `.deb`)

on Windows will generate installer exe via `Inno Setup`.

on macOS will generate `.dmg` via `create-dmg`. Supports universal binaries with `--format universal` flag.

on Linux will generate `.deb` via `dpkg-dev` and `.AppImage` via `linuxdeployqt`.

Produced files under `./dist`

example directory structure.

``` sh
.
├── APPID.txt (Recommend for best practice)
├── .nimpacker_cache/
├── VERSION.txt (Recommend for best practice)
├── build
│   ├── linux
│   │   └── Release
│   │       ├── DEBIAN
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
│   ├── post_build.nims
│   ├── meta.nims
│   └── DEBIAN
│       ├── preinst
│       ├── postinst
│       ├── prerm
│       └── postrm

```

`.nimpacker_cache/` is cache direcotry for nimpacker.

### Universal Binaries (macOS)

For macOS, you can create universal binaries that work on both Intel and Apple Silicon Macs:

```bash
nimpacker build --target macos --format universal --icon data/logo.png --release
nimpacker pack --target macos --format universal --icon data/logo.png --release
```

This will build separate x86_64 and ARM64 binaries and combine them using `lipo` into a single universal binary.

`nimpacker/post_build.nims` is nimscript executed after build.

`nimpacker/meta.nims` is variables defined for app meta info.

`nimpacker/DEBIAN` scripts for deb package.

example `nimpacker/post_build.nims`

```nim
#!/usr/bin/env nim

mode = ScriptMode.Verbose # or .Silent

import std/[os, strformat]

const APP_DIR {.strdefine.} = ""

echo "Build directory: " & APP_DIR

let exe = "chromedriver".toExe

when defined(macosx):
  const ResourcesDir = APP_DIR / "Contents" / "Resources"
  cpDir "data", ResourcesDir / "data"
  mkDir ResourcesDir / "drivers"
  let src = "drivers" / "chromedriver-mac-arm64" / exe
  cpFile src, ResourcesDir / "drivers" / exe
elif defined(windows):
  mkDir APP_DIR / "drivers"
  cpDir "data", APP_DIR / "data"
  let src = "drivers" / "chromedriver-win64" / exe
  cpFile src, APP_DIR / "drivers" / exe
elif defined(linux):
  mkDir APP_DIR / "usr" / "share" / "package_name"
  cpDir "data", APP_DIR / "usr" / "share" / "package_name" / "data"
  let src = "drivers" / "chromedriver-linux64" / exe
  cpFile src, APP_DIR / "usr" / "bin" / exe
```

`APP_DIR` is defined via `nimpacker`

example `nimpacker/meta.nims`

```nim
import os

productName = "NimPacker" # default to package name

# a GUID required by InnoSetup
appId = staticRead(getCurrentDir() / "APPID.txt")

# file associations, used for MacOS
fileAssociations = @[
    DocumentType(
        exts: @["xlsx", "xls"],
        mimes: @[
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "application/vnd.ms-excel"
        ],
        utis: @[
            "org.openxmlformats.spreadsheetml.sheet",
            "com.microsoft.excel.xls"
            ],
        role: DocumentTypeRole.Viewer
    )
]

maintainer = "Debian QA Group <packages@qa.DEBIAN.org>" # deb Maintainer
homepage = "https://nim-lang.org" # deb and exe Homepage
linuxCategories = @["Utility"]
```
