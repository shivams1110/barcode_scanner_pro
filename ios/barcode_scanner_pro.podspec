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
                       DESC
  s.homepage         = 'https://github.com/karnival/barcode_scanner_pro'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.frameworks = 'AVFoundation', 'Vision', 'CoreMedia', 'CoreVideo', 'CoreImage', 'UIKit'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'barcode_scanner_pro_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
