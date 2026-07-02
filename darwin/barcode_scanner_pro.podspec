#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint barcode_scanner_pro.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'barcode_scanner_pro'
  s.version          = '0.0.1'
  s.summary          = 'High-performance offline barcode scanner (AVFoundation + Vision).'
  s.description      = <<-DESC
A production-grade Flutter barcode scanner plugin using AVFoundation capture and
the Vision framework for fully on-device, offline barcode detection. No third-party SDKs.
Shared Darwin sources support both iOS and macOS.
                       DESC
  s.homepage         = 'https://github.com/umda/barcode_scanner_pro'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'barcode_scanner_pro/Sources/barcode_scanner_pro/**/*.swift'
  s.resource_bundles = {'barcode_scanner_pro_privacy' => ['barcode_scanner_pro/Sources/barcode_scanner_pro/PrivacyInfo.xcprivacy']}

  # Per-platform Flutter dependency + deployment targets.
  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'
  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'

  # System frameworks shared across both platforms, plus the UI framework each needs.
  s.frameworks = 'AVFoundation', 'Vision', 'CoreMedia', 'CoreVideo', 'CoreImage'
  s.ios.frameworks = 'UIKit'
  s.osx.frameworks = 'AppKit'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
