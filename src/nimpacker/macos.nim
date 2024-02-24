import std/[os, strformat]
import ./packageinfo

proc getCreateDmg*(pkgInfo: PackageInfo, metaInfo: MetaInfo, appDir: string):string =
  let productName = metaInfo.productName
  let name = if productName.len > 0: productName else: pkgInfo.name
  let outputPath = fmt"dist/{name}-Installer.dmg"
  if fileExists(outputPath):
    removeFile(outputPath)
  result = fmt"""
  create-dmg \
  --volname "{name} Installer" \
  --volicon "{appDir}/Contents/Resources/app.icns" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "{appDir.lastPathPart}" 200 190 \
  --hide-extension "{appDir.lastPathPart}" \
  --app-drop-link 600 185 \
  "{outputPath}" \
  "{appDir}"
  """
