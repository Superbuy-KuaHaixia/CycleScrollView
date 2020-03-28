
Pod::Spec.new do |s|
  s.name         = "CycleScrollView"
  s.version      = "1.0.0"
  s.summary      = "Swift轮播图"
  s.homepage     = "https://github.com/woodtengfei/CycleScrollView"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "woodwu" => "woodtengfei@gmail.com" }
  s.swift_version = "5.0"
  s.swift_versions = ['5.0']
  s.platform     = :ios, "10.0"
  s.source       = { :git => "https://github.com/woodtengfei/CycleScrollView.git", :tag => "#{s.version}" }
  s.public_header_files = ["Lib/CycleScrollView.h"]
  s.source_files = ["Lib/**/*.{swift}", "Lib/CycleScrollView.h"]
  s.resource     = "Lib/CycleScrollView.bundle"
  s.dependency 'Kingfisher'
  s.requires_arc = true
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '5.0' }
end
