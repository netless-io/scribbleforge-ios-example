Pod::Spec.new do |s|
  s.name             = 'ScribbleForge'
  s.version          = '0.1.35'
  s.license          = { :type => 'MIT', :text => 'Copyright netless 2024' }
  s.summary          = 'Interacetive whiteboard SDK.'
  s.description      = 'Next generation Interacetive whiteboard SDK.'
  s.homepage         = 'https://github.com/netless-io/scribble-forge-release'
  s.author           = { 'vince' => 'zjxuyunshi@gmail.com' }
  s.platform         = :ios, '11.0'
  s.swift_versions   = '5.0'
  s.source = {  :path => '/Users/vince/agora/ScribbleForge/ScribbleForge-iOS/Scripts/.build' }

  s.subspec 'Basic' do |s|
    s.vendored_frameworks = '/Users/vince/agora/ScribbleForge/ScribbleForge-iOS/Scripts/.build/ScribbleForge.xcframework'
    s.dependency 'NTLBridge', '3.2.0'
    s.dependency 'RxSwift'
  end

  s.subspec 'Basic-XCode13' do |s|
    s.vendored_frameworks = 'xcode13-build/ScribbleForge.xcframework'
    s.dependency 'NTLBridge'
    s.dependency 'RxSwift', '6.2.0'
  end

  s.subspec 'AgoraRtm2.1.x' do |s|
    s.dependency 'AgoraRtm_iOS', '~> 2.1.12'
    s.dependency 'ScribbleForge/Basic'
  end

  s.subspec 'AgoraRtmKit2.2.x' do |s|
    s.dependency 'AgoraRtm/RtmKit', '~> 2.2.2'
    s.dependency 'ScribbleForge/Basic'
  end

  s.subspec 'AgoraRtm2.2.x' do |s|
    s.dependency 'AgoraRtm', '~> 2.2.2'
    s.dependency 'ScribbleForge/Basic'
  end

  s.subspec 'AgoraSpecial' do |s|
    s.dependency 'AgoraRtm/RtmKit', '~> 2.2.2'
    s.dependency 'ScribbleForge/Basic-XCode13'
  end
 
  s.default_subspec = 'AgoraRtm2.1.x'
end
