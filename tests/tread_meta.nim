import os
import nimpacker/scripter


let path =  currentSourcePath.parentDir / "meta.nims"
let metaInfo = getMetaInfo(path)

doAssert metaInfo.productName == "NimPacker"
doAssert metaInfo.fileAssociations.len > 0
doAssert metaInfo.homepage == "https://nim-lang.org"
