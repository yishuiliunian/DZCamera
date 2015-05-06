#
# Be sure to run `pod lib lint DZCamera.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "DZCamera"
  s.version          = "0.1.0"
  s.summary          = "DZCamera基于AVFoundation的拍照组件，界面易于扩展和自定义"
  s.description      = <<-DESC
                        DZCamera基于AVFoundation的拍照组件，界面易于扩展和自定义。是否从设计那里拿来了设计稿，结果发现相机的界面和系统的完全不一样，基于ImagePicker来改造界面也非常啰嗦。那么可以试一下DZCamera。
                        This a project in progress。
                        目前版本已经完成了相机的基本功能，还有一些细节需要调节一下。

                       DESC
  s.homepage         = "https://github.com/yishuiliunian/DZCamera"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "stonedong" => "yishuiliunian@gmail.com" }
  s.source           = { :git => "https://github.com/yishuiliunian/DZCamera.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'DZCamera' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'DZGeometryTools'
  s.dependency 'DZCache'
  s.dependency 'GPUImage'
end
