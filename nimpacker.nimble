import os, std/distros

# Package

version       = "0.2.2"
author        = "bung87"
description   = "Build and packaging nimble binary package for Windows, macOS and Linux"
license       = "MIT"
srcDir        = "src"
bin           = @["nimpacker"]


# Dependencies

requires "nim >= 1.4.4"
requires "plists"
requires "cligen >= 1.6"
requires "imageman"
requires "zopflipng >= 0.1.6"
requires "rcedit"
requires "icon >= 0.2.0"
requires "jsonschema"
requires "parseini"
requires "nimscripter >= 1.1.5"
requires "puppy"

when NimMajor >= 2:
  requires "checksums"

if detectOs(Windows):
  foreignDep "InnoSetup"
elif detectOs(Debian) or detectOs(Ubuntu) or
  detectOs(Kali) or detectOs(Elementary) or detectOs(Zorin) or
  detectOs(MXLinux) or detectOs(Deepin) or detectOs(Parrot) or
  detectOs(Trisquel):
  foreignDep "dpkg-dev"
elif detectOs(MacOSX):
  foreignDep "create-dmg"
