import std/[os, json, tables, osproc, strutils, sequtils, strformat, oids, options, distros]
import cligen
import plists
import icon
import icon/icns
import icon/ico
import imageman/images
import imageman/colors
import imageman/resize
import zopflipng
import rcedit
include nimpacker/packageinfo_schema
include nimpacker/cocoaappinfo
import nimpacker/[packageinfo, scripter]
import nimpacker/[innosetup_script, linux, macos, appimage]

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
  let r = execCmdEx("nimble dump --json --silent " & getCurrentDir())
  let jsonNode = parseJson(r.output)
  result = to(jsonNode, PackageInfo)

proc baseCmd(base: seq[string], release: bool, flags: seq[
    string]): seq[string] =
  result = base
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
      if e.msg != "not enough input to encode":
        stderr.write(e.msg & "\n")
      return ImageInfo(size: size, filePath: tmpName)
    result = ImageInfo(size: size, filePath: optName)
  )

proc buildMacos(app_logo: string, release = false, metaInfo: MetaInfo = default(MetaInfo), flags: seq[string]) =
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
  let documentTypes = metaInfo.fileAssociations.mapIt(
    create(DocumentType,
      CFBundleTypeExtensions = some(it.exts),
      CFBundleTypeMIMETypes = some(it.mimes),
      LSItemContentTypes = some(it.utis),
      CFBundleTypeRole = some($it.role)
    )
  )

  let productName = metaInfo.productName
  let displayName = if productName.len > 0: productName else: pkgInfo.name 

  let dt = if len(documentTypes) > 0: some(documentTypes) else: none(seq[DocumentType])
  # let sec = if len(wwwroot) > 0: some(nSAppTransportSecurityJson) else: none(NSAppTransportSecurity)
  let sec = none(NSAppTransportSecurity)
  let appInfo = create(CocoaAppInfo,
    NSHighResolutionCapable = some(true),
    CFBundlePackageType = some("APPL"),
    CFBundleExecutable = pkgInfo.name,
    CFBundleDisplayName = displayName,
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
  var cmd = baseCmd(@["nimble", "build", "--silent", "-y"], release, flags)
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

proc runMacos(release = false, flags: seq[string]) =
  let pkgInfo = getPkgInfo()
  var cmd = baseCmd(@["nimble"], release, flags)
  let finalCMD = cmd.concat(@["run", pkgInfo.name]).join(" ")
  debugEcho finalCMD
  let (output, exitCode) = execCmdEx(finalCMD)
  debugEcho output

proc runWindows(release = false, flags: seq[string]) =
  let pkgInfo = getPkgInfo()
  var cmd = baseCmd(@["nimble"], release, flags)
  let finalCMD = cmd.concat(@["run", pkgInfo.name]).join(" ")
  debugEcho finalCMD
  let (output, exitCode) = execCmdEx(finalCMD)
  debugEcho output

proc runLinux(release = false, flags: seq[string]) =
  let pkgInfo = getPkgInfo()
  var cmd = baseCmd(@["nimble"], release, flags)
  let finalCMD = cmd.concat(@["run", pkgInfo.name]).join(" ")
  debugEcho finalCMD
  let (output, exitCode) = execCmdEx(finalCMD)
  debugEcho output

proc getAppDir(target: string, release: bool): string =
  let pkgInfo = getPkgInfo()
  let pwd = getCurrentDir()
  let buildDir = pwd / "build" / target
  let subDir = if release: "Release" else: "Debug"
  result = buildDir / subDir
  if target == "macos":
    result = result / pkgInfo.name & ".app"

proc buildWindows(app_logo: string, release = false, flags: seq[string]): string {.discardable.} =
  let pwd: string = getCurrentDir()
  let pkgInfo = getPkgInfo()
  let buildDir = pwd / "build" / "windows"
  let subDir = if release: "Release" else: "Debug"
  let appDir = buildDir / subDir
  removeDir(buildDir)
  createDir(appDir)
  let logoExists = fileExists(app_logo)
  var icoPath: string
  if logoExists:
    let png = zopflipng.loadPNG32(app_logo)
    let tempDir = getTempDir()
    let images = genImages(png, @(ico.REQUIRED_IMAGE_SIZES))
    icoPath = generateICO(images.filterIt(it != default(ImageInfo)), tempDir)
    discard images.mapIt(tryRemoveFile(it.filePath))
  var myflags: seq[string]
  when not defined(windows):
    myflags.add "-d:mingw"
  var cmd = baseCmd(@["nimble", "build", "--silent", "-y"], release,
      myflags.concat flags)
  # for windres
  # if logoExists:
  #   let (output, exitCode, resPath) = callWindres(icoPath)
  #   discard cmd.concat @[&"--passL:{resPath}"]
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

proc buildLinux(app_logo: string, release = false, format = "deb", flags: seq[string]) =
  let pwd: string = getCurrentDir()
  let pkgInfo = getPkgInfo()
  let buildDir = pwd / "build" / "linux"
  let subDir = if release: "Release" else: "Debug"
  removeDir(buildDir)
  var appDir = buildDir / subDir
  # if format == "appimage":
  #   appDir = appDir / pkgInfo.name & ".AppDir"
  createDir(appDir)
  createLinuxTree(appDir)
  var cmd = baseCmd(@["nimble", "build", "--silent", "-y"], release, flags)
  let finalCMD = cmd.join(" ")
  debugEcho finalCMD
  let (o, e) = execCmdEx(finalCMD)
  if e == 0:
    debugEcho o
    let exePath = pwd / pkgInfo.name
    moveFile(exePath, appDir / pkgInfo.name)
  else:
    quit o

proc packAppImage(release = false, app_logo: string, metaInfo: MetaInfo) =
  let pwd: string = getCurrentDir()
  let pkgInfo = getPkgInfo()
  let buildDir = pwd / "build" / "linux"
  let subDir = if release: "Release" else: "Debug"
  let appDir = buildDir / subDir / pkgInfo.name & ".AppDir"
  # removeDir(appDir)
  # createDir(appDir)
  createAppImageTree(appDir)
  moveFile(buildDir / subDir / pkgInfo.name, appDir / "usr" / "bin" / pkgInfo.name)
  let logoExists = fileExists(app_logo)
  let iconDir = appDir / "usr" / "share" / "icons" / "hicolor" / "48x48" / "apps"
  createDir iconDir
  copyFile(app_logo, iconDir / pkgInfo.name & ".png")
  let metaInfo = getMetaInfo()
  let desktop = getDesktop(pkgInfo, metaInfo,"appimage")
  let desktopPath = appDir / "usr" / "share" / "applications" / pkgInfo.name & ".desktop"
  writeFile(desktopPath, desktop)

  # appimage-builder stuffs below
  if not fileExists(appDir / "AppRun"):
    let run = getAppRun(pkgInfo)
    writeFile(appDir / "AppRun", run)
    inclFilePermissions(appDir / "AppRun", {fpUserExec, fpGroupExec, fpOthersExec})
  # let img = loadImage[ColorRGBU](app_logo)
  # let img2 = img.resizedBicubic(256, 256)
  # img2.savePNG(appDir / ".DirIcon")
  # let tempDir = getTempDir()
  # writeBuildConfig(pkgInfo, tempDir)
  # let recipe = tempDir / AppImageBuilderConfName
  # let cmd = fmt"appimage-builder --recipe {recipe} --appdir {appDir}"
  # debugEcho cmd
  # let (output, exitCode) = execCmdEx(cmd)
  # debugEcho output
  # let (output2, exitCode2) = execCmdEx(fmt"ARCH=x86_64 appimagetool {appDir}")
  # quit(exitCode2)
  let cmd = fmt"linuxdeployqt {appDir}/usr/share/applications/initium.desktop -appimage"
  debugEcho cmd
  let (output, exitCode) = execCmdEx(cmd)
  debugEcho output

const Perm755 = {fpUserExec, fpUserWrite, fpUserRead, 
                          fpGroupExec, fpGroupRead, 
                          fpOthersExec, fpOthersRead}

proc convertLineEndings(filename: string, dest: string) =
  var lines: seq[string]
  var content: string
  content = readFile(filename)
  lines = content.splitLines()
  content = lines.join("\n")
  writeFile(dest, content)

proc packLinux(release:bool, icon: string) =
  let pkgInfo = getPkgInfo()
  let appDir = getAppDir("linux", release)
  createDebianTree(appDir)
  moveFile(appDir / pkgInfo.name, appDir / "usr" / "bin" / pkgInfo.name)
  copyFile(icon, appDir / "usr" / "share" / "icons" / pkgInfo.name & ".png")
  let metaInfo = getMetaInfo()
  let desktop = getDesktop(pkgInfo, metaInfo)
  let desktopPath = appDir / "usr" / "share" / "applications" / pkgInfo.name & ".desktop"
  writeFile(desktopPath, desktop)
  let exes = findExes(appDir)
  for exe in exes:
    inclFilePermissions(exe, {fpUserExec, fpGroupExec, fpOthersExec})
  const DebScripts = ["preinst", "postinst", "prerm", "postrm"]
  for script in DebScripts:
    if fileExists("nimpacker" / "debian" / script):
      # copyFile("nimpacker" / "debian" / script, appDir / "debian" / script)
      convertLineEndings("nimpacker" / "debian" / script, appDir / "debian" / script)
      # inclFilePermissions(appDir / "debian" / script, {fpUserExec, fpGroupExec, fpOthersExec})
      setFilePermissions(appDir / "debian" / script, Perm755)
      
  let baseControl = getControlBasic(pkgInfo, metaInfo)
  writeFile(appDir / "debian" / "control", baseControl)
  setFilePermissions(appDir / "debian" / "control", Perm755)
  let oldPWD = getCurrentDir()
  setCurrentDir(appDir)
  let deps = collectDeps(exes)
  setCurrentDir(oldPWD)
  let size = getDirectorySize(appDir)
  let sizeInKb = size div 1024
  let controlContent = getControl(pkgInfo, metaInfo, deps, sizeInKb)
  writeFile(appDir / "debian" / "control", controlContent)
  setFilePermissions(appDir / "debian" / "control", Perm755)
  let cmd = fmt"dpkg-deb --build {appDir} dist"
  let (output, exitCode) = execCmdEx(cmd)
  debugEcho output
  quit(exitCode)

proc postScript(post_build: string, target: string, release: bool, appDir = "") =
  if post_build.len > 0 and fileExists(post_build):
    let appDir = if appDir.len == 0: getAppDir(target, release) else: appDir
    let cmd = fmt"""nim e --hints:off -d:APP_DIR="{appDir}" {post_build}"""
    let (output, exitCode) = execCmdEx(cmd, options = {poUsePath, poStdErrToStdOut})
    debugEcho output

proc build(target: string, icon = "logo.png",
    post_build = "nimpacker" / "post_build.nims",
    release = false, flags: seq[string]): int =
  let metaInfo = getMetaInfo()
  case target:
    of "macos":
      buildMacos(icon, release, metaInfo, flags)
    of "windows":
      buildWindows(icon, release, flags)
    of "linux":
      buildLinux(icon, release, "deb", flags)
    else:
      discard

  postScript(post_build, target, release)

proc run(target: string, release = false, flags: seq[string]): int =
  case target:
    of "macos":
      runMacos(release, flags)
    of "windows":
      runWindows(release, flags)
    of "linux":
      runLinux(release, flags)
    else:
      discard

proc packWindows(release:bool, icoPath: string, metaInfo: MetaInfo) =
  let pkgInfo = getPkgInfo()
  let appDir = getAppDir("windows", release)
  let appId = metaInfo.appId
  if appId.len == 0:
    quit(fmt"Variable `appId` in {DefaultMetaPath} SHOULD NOT be empty, The `appId` is a GUID used in Inno Setup to uniquely identify an application during the installation process.")
  let script = getInnoSetupScript(pkgInfo, appDir, icoPath, metaInfo)
  let tempDir = getTempDir()
  let issPath = tempDir / pkgInfo.name & ".iss"
  writeFile(issPath, script)
  let isccPath = findExe("ISCC")
  let (installCmd, sudo) = foreignDepInstallCmd("InnoSetup")
  if isccPath.len == 0:
    quit("ISCC.exe not found, please ensure it's in `Path` environment variable or install it via `" & installCmd & "`")
  let cmd = "ISCC.exe /V1 " & issPath
  let (output, exitCode) = execCmdEx(cmd, options = {poUsePath, poStdErrToStdOut})
  var found = false
  for line in output.splitLines():
    if not found and line.startsWith("Compiler engine version"):
      found = true
    if found == true and not line.startsWith("Parsing"):
      debugEcho line
  if not found:
    debugEcho output

proc packMacos(release:bool, metaInfo: MetaInfo) =
  let pkgInfo = getPkgInfo()
  let appDir = getAppDir("macos", release)
  let cmd = getCreateDmg(pkgInfo, metaInfo, appDir)
  debugEcho cmd
  let (output, exitCode) = execCmdEx(cmd, options = {poUsePath, poStdErrToStdOut})
  debugEcho output

proc pack(target: string, icon = "logo.png",
    post_build =  "nimpacker" / "post_build.nims",
    release = false, format = "", flags: seq[string]): int =
  let metaInfo = getMetaInfo()
  case target:
    of "macos":
      buildMacos(icon, release, metaInfo, flags)
      postScript(post_build, target, release)
      packMacos(release, metaInfo)
    of "windows":
      let icoPath = buildWindows(icon, release, flags)
      postScript(post_build, target, release)
      packWindows(release, icoPath, metaInfo)
    of "linux":
      if format == "":
        let appDir = getAppDir("linux", release)
        removeDir(appDir)
        buildLinux(icon, release, format, flags)
        createDebianTree(appDir)
        postScript(post_build, target, release)
        packLinux(release, icon)
      elif format == "appimage":
        let baseDir = getAppDir("linux", release)
        let pkgInfo = getPkgInfo()
        let appDir = baseDir / pkgInfo.name & ".AppDir"
        removeDir(appDir)
        buildLinux(icon, release, format, flags)
        createAppImageTree(appDir)
        postScript(post_build, target, release, appDir)
        packAppImage(release, icon, metaInfo)
    else:
      discard

proc installLinuxdeployqt() =
  block download:
    const url = "https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage"
    let (output, exitCode) = execCmdEx("curl -L -o linuxdeployqt-continuous-x86_64.AppImage " & url)
    debugEcho output
  block cp:
    let (output, exitCode) = execCmdEx("sudo cp linuxdeployqt-continuous-x86_64.AppImage /usr/local/bin/linuxdeployqt")
    debugEcho output
  block chmod:
    let (output, exitCode) = execCmdEx("chmod +X /usr/local/bin/linuxdeployqt")
    debugEcho output

proc install(pkg: string) =
  ## install `create-dmg`,`dpkg-dev`, `linuxdeployqt` or `InnoSetup`
  if pkg == "linuxdeployqt":
    installLinuxdeployqt()
    return
  var pkg1: string
  for item in ["create-dmg", "dpkg-dev", "InnoSetup"]:
    if cmpIgnoreCase(pkg, item) == 0:
      pkg1 = "create-dmg"
  if pkg1.len == 0:
    quit("unknown package")
  let (cmd, sudo) = foreignDepInstallCmd($pkg)

  when defined(windows):
    let cmd1 = fmt"powershell.exe Start-Process -FilePath 'powershell' -Verb runAs -ArgumentList 'choco','install', '{$pkg}'"
    let (output, exitCode) = execCmdEx(cmd1, options = {poEchoCmd, poUsePath, poEvalCommand}, input="Y")
    debugEcho output
    quit(exitCode)
  else:
    let sudoCmd = if sudo:
      fmt"sudo {cmd}"
    else:
      cmd
    let (output, exitCode) = execCmdEx(sudoCmd, options = {poEchoCmd, poUsePath})
    debugEcho output
    quit(exitCode)

dispatchMulti([build], [run], [pack], [install])
