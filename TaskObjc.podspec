#
# Be sure to run `pod lib lint TaskObjc.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'TaskObjc'
  s.version          = '0.1.0'
  s.summary          = '基于NSOperation的任务管理工具'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC

  Task extends the functionality of NSOperation by adding conditions and observers. Its use is similar but slightly different than NSOperation. Instead of overriding start() and main() subclasses should override execute() and call finish() when the code has finished. `finish() `must be called whether the task completed successfully or in an error state. As long as these methods are called, all other state is managed automatically.

  Conditions are added to an task to establish criteria required in order for the task to successfully run. For example a task that required location data could add a condition that made sure access had been granted to location services. Observers are added to a task and can react to the starting and ending of a task. For example an observer could start and stop an activity indicator while the task is executing.
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

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
