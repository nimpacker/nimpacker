import os, nimscripter, nimscripter/[variables, vmops]
import ./packageinfo

exportTo(myImpl, DocumentTypeRole)
exportTo(myImpl, DocumentType)
addVariable(myImpl, productName, string)
addVariable(myImpl, appId, string)
addVariable(myImpl, fileAssociations, seq[DocumentType])
addVariable(myImpl, maintainer, string)
addVariable(myImpl, homepage, string)
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
    let fileAssociations = intr.getGlobalVariable[:seq[DocumentType]]("fileAssociations")
    var maintainer = intr.getGlobalVariable[:string]("maintainer")
    if maintainer.len == 0: maintainer = "YOUR NAME <EMAIL>"
    let homepage = intr.getGlobalVariable[:string]("homepage")
    result.productName = productName
    result.appId = appId
    result.fileAssociations = fileAssociations
    result.maintainer = maintainer
    result.homepage = homepage
