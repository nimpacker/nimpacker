import std/xmltree
export xmltree

import ./packageinfo

proc createAppMainifest*(execLevel: ExecutionLevel, uiAccess: bool): XmlNode =
  ## window application mainifest see https://learn.microsoft.com/en-us/windows/win32/sbscs/application-manifests
  var assembly = newElement("assembly")
  assembly.attrs = {"xmlns": "urn:schemas-microsoft-com:asm.v1", "manifestVersion": "1.0"}.toXmlAttributes
  var trustInfo = newElement("trustInfo")
  var security = newElement("security")
  var requestedPrivileges = newElement("requestedPrivileges")
  var requestedExecutionLevel = newElement("requestedExecutionLevel")
  requestedExecutionLevel.attrs = {"level": $execLevel, "uiAccess": $uiAccess }.toXmlAttributes

  requestedPrivileges.add requestedExecutionLevel
  security.add requestedPrivileges
  trustInfo.add security
  assembly.add trustInfo
  assembly

when isMainModule:
  let xml = createAppMainifest(ExecutionLevel.requireAdministrator, false)
  echo $xml