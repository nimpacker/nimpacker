import jsonschema
import json
import tables
import options
# https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/AboutInformationPropertyListFiles.html#//apple_ref/doc/uid/TP40009254-SW4

jsonSchema:
  Domain:
    NSIncludesSubdomains ?: bool
    NSExceptionAllowsInsecureHTTPLoads ?: bool
    NSExceptionMinimumTLSVersion ?: bool
    NSExceptionRequiresForwardSecrecy ?: bool
    NSRequiresCertificateTransparency ?: bool

  NSAppTransportSecurity:
    NSAllowsArbitraryLoads?:bool
    NSAllowsLocalNetworking?:bool
    NSExceptionDomains ?: any
  DocumentType:
    CFBundleTypeName: string
    # Deprecated in OS X v10.5
    CFBundleTypeExtensions?:string[]
    # Deprecated in OS X v10.5
    CFBundleTypeMIMETypes?:string[]
    LSItemContentTypes?:string[] # https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html#//apple_ref/doc/uid/TP40009249-SW7
    # Editor, Viewer, Shell, or None
    CFBundleTypeRole?:string
    LSHandlerRank?: string
    CFBundleTypeIconFile?: string
  # https://developer.apple.com/documentation/uniformtypeidentifiers/defining-file-and-data-types-for-your-app?language=objc
  UTTypeTagSpecification:
    "public.filename-extension": string[]
    # "public.mime-type": string
  # https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/understanding_utis/understand_utis_declare/understand_utis_declare.html
  UTExportedTypeDeclaration:
    UTTypeIdentifier: string
    UTTypeReferenceURL ?: string
    UTTypeDescription ?: string
    UTTypeIconFile ?: string
    UTTypeConformsTo ?: string[]
    UTTypeTagSpecification: any
  CocoaAppInfo:
    CFBundleDisplayName: string
    CFBundleName ?: string
    CFBundleVersion: string
    CFBundleShortVersionString: string # required for uploading .pkg to appstore
    LSApplicationCategoryType?: string # required for uploading .pkg to appstore
    ITSAppUsesNonExemptEncryption?: bool # required for uploading .pkg to appstore
    CFBundleSupportedPlatforms: string[] # required for uploading .pkg to appstore
    CFBundleExecutable: string
    CFBundleIdentifier?:string
    CFBundlePackageType ?: string
    NSAppTransportSecurity ?: NSAppTransportSecurity
    NSHighResolutionCapable ?: bool
    CFBundleIconName ?: string
    CFBundleDocumentTypes ?: DocumentType[]
    UTExportedTypeDeclarations ?: UTExportedTypeDeclaration[]
