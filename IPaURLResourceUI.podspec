Pod::Spec.new do |s|
  s.name             = 'IPaURLResourceUI'
  s.version          = '1.0'
  s.summary          = 'Easy API tools to auto parse result to JSON'
  s.homepage         = 'https://github.com/ipapamagic/IPaURLResourceUI'
  s.license          = 'MIT'
  s.author           = { 'IPaPa' => 'ipapamagic@gmail.com' }
  s.source           = { :git => 'https://github.com/ipapamagic/IPaURLResourceUI.git', :tag => 'v1.0'}

  s.platform         = :ios, "7.0"
  s.requires_arc     = true

  s.source_files = '*.swift'
  s.dependency 'IPaLog'
end
