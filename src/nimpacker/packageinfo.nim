type PackageInfo* = object
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

type DocumentType* = object
  exts*: seq[string]
  mimes*: seq[string]
  role*: DocumentTypeRole
  utis*: seq[string]

type MetaInfo* = object
  productName*: string
  appId*: string
  fileAssociations*: seq[DocumentType]