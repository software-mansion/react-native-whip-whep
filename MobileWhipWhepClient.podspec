Pod::Spec.new do |s|
  s.name             = 'MobileWhipWhepClient'
  s.version          = '0.6.0'
  s.summary          = 'WHIP/WHEP SDK for iOS.'

  s.author           = { 'Software Mansion' => 'https://swmansion.com' }
  s.source           = { git: 'https://github.com/software-mansion/react-native-whip-whep' }
  s.ios.deployment_target = '15.1'
  s.swift_version = '5.0'

  s.source_files = 'packages/ios-client/Sources/**/*'
  s.homepage         = 'https://github.com/software-mansion/react-native-whip-whep/'
  s.license          = { :type => 'Apache-2.0 license', :file => 'packages/ios-client/LICENSE' }
  s.author           = { 'Software Mansion' => 'https://swmansion.com' }
  s.source           = { :git => 'https://github.com/software-mansion/react-native-whip-whep.git', :tag => s.version.to_s }
  s.pod_target_xcconfig = { 'ENABLE_BITCODE' => 'NO' }

  s.dependency 'WebRTC-SDK', '=125.6422.06'
  s.dependency 'SwiftLogJellyfish', '1.5.2'
  s.dependency 'SwiftProtobuf', '~> 1.18.0'

  # Broadcast subspec for screen sharing extension
  s.subspec 'Broadcast' do |broadcast|
    broadcast.source_files = [
      'packages/ios-client/Sources/ios-client/Media/BroadcastSampleSource.swift',
      'packages/ios-client/Sources/ios-client/ipc/**/*',
      'packages/ios-client/Sources/ios-client/proto/**/*',
      'packages/ios-client/Sources/ios-client/utils/**/*'
    ]
    broadcast.dependency 'WebRTC-SDK', '=125.6422.06'
    broadcast.dependency 'SwiftProtobuf', '~> 1.18.0'
  end

end
