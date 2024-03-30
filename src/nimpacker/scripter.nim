import os
import nimscripter, nimscripter/[variables, vmops], puppy, webby
import ./packageinfo

exportTo(myImpl, DocumentTypeRole)
exportTo(myImpl, DocumentType)
exportTo(myImpl, PrivilegesRequired)
addVariable(myImpl, productName, string)
addVariable(myImpl, appId, string)
addVariable(myImpl, fileAssociations, seq[DocumentType])
addVariable(myImpl, maintainer, string)
addVariable(myImpl, homepage, string)
addVariable(myImpl, linuxCategories, seq[string])
addVariable(myImpl, linuxDepends, seq[string])
addVariable(myImpl, runAsAdmin, bool)
addVariable(myImpl, privilegesRequired, PrivilegesRequired)
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

proc httpFetch(url: string, headers: seq[(string, string)] = @[]): string =
  fetch(url, headers)

proc httpPost(url: string, headers: seq[(string, string)] = @[], body: sink string = "", timeout: float32 = 60): Response =
  post(url, headers, body, timeout)

proc httpPut(url: string, headers: seq[(string, string)] = @[], body: sink string = "", timeout: float32 = 60): Response =
  put(url, headers, body, timeout)

proc httpPatch(url: string, headers: seq[(string, string)] = @[], body: sink string = "", timeout: float32 = 60): Response =
  patch(url, headers, body, timeout)

proc httpDelete(url: string, headers: seq[(string, string)] = @[], timeout: float32 = 60): Response =
  delete(url, headers, timeout)

proc httpHead(url: string, headers: seq[(string, string)] = @[], timeout: float32 = 60): Response =
  head(url, headers, timeout)

exportTo(myImpl, httpFetch)
exportTo(myImpl, httpGet)
exportTo(myImpl, httpPost)
exportTo(myImpl, httpPut)
exportTo(myImpl, httpPatch)
exportTo(myImpl, httpDelete)
exportTo(myImpl, httpHead)

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
    let linuxCategories = intr.getGlobalVariable[:seq[string]]("linuxCategories")
    let linuxDepends = intr.getGlobalVariable[:seq[string]]("linuxDepends")
    let runAsAdmin = intr.getGlobalVariable[:bool]("runAsAdmin")
    let privilegesRequired = intr.getGlobalVariable[:PrivilegesRequired]("privilegesRequired")
    result.productName = productName
    result.appId = appId
    result.fileAssociations = fileAssociations
    result.maintainer = maintainer
    result.homepage = homepage
    result.linuxCategories = linuxCategories
    result.linuxDepends = linuxDepends
    result.runAsAdmin = runAsAdmin
    result.privilegesRequired= privilegesRequired

proc exec*(path: string) =
  if fileExists(path):
    let ourScript = NimScriptFile(readFile(path))
    let intr = loadScript(ourScript, scriptProcs)
