#
# Be sure to run `pod lib lint TaskObjc.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'TaskObjc'
  s.version          = '0.1.2'
  s.summary          = '基于NSOperation的任务管理工具'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!
# git@github.com:xtxh/TaskObjc.git
# https://github.com/xtxh/TaskObjc.git
  s.description      = <<-DESC
  继承于NSOperation，通过添加条件[condition]和观察者[observer]来扩展的任务管理工具。
                       DESC

  s.homepage         = 'https://github.com/xtxh/TaskObjc.git'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'xtxh' => 'xtxh@outlook.com' }
  s.source           = { :git => 'git@github.com:xtxh/TaskObjc.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'TaskObjc/Classes/**/*'
  
  # s.resource_bundles = {
  #   'TaskObjc' => ['TaskObjc/Assets/*.png']
  # }

   s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
