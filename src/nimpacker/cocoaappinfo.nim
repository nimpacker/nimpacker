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
    # Deprecated in OS X v10.5
    CFBundleTypeExtensions?:string[]
    # Deprecated in OS X v10.5
    CFBundleTypeMIMETypes?:string[]
    LSItemContentTypes?:string[] # https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html#//apple_ref/doc/uid/TP40009249-SW7
    # Editor, Viewer, Shell, or None
    CFBundleTypeRole?:string
  CocoaAppInfo:
    CFBundleDisplayName: string
    CFBundleVersion: string
    CFBundleExecutable: string
    CFBundleIdentifier?:string
    CFBundlePackageType ?: string
    NSAppTransportSecurity ?: NSAppTransportSecurity
    NSHighResolutionCapable ?: bool
    CFBundleIconName ?: string
    CFBundleDocumentTypes ?: DocumentType[]
