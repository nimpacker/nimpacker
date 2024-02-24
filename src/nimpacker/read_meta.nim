import os, nimscripter, nimscripter/[variables, vmops]
import ./packageinfo

addVariable(myImpl, productName, string)
addVariable(myImpl, appId, string)
addVmops(myImpl)

const
  scriptProcs = implNimScriptModule(myImpl)
  DefaultMetaPath* = "nimpacker" / "meta.nims"

proc getMetaInfo*(metaPath = DefaultMetaPath): MetaInfo =
  if fileExists(metaPath):
    let ourScript = NimScriptFile(readFile(metaPath))
    let intr = loadScript(ourScript, scriptProcs)
    let productName = intr.getGlobalVariable[:string]("productName")
    let appId = intr.getGlobalVariable[:string]("appId")
    result = MetaInfo(productName: productName, appId: appId)