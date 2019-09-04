#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'flutter_webview_plugin'
  s.version          = '0.0.1'
  s.summary          = 'A new flutter plugin project.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'https://github.com/dart-flitter/flutter_webview_plugin'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'AlibcTradeSDK'
  s.dependency 'AliAuthSDK'
  s.dependency 'mtopSDK'
  s.dependency 'securityGuard'
  s.dependency 'AliLinkPartnerSDK'
  s.dependency 'BCUserTrack'
  s.dependency 'UTDID'
  s.dependency 'AlipaySDK'


  s.static_framework = true
  
  s.ios.deployment_target = '8.0'
end

