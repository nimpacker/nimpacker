import os
import nimscripter, nimscripter/[variables, vmops], puppy, webby
import ./packageinfo

exportTo(myImpl, DocumentTypeRole)
exportTo(myImpl, HandlerRank)
exportTo(myImpl, DocumentType)
exportTo(myImpl, PrivilegesRequired)
exportTo(myImpl, ExecutionLevel)
exportTo(myImpl, TagSpec)
exportTo(myImpl, ExportedTypeDeclaration)

addVariable(myImpl, productName, string)
addVariable(myImpl, appId, string)
addVariable(myImpl, bundleIdentifier, string)
addVariable(myImpl, appUsesNonExemptEncryption, bool)

addVariable(myImpl, fileAssociations, seq[DocumentType])
addVariable(myImpl, exportedTypeDeclarations, seq[ExportedTypeDeclaration])
addVariable(myImpl, maintainer, string)
addVariable(myImpl, homepage, string)
addVariable(myImpl, linuxCategories, seq[string])
addVariable(myImpl, macosCategory, string)
addVariable(myImpl, linuxDepends, seq[string])
addVariable(myImpl, runAsAdmin, bool)
addVariable(myImpl, privilegesRequired, PrivilegesRequired)
addVariable(myImpl, executionLevel, ExecutionLevel)
exportTo(myImpl, webby.HttpHeaders)
exportTo(myImpl, puppy.Response)

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
    let bundleIdentifier = intr.getGlobalVariable[:string]("bundleIdentifier")
    let fileAssociations = intr.getGlobalVariable[:seq[DocumentType]]("fileAssociations")
    let exportedTypeDeclarations = intr.getGlobalVariable[:seq[ExportedTypeDeclaration]]("exportedTypeDeclarations")
    var maintainer = intr.getGlobalVariable[:string]("maintainer")
    if maintainer.len == 0: maintainer = "YOUR NAME <EMAIL>"
    let homepage = intr.getGlobalVariable[:string]("homepage")
    let linuxCategories = intr.getGlobalVariable[:seq[string]]("linuxCategories")
    let linuxDepends = intr.getGlobalVariable[:seq[string]]("linuxDepends")
    let runAsAdmin = intr.getGlobalVariable[:bool]("runAsAdmin")
    let privilegesRequired = intr.getGlobalVariable[:PrivilegesRequired]("privilegesRequired")
    let executionLevel = intr.getGlobalVariable[:ExecutionLevel]("executionLevel")
    let macosCategory = intr.getGlobalVariable[:string]("macosCategory")
    let appUsesNonExemptEncryption = intr.getGlobalVariable[:bool]("appUsesNonExemptEncryption")
    result.productName = productName
    result.appId = appId
    result.bundleIdentifier = bundleIdentifier
    result.fileAssociations = fileAssociations
    result.exportedTypeDeclarations = exportedTypeDeclarations
    result.maintainer = maintainer
    result.homepage = homepage
    result.linuxCategories = linuxCategories
    result.linuxDepends = linuxDepends
    result.runAsAdmin = runAsAdmin
    result.privilegesRequired = privilegesRequired
    result.executionLevel = executionLevel
    result.macosCategory = macosCategory
    result.appUsesNonExemptEncryption = appUsesNonExemptEncryption

proc exec*(path: string) =
  if fileExists(path):
    let ourScript = NimScriptFile(readFile(path))
    let intr = loadScript(ourScript, scriptProcs)
