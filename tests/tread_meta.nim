import os
import nimpacker/read_meta


let path =  currentSourcePath.parentDir / "meta.nims"
let metaInfo = getMetaInfo(path)

doAssert metaInfo.productName == "NimPacker"
doAssert metaInfo.fileAssociations.len > 0