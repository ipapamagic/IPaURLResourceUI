#
# Be sure to run `pod lib lint IPaURLResourceUI.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'IPaURLResourceUI'
  s.version          = '6.0.0'
  s.summary          = 'A short description of IPaURLResourceUI.'
  s.swift_version    = '6.0'
  s.ios.deployment_target = '11.0'
  s.watchos.deployment_target = '6.0'
# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/ipapamagic/IPaURLResourceUI'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ipapamagic@gmail.com' => 'ipapamagic@gmail.com' }
  s.source           = { :git => 'https://github.com/ipapamagic/IPaURLResourceUI.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.source_files = 'Sources/IPaURLResourceUI/**/*'
  
  # s.resource_bundles = {
  #   'IPaURLResourceUI' => ['IPaURLResourceUI/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'


    s.dependency 'IPaLog' ,'~> 3.1.0'
    
    s.dependency 'IPaXMLSection' , '~> 2.2.0'
  

end
