
type PackageInfo* = ref object
  name*: string
  version*: string
  author*: string
  desc*: string
  license*: string
  srcDir*: string
  bin*: seq[string]

type DocumentTypeRole* = enum
  None = "None"
  Editor = "Editor"
  Viewer = "Viewer"
  Shell = "Shell"

type HandlerRank* = enum
  Default = "Default"
  Owner = "Owner"
  Alternate = "Alternate"
  None = "None"

type DocumentType* = ref object
  name*: string
  exts*: seq[string]
  mimes*: seq[string]
  role*: DocumentTypeRole
  rank*: HandlerRank
  utis*: seq[string]
  iconFile*: string

type TagSpec* = ref object
  # mime*: string
  exts*: seq[string]

type ExportedTypeDeclaration* = ref object
  identifier*: string
  referenceURL*: string
  description*: string
  iconFile*: string
  conformsTo*: seq[string]
  tagSpec*: TagSpec

type PrivilegesRequired* = enum
  admin = "admin"
  lowest = "lowest"

type ExecutionLevel* = enum
  asInvoker = "asInvoker"
  requireAdministrator = "requireAdministrator"
  highestAvailable = "highestAvailable"

type MetaInfo* = ref object
  productName*: string
  appId*: string
  bundleIdentifier*: string
  fileAssociations*: seq[DocumentType]
  maintainer*: string # deb Maintainer
  homepage*: string # deb and exe Homepage
  linuxCategories*: seq[string]
  linuxDepends*: seq[string]
  privilegesRequired*: PrivilegesRequired
  runAsAdmin*: bool
  executionLevel*: ExecutionLevel
  exportedTypeDeclarations*: seq[ExportedTypeDeclaration]
  macosCategory*: string
  appUsesNonExemptEncryption*: bool
  supportedPlatforms*: seq[string]
  copyright*: string
  minimumSystemVersion*: string