import std/[os, strformat, strutils, osproc, sequtils]
import ./packageinfo
import parseini

const Perm755 = {fpUserExec, fpUserWrite, fpUserRead, 
                          fpGroupExec, fpGroupRead, 
                          fpOthersExec, fpOthersRead}

proc isExecutable(path: string): bool =
  let p = getFilePermissions(path)
  result = fpUserExec in p and fpGroupExec in p and fpOthersExec in p

proc isBinaryProgram(fileName: string): bool =
  var file = open(fileName, fmRead)
  var magicNumber: array[4, uint8]
  discard file.readBytes(magicNumber, 0,  4)
  file.close()
  return magicNumber == [127.uint8, 'E'.ord.uint8, 'L'.ord.uint8, 'F'.ord.uint8]

proc findExes*(baseDir: string): seq[string] =
  toSeq(walkDirRec(baseDir)).filterIt(it.isBinaryProgram)

proc collectDeps*(exes:seq[string]): seq[string] =
  const Prefix = "shlibs:Depends="
  const PrefixLen = Prefix.len
  for file in exes:
    let cmd = fmt"dpkg-shlibdeps -e{file} -O"
    debugEcho cmd
    let (output, exitCode) = execCmdEx(cmd)
    if not exitCode == 0:
      quit(output)
    else:
      debugEcho output
      for line in output.splitLines:
        # ignore warning: package could avoid a useless dependency
        if Prefix in line:
          result.add line.substr(PrefixLen).strip()

proc getDirectorySize*(directory: string): int =
  ## get directory size in bytes
  var totalSize = 0

  for file in walkDirRec(directory):
    totalSize += getFileSize(file)

  return totalSize

proc getControlBasic*(pkgInfo: PackageInfo, metaInfo: MetaInfo): string =
  ## size in kb
  let arch = hostCPU
  result = fmt"""
  Source: {pkgInfo.name}
  Package: {pkgInfo.name}
  Version: {pkgInfo.version}
  Description: {pkgInfo.desc}
  Architecture: {arch}
  Maintainer: {metaInfo.maintainer}
  """.unindent

proc getControl*(pkgInfo: PackageInfo, metaInfo: MetaInfo, depends: seq[string], size: int): string =
  ## size in kb
  let arch = hostCPU
  var deps = metaInfo.linuxDepends
  deps.add(depends)
  result = fmt"""
  Source: {pkgInfo.name}
  Package: {pkgInfo.name}
  Version: {pkgInfo.version}
  Description: {pkgInfo.desc}
  Architecture: {arch}
  Maintainer: {metaInfo.maintainer}
  Installed-Size: {size}
  Depends: {deps.join(",")}
  """.unindent

proc createLinuxTree*(baseDir: string) =
  createDir(baseDir / "usr" / "bin")
  createDir(baseDir / "usr" / "share" / "applications")
  # usr/share/applications/{pkgInof.name}.desktop
  createDir(baseDir / "usr" / "share" / "icons")
  # /usr/share/icons/{pkgInfo.name}.png
  # dpkg-deb --build

  createDir(baseDir / "usr" / "sbin")
  createDir(baseDir / "etc")
  createDir(baseDir / "usr" / "lib")
  createDir(baseDir / "var" / "lib")
  createDir(baseDir / "var" / "log")
  createDir(baseDir / "usr" / "include")

proc createDebianTree*(baseDir: string) =
  createDir(baseDir / "debian")
  setFilePermissions(baseDir / "debian", Perm755)
  # debian/control
  createLinuxTree(baseDir)

proc getDesktop*(pkgInfo: PackageInfo, metaInfo: MetaInfo, format = ""): string =
  let productName = metaInfo.productName
  let name = if productName.len > 0: productName else: pkgInfo.name
  var dict = newConfig()
  dict.setSectionKey("Desktop Entry", "Name", name, false)
  dict.setSectionKey("Desktop Entry", "Comment", pkgInfo.desc, false)
  # appimage-builder
  # let exec = if format == "appimage": "usr/bin/" & pkgInfo.name else: pkgInfo.name
  let exec = pkgInfo.name
  dict.setSectionKey("Desktop Entry", "Exec", exec , false)
  let icon = if format == "appimage": pkgInfo.name else: fmt"/usr/share/icons/{pkgInfo.name}.png"
  dict.setSectionKey("Desktop Entry", "Icon", icon, false)
  dict.setSectionKey("Desktop Entry", "Terminal", "false", false)
  dict.setSectionKey("Desktop Entry", "Type", "Application", false)
  if metaInfo.linuxCategories.len > 0:
    let cates = metaInfo.linuxCategories.join(";") & ";"
    dict.setSectionKey("Desktop Entry", "Categories", cates, false)
  # dict.setSectionKey("Desktop Entry", "Version", pkgInfo.version, false)
  result = $dict

when isMainModule:
  let version = "1.0.0"
  let desc = "my app desc"
  let pkgInfo = PackageInfo(name: "myapp", version: version, desc: desc)
  echo getDesktop(pkgInfo)
  echo getDirectorySize(".")

