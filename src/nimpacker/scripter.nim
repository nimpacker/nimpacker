import os
import nimscripter, nimscripter/[variables, vmops], puppy, webby
import ./packageinfo

exportTo(myImpl, DocumentTypeRole)
exportTo(myImpl, DocumentType)
addVariable(myImpl, productName, string)
addVariable(myImpl, appId, string)
addVariable(myImpl, fileAssociations, seq[DocumentType])
addVariable(myImpl, maintainer, string)
addVariable(myImpl, homepage, string)

# exportTo(myImpl, webby.QueryParams)
# exportTo(myImpl, webby.Url)
exportTo(myImpl, webby.HttpHeaders)
# exportTo(myImpl, webby.toWebby)
# exportTo(myImpl, webby.toBase)

# exportTo(myImpl, puppy.Request)
exportTo(myImpl, puppy.Response)
# exportTo(myImpl, puppy.PuppyError)
# exportTo(myImpl, puppy.Header)

proc writeFile(name, content: string) =
  syncio.writeFile(name, content)

exportTo(myImpl, emptyHttpHeaders)
exportTo(myImpl, writeFile)

proc httpGet(url: string, headers: seq[(string, string)] = @[], timeout: float32 = 60): Response =
  get(url, headers, timeout)

# exportTo(myImpl, puppy.fetch)
exportTo(myImpl, httpGet)
# exportTo(myImpl, puppy.post)
# exportTo(myImpl, puppy.put)
# exportTo(myImpl, puppy.patch)
# exportTo(myImpl, puppy.delete)
# exportTo(myImpl, puppy.head)

addVmops(myImpl)

const
  scriptProcs = implNimScriptModule(myImpl)
  DefaultMetaPath* = "nimpacker" / "meta.nims"

proc getMetaInfo*(metaPath = DefaultMetaPath): MetaInfo =
  result = new MetaInfo
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

proc exec*(path: string) =
  if fileExists(path):
    let ourScript = NimScriptFile(readFile(path))
    let intr = loadScript(ourScript, scriptProcs)