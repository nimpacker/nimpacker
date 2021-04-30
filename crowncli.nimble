# Package

version       = "0.1.1"
author        = "bung87"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
bin           = @["crowncli"]


# Dependencies

requires "nim >= 1.4.4"
requires "plists"
requires "cligen >= 1.5"
requires "imageman"
requires "zopflipng"
requires "rcedit"
requires "zippy"
requires "http://github.com/bung87/static_server >= 2.2.0"
requires "https://github.com/bung87/icon >= 0.2.0"
requires "jsonschema"
