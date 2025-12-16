base_content = File.read(File.join(__dir__, 'MobileWhipWhepClient.podspec'))

base_config = {
  homepage: base_content[/s\.homepage\s*=\s*['"]([^'"]+)['"]/, 1],
  license_type: base_content[/s\.license\s*=\s*\{[^}]*:type\s*=>\s*['"]([^'"]+)['"]/, 1],
  license_file: base_content[/s\.license\s*=\s*\{[^}]*:file\s*=>\s*['"]([^'"]+)['"]/, 1],
  author_name: base_content[/s\.author\s*=\s*\{\s*['"]([^'"]+)['"]/, 1],
  author_url: base_content[/s\.author\s*=\s*\{[^}]*['"][^'"]*['"]\s*=>\s*['"]([^'"]+)['"]/, 1],
  deployment_target: base_content[/s\.ios\.deployment_target\s*=\s*['"]([^'"]+)['"]/, 1],
  swift_version: base_content[/s\.swift_version\s*=\s*['"]([^'"]+)['"]/, 1],
  version: base_content[/s\.version\s*=\s*['"]([^'"]+)['"]/, 1],
  xcconfig_key: base_content[/s\.pod_target_xcconfig\s*=\s*\{\s*['"]([^'"]+)['"]/, 1],
  xcconfig_value: base_content[/s\.pod_target_xcconfig\s*=\s*\{[^}]*['"][^'"]*['"]\s*=>\s*['"]([^'"]+)['"]/, 1],
  webrtc_version: base_content[/s\.dependency\s+['"]WebRTC-SDK['"]\s*,\s*['"]([^'"]+)['"]/, 1],
  swift_protobuf_version: base_content[/s\.dependency\s+['"]SwiftProtobuf['"]\s*,\s*['"]([^'"]+)['"]/, 1],
  source: base_content[/s\.source\s*=\s*\{[^}]*:git\s*=>\s*['"]([^'"]+)['"]/, 1]
}

Pod::Spec.new do |s|
  s.name             = 'MobileWhipWhepBroadcastClient'
  s.version          = base_config[:version]
  s.summary          = 'WHIP/WHEP Broadcast Extension SDK for iOS screen sharing and broadcast functionality.'

  s.homepage         = base_config[:homepage]
  s.license          = { :type => base_config[:license_type], :file => base_config[:license_file] }
  s.author           = { base_config[:author_name] => base_config[:author_url] }
  s.source           = { :git => base_config[:source], :tag => s.version.to_s }

  s.ios.deployment_target = base_config[:deployment_target]
  s.swift_version = base_config[:swift_version]

  s.source_files = [
    'packages/ios-client/Sources/ios-client/Media/BroadcastSampleSource.swift',
    'packages/ios-client/Sources/ios-client/ipc/**/*'
  ]

  s.pod_target_xcconfig = { base_config[:xcconfig_key] => base_config[:xcconfig_value] }

  s.dependency 'WebRTC-SDK', base_config[:webrtc_version]
  s.dependency 'SwiftProtobuf', base_config[:swift_protobuf_version]
end
