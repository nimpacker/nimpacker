import os, nimscripter, nimscripter/[variables, vmops]
import ./packageinfo

exportTo(myImpl, DocumentTypeRole)
exportTo(myImpl, DocumentType)
addVariable(myImpl, productName, string)
addVariable(myImpl, appId, string)
addVariable(myImpl, fileAssociations, seq[DocumentType])
addVmops(myImpl)

const
  scriptProcs = implNimScriptModule(myImpl)
  DefaultMetaPath* = "nimpacker" / "meta.nims"

proc getMetaInfo*(metaPath = DefaultMetaPath): MetaInfo =
  echo metaPath
  if fileExists(metaPath):
    let ourScript = NimScriptFile(readFile(metaPath))
    let intr = loadScript(ourScript, scriptProcs)
    let productName = intr.getGlobalVariable[:string]("productName")
    let appId = intr.getGlobalVariable[:string]("appId")
    let fileAssociations = intr.getGlobalVariable[:seq[DocumentType]]("fileAssociations")
    result = MetaInfo(productName: productName, appId: appId, fileAssociations: fileAssociations)