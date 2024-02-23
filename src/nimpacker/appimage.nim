import std/[os,strutils, strformat]
import ./packageinfo

proc createScalableIconsDir(baseDir: string) =
  createDir(baseDir / "usr" / "share" / "icons" / "hicolor" / "scalable" / "appps")
  # icon.svg

proc createNonScalableIconsDir(baseDir: string) =
  createDir(baseDir / "usr" / "share" / "icons" / "hicolor" / "scalable" / "48x48" / "apps")
  # icon.png
  # in desktop file: Icon=/usr/share/icons/hicolor/48x48/apps/icon.png
  # createDir(baseDir / "usr" / "share" / "icons" / "hicolor" / "scalable" / "16x16" / "apps")
  # createDir(baseDir / "usr" / "share" / "icons" / "hicolor" / "scalable" / "32x32" / "apps")
  # createDir(baseDir / "usr" / "share" / "icons" / "hicolor" / "scalable" / "256x256" / "apps")
  # createDir(baseDir / "usr" / "share" / "icons" / "hicolor" / "scalable" / "512x512" / "apps")

proc createAppImageTree*(baseDir: string) =
  ## https://docs.appimage.org/packaging-guide/manual.html#ref-manual
  ## https://docs.appimage.org/reference/appdir.html#root-icon
  createDir(baseDir / "usr" / "bin")
  createDir(baseDir / "usr" / "lib")

proc getAppRun*(pkgInfo: PackageInfo): string =
  result = fmt"""
  #!/bin/sh

  APPDIR=$(dirname "$(readlink -f "$0")")
  export PATH=$APPDIR/usr/bin:$PATH
  export LD_LIBRARY_PATH=$APPDIR/usr/lib:$APPDIR/usr/lib64:$LD_LIBRARY_PATH

  # Run the application binary
  $APPDIR/usr/bin/{pkgInfo.name} "$@"
  """.unindent

