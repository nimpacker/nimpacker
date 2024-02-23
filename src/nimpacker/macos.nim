import std/[os, strformat]
import ./packageinfo

proc getCreateDmg*(pkgInfo: PackageInfo, appDir: string):string =
  let name = pkgInfo.name
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
  "dist/{name}-Installer.dmg" \
  "{appDir}"
  """
