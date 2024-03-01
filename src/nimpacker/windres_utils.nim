import std/[os, osproc, strformat]

proc callWindres*(icoPath: string): tuple[output: string, exitCode: int, resPath: string] =
  let content = &"id ICON \"{icoPath}\""
  let rc = getTempDir() / "my.rc"
  writeFile(rc, content)
  let resPath = getTempDir() / "my.res"
  let resCmd = &"windres {rc} -O coff -o {resPath}"
  let (output, exitCode) = execCmdEx(resCmd)
  result = (output, exitCode, resPath)
