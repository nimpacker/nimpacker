import std/[os, strformat, strutils]
import ./packageinfo
import parseini

proc getControl*(pkgInfo: PackageInfo, depends: string): string =
  let arch = hostCPU
  result = fmt"""
  Package: {pkgInfo.name}
  Version: {pkgInfo.version}
  Description: {pkgInfo.desc}
  Architecture: {arch}
  Maintainer: YOUR NAME <EMAIL>
  Depends: {depends}
  """.unindent

proc createDebianTree*(baseDir: string) =
  createDir(baseDir / "DEBIAN")
  # DEBIAN/control
  createDir(baseDir / "usr" / "bin")
  createDir(baseDir / "usr" / "share" / "applications")
  # usr/share/applications/{pkgInof.name}.desktop
  createDir(baseDir / "usr" / "share" / "icons")
  # /usr/share/icons/{pkgInfo.name}.png
  # dpkg-deb --build

proc getDesktop*(pkgInfo: PackageInfo): string =
  var dict = newConfig()
  dict.setSectionKey("Desktop Entry", "Name", pkgInfo.name, false)
  dict.setSectionKey("Desktop Entry", "Comment", pkgInfo.desc, false)
  dict.setSectionKey("Desktop Entry", "Exec", fmt"/usr/share/icons/{pkgInfo.name}.png", false)
  dict.setSectionKey("Desktop Entry", "Icon", pkgInfo.name, false)
  dict.setSectionKey("Desktop Entry", "Terminal", "false", false)
  dict.setSectionKey("Desktop Entry", "Type", "Application", false)
  dict.setSectionKey("Desktop Entry", "Categories", "Office", false)
  dict.setSectionKey("Desktop Entry", "Version", pkgInfo.version, false)
  result = $dict

when isMainModule:
  let version = "1.0.0"
  let desc = "my app desc"
  let pkgInfo = PackageInfo(name: "myapp", version: version, desc: desc)
  echo getDesktop(pkgInfo)

