import os, std/distros

# Package

version       = "0.1.5"
author        = "bung87"
description   = "A new awesome nimble package"
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
requires "zippy"
requires "icon >= 0.2.0"
requires "jsonschema"
requires "parseini"
when NimMajor >= 2:
  requires "checksums"

if detectOs(Windows):
  foreignDep "InnoSetup"
