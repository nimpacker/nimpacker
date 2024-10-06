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
    CFBundleTypeName: string # must be non empty when upload appstore
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
    # Xcode generates this key automatically when you build a bundle and you should not change it manually. The value for this key is currently 6.0.
    # see: https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html#//apple_ref/doc/uid/20001431-102088
    CFBundleInfoDictionaryVersion: string  
    # For macOS apps, make sure that you set the copyright key in the information property list before you upload your app to App Store Connect.
    # see: https://help.apple.com/xcode/mac/current/#/dev91fe7130a
    NSHumanReadableCopyright?: string
    CFBundleExecutable: string
    CFBundleIdentifier?:string
    CFBundlePackageType ?: string
    NSAppTransportSecurity ?: NSAppTransportSecurity
    NSHighResolutionCapable ?: bool
    CFBundleIconName ?: string
    CFBundleDocumentTypes ?: DocumentType[]
    UTExportedTypeDeclarations ?: UTExportedTypeDeclaration[]
