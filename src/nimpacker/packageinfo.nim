type PackageInfo* = ref object
  name*: string
  version*: string
  author*: string
  desc*: string
  license*: string

type DocumentTypeRole* = enum
  None = "None"
  Editor = "Editor"
  Viewer = "Viewer"
  Shell = "Shell"

type DocumentType* = ref object
  exts*: seq[string]
  mimes*: seq[string]
  role*: DocumentTypeRole
  utis*: seq[string]

type MetaInfo* = ref object
  productName*: string
  appId*: string
  fileAssociations*: seq[DocumentType]
  maintainer*: string # deb Maintainer
  homepage*: string # deb and exe Homepage
  linuxCategories*: seq[string]
