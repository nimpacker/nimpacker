import os
import nimscripter, nimscripter/[variables,vmops]
import puppy, webby

exportTo(myImpl, webby.QueryParams)
exportTo(myImpl, webby.Url)
exportTo(myImpl, webby.HttpHeaders)
# exportTo(myImpl, webby.toWebby)
# exportTo(myImpl, webby.toBase)

exportTo(myImpl, puppy.Request)
exportTo(myImpl, puppy.Response)
exportTo(myImpl, puppy.PuppyError)
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

# let path =  currentSourcePath.parentDir / "http.nims"
# let ourScript = NimScriptFile(readFile(path))
# let intr = loadScript(ourScript, scriptProcs)
