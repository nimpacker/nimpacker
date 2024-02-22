import std/[os, json, tables, osproc, sequtils, strformat, oids, options, distros]
import cligen
import plists
import zippy/ziparchives
import icon
import icon/icns
import icon/ico
include nimpacker/packageinfo_schema
import nimpacker/packageinfo
import imageman/images
import imageman/colors
import imageman/resize
import zopflipng
import rcedit
include nimpacker/cocoaappinfo
import nimpacker/innosetup_script
import nimpacker/linux

when NimMajor >= 2:
  import checksums/md5
else:
  import std/md5

type
  MyImage = ref Image[ColorRGBAU]

const DEBUG_OPTS = " --verbose --debug "
const RELEASE_OPTS = " -d:release " # -d:noSignalHandler --exceptions:quirky
const CACHE_DIR_NAME = ".nimpacker_cache"

proc getPkgInfo(): PackageInfo =
  # let r = execProcess(fmt"nimble",args=["dump", "--json", getCurrentDir()],options={poUsePath})
  let r = execCmdEx("nimble dump --json --silent " & getCurrentDir())
  let jsonNode = parseJson(r.output)
  result = to(jsonNode, PackageInfo)

proc zipBundle(dir: string): string =
  let p = getTempDir() / "zipBundle.zip"
  createZipArchive(dir, p)
  return p

proc handleBundle(wwwroot: string): string =
  var zip: string
  if len(wwwroot) > 0:
    let path = absolutePath wwwroot
    if not dirExists(path):
      raise newException(OSError, fmt"dir {path} not existed.")
    debugEcho path
    zip = zipBundle(path)
    debugEcho zip
  return zip

proc baseCmd(base: seq[string], wwwroot: string, release: bool, flags: seq[
    string]): seq[string] =
  result = base
  let zip = handleBundle(wwwroot)
  if len(wwwroot) > 0:
    result.add fmt" -d:bundle='{zip}'"
  result.add "--threads:on"
  result.add flags
  let opts = if not release: DEBUG_OPTS else: RELEASE_OPTS
  result.add opts

proc genImages[T](png: zopflipng.PNGResult[T], sizes: seq[int]): seq[ImageInfo] =
  let tempDir = getTempDir()
  let id = $genOid()
  result = sizes.map(proc (size: int): ImageInfo{.closure.} =
    let tmpName = tempDir & id & $size & ".png"
    let optName = tempDir & id & $size & "opt" & ".png"
    let img = cast[MyImage](png)
    let img2 = img[].resizedBicubic(size, size)
    let ad = cast[ptr UnCheckedArray[byte]](img2.data[0].unsafeAddr)
    discard zopflipng.savePNG32(tmpName, toOpenArray(ad, 0, img2.data.len * 4 -
        1), img2.width, img2.height)
    try:
      optimizePNG(tmpName, optName)
    except Exception as e:
      stderr.write(e.msg & "\n")
      return ImageInfo(size: size, filePath: tmpName)
    result = ImageInfo(size: size, filePath: optName)
  )

proc buildMacos(app_logo: string, wwwroot = "", release = false, flags: seq[string]) =
  let pwd: string = getCurrentDir()
  let pkgInfo = getPkgInfo()
  let buildDir = pwd / "build" / "macos"
  if not dirExists(buildDir):
    createDir(buildDir)
  let subDir = if release: "Release" else: "Debug"
  removeDir(buildDir)
  let appDir = buildDir / subDir / pkgInfo.name & ".app"
  createDir(appDir)
  let nSAppTransportSecurityJson = create(NSAppTransportSecurity,
    NSAllowsArbitraryLoads = some(true),
      NSAllowsLocalNetworking = some(true),
      NSExceptionDomains = some( %* @[
          {"localhost": {"NSExceptionAllowsInsecureHTTPLoads": true}.toTable}.toTable
          ])
  )
  var documentTypes: seq[DocumentType] = @[]
  if fileExists("app.json"):
    let data = parseJson(readFile("app.json"))
    if data.hasKey("fileAssociations"):
      let ass = getElems(data["fileAssociations"])
      for a in ass:
        documentTypes.add create(DocumentType,
          CFBundleTypeExtensions = some(@[a["ext"].getStr()]),
          CFBundleTypeMIMETypes = some(@[a["mimeType"].getStr()]),
          LSItemContentTypes = some(@[a["uti"].getStr()]),
          CFBundleTypeRole = some(a["role"].getStr())
        )
  let dt = if len(documentTypes) > 0: some(documentTypes) else: none(seq[DocumentType])
  let sec = if len(wwwroot) > 0: some(nSAppTransportSecurityJson) else: none(NSAppTransportSecurity)
  let appInfo = create(CocoaAppInfo,
    NSHighResolutionCapable = some(true),
    CFBundlePackageType = some("APPL"),
    CFBundleExecutable = pkgInfo.name,
    CFBundleDisplayName = pkgInfo.name,
    CFBundleVersion = pkgInfo.version,
    CFBundleIdentifier = none(string),
    NSAppTransportSecurity = sec,
    CFBundleIconName = none(string),
    CFBundleDocumentTypes = dt
    )
  var plist = appInfo.JsonNode

  if fileExists(app_logo):
    let outDir = appDir / "Contents" / "Resources"
    if not dirExists(outDir):
      createDir(outDir)
    if not dirExists(getCurrentDir() / CACHE_DIR_NAME):
      createDir(getCurrentDir() / CACHE_DIR_NAME)
    let hash = getMD5(readFile(app_logo))
    let cachePath = getCurrentDir() / CACHE_DIR_NAME / fmt"app.{hash}.icns"
    var path: string
    if fileExists(cachePath):
      path = outDir / "app.icns"
      copyFile(cachePath, path)
    else:
      let png = zopflipng.loadPNG32(app_logo)
      let images = genImages(png, @(icns.REQUIRED_IMAGE_SIZES))
      path = generateICNS(images.filterIt(it != default(ImageInfo)), outDir)
      copyFile(path, cachePath)
      discard images.mapIt(tryRemoveFile(it.filePath))
    plist["CFBundleIconFile"] = newJString(extractFilename path)
  if not dirExists(appDir / "Contents"):
    createDir(appDir / "Contents")
  writePlist(plist, appDir / "Contents" / "Info.plist")
  var cmd = baseCmd(@["nimble", "build", "--silent", "-y"], wwwroot, release, flags)
  let finalCMD = cmd.join(" ")
  debugEcho finalCMD
  let (output, exitCode) = execCmdEx(finalCMD, options = {poUsePath})
  if exitCode == 0:
    debugEcho output
    let binOutDir = appDir / "Contents" / "MacOS"
    if not dirExists(binOutDir):
      createDir(binOutDir)
    moveFile(pwd / pkgInfo.name, binOutDir / pkgInfo.name)
  else:
    debugEcho output

proc runMacos(wwwroot = "", release = false, flags: seq[string]) =
  let pkgInfo = getPkgInfo()
  var cmd = baseCmd(@["nimble"], wwwroot, release, flags)
  let finalCMD = cmd.concat(@["run", pkgInfo.name]).join(" ")
  debugEcho finalCMD
  let (output, exitCode) = execCmdEx(finalCMD)
  if exitCode == 0:
    debugEcho output
  else:
    debugEcho output

proc runWindows(wwwroot = "", release = false, flags: seq[string]) =
  let pkgInfo = getPkgInfo()
  var cmd = baseCmd(@["nimble"], wwwroot, release, flags)
  let finalCMD = cmd.concat(@["run", pkgInfo.name]).join(" ")
  debugEcho finalCMD
  let (output, exitCode) = execCmdEx(finalCMD)
  if exitCode == 0:
    debugEcho output
  else:
    debugEcho output

proc getAppDir(target: string, release: bool): string =
  let pkgInfo = getPkgInfo()
  let pwd = getCurrentDir()
  let buildDir = pwd / "build" / target
  let subDir = if release: "Release" else: "Debug"
  result = buildDir / subDir
  if target == "macos":
    result = result / pkgInfo.name & ".app"

proc buildWindows(app_logo: string, wwwroot = "", release = false, flags: seq[string]): string {.discardable.} =
  let pwd: string = getCurrentDir()
  let pkgInfo = getPkgInfo()
  let buildDir = pwd / "build" / "windows"
  let subDir = if release: "Release" else: "Debug"
  removeDir(buildDir)
  let appDir = buildDir / subDir
  createDir(appDir)
  let logoExists = fileExists(app_logo)
  # var res: string
  # var output: string
  # var exitCode: int
  var icoPath: string
  if logoExists:
    let png = zopflipng.loadPNG32(app_logo)
    let tempDir = getTempDir()
    let images = genImages(png, @(ico.REQUIRED_IMAGE_SIZES))
    icoPath = generateICO(images.filterIt(it != default(ImageInfo)), tempDir)
    discard images.mapIt(tryRemoveFile(it.filePath))
    # for windres
    # let content = &"id ICON \"{path}\""
    # let rc = getTempDir() / "my.rc"
    # writeFile(rc, content)
    # res = getTempDir() / "my.res"
    # let resCmd = &"windres {rc} -O coff -o {res}"
    # (output, exitCode) = execCmdEx(resCmd)
  var myflags: seq[string]
  when not defined(windows):
    myflags.add "-d:mingw"
  var cmd = baseCmd(@["nimble", "build", "--silent", "-y"], wwwroot, release,
      myflags.concat flags)
  # for windres
  # if logoExists and exitCode == 0:
  #   discard cmd.concat @[&"--passL:{res}"]
  #   debugEcho output
  # else:
  #   debugEcho output

  let finalCMD = cmd.join(" ")
  debugEcho finalCMD
  let (o, e) = execCmdEx(finalCMD)

  if e == 0:
    debugEcho o
    let exePath = pwd / pkgInfo.name & ".exe"
    if icoPath.len > 0 and fileExists(icoPath):
      rcedit(none(string), exePath, {"icon": icoPath}.toTable())
    moveFile(exePath, appDir / pkgInfo.name & ".exe")
  else:
    debugEcho o
  result = icoPath

proc buildLinux(app_logo: string, wwwroot = "", release = false, flags: seq[string]) =
  let pwd: string = getCurrentDir()
  let pkgInfo = getPkgInfo()
  let buildDir = pwd / "build" / "linux"
  let subDir = if release: "Release" else: "Debug"
  removeDir(buildDir)
  let appDir = buildDir / subDir
  createDir(appDir)
  var cmd = baseCmd(@["nimble", "build", "--silent", "-y"], wwwroot, release, flags)
  let finalCMD = cmd.join(" ")
  debugEcho finalCMD
  let (o, e) = execCmdEx(finalCMD)
  if e == 0:
    debugEcho o
    let exePath = pwd / pkgInfo.name
    moveFile(exePath, appDir / pkgInfo.name)
  else:
    debugEcho o

proc packLinux(release:bool, icon: string) =
  let pkgInfo = getPkgInfo()
  let appDir = getAppDir("linux", release)
  createDebianTree(appDir)
  moveFile(appDir / pkgInfo.name, appDir / "usr" / "bin" / pkgInfo.name)
  copyFile(icon, appDir / "usr" / "share" / "icons" / pkgInfo.name & ".png")
  let desktop = getDesktop(pkgInfo)
  let desktopPath = appDir / "usr" / "share" / "applications" / pkgInfo.name & ".desktop"
  writeFile(desktopPath, desktop)
  let exes = findExes(appDir)
  let baseControl = getControlBasic(pkgInfo)
  writeFile(appDir / "debian" / "control", baseControl)
  let oldPWD = getCurrentDir()
  setCurrentDir(appDir)
  let deps = collectDeps(exes)
  setCurrentDir(oldPWD)
  let size = getDirectorySize(appDir)
  let sizeInKb = size div 1024
  let controlContent = getControl(pkgInfo, deps, sizeInKb)
  writeFile(appDir / "debian" / "control", controlContent)
  let cmd = fmt"dpkg-deb --build {appDir} dist"
  let (output, exitCode) = execCmdEx(cmd)
  debugEcho output
  quit(exitCode)

proc postScript(post_build: string, target: string, release: bool) =
  if post_build.len > 0 and fileExists(post_build):
    let appDir = getAppDir(target, release)
    let cmd = fmt"""nim e --hints:off -d:APP_DIR="{appDir}" {post_build}"""
    let (output, exitCode) = execCmdEx(cmd, options = {poUsePath, poStdErrToStdOut})
    debugEcho output

proc build(target: string, icon = getCurrentDir() / "logo.png",
    post_build = getCurrentDir() / "nimpacker" / "post_build.nims", wwwroot = "",
    release = false, flags: seq[string]): int =
  case target:
    of "macos":
      # nim c -r -f src/crownguipkg/cli.nim build --target macos --wwwroot ./docs
      buildMacos(icon, wwwroot, release, flags)
    of "windows":
      buildWindows(icon, wwwroot, release, flags)
    else:
      discard

  postScript(post_build, target, release)

proc run(target: string, wwwroot = "", release = false, flags: seq[string]): int =
  case target:
    of "macos":
      # nim c -r -f src/crownguipkg/cli.nim run --target macos --wwwroot ./docs
      runMacos(wwwroot, release, flags)
    of "windows":
      runWindows(wwwroot, release, flags)
    else:
      discard

proc packWindows(release:bool, icoPath: string) =
  let pkgInfo = getPkgInfo()
  let appDir = getAppDir("windows", release)
  let script = getInnoSetupScript(pkgInfo, appDir, icoPath)
  let tempDir = getTempDir()
  let issPath = tempDir / pkgInfo.name & ".iss"
  writeFile(issPath, script)
  let isccPath = findExe("ISCC")
  let (installCmd, sudo) = foreignDepInstallCmd("InnoSetup")
  if isccPath.len == 0:
    quit("ISCC.exe not found, please ensure it's in `Path` environment variable or install it via `" & installCmd & "`")
  let cmd = "ISCC.exe " & issPath
  let (output, exitCode) = execCmdEx(cmd, options = {poUsePath, poStdErrToStdOut})
  debugEcho output

proc pack(target: string, icon = getCurrentDir() / "logo.png",
    post_build = getCurrentDir() / "nimpacker" / "post_build.nims", wwwroot = "",
    release = false, flags: seq[string]): int =

  case target:
    of "macos":
      # nim c -r -f src/crownguipkg/cli.nim build --target macos --wwwroot ./docs
      buildMacos(icon, wwwroot, release, flags)
      postScript(post_build, target, release)
    of "windows":
      let icoPath = buildWindows(icon, wwwroot, release, flags)
      postScript(post_build, target, release)
      packWindows(release, icoPath)
    of "linux":
      buildLinux(icon, wwwroot, release, flags)
      let appDir = getAppDir("linux", release)
      createDir(appDir / "usr" / "bin")
      postScript(post_build, target, release)
      packLinux(release, icon)
    else:
      discard

dispatchMulti([build], [run], [pack])
