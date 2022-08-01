#
# Be sure to run `pod lib lint azbouki.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'azbouki'
  s.version          = '0.1.0'
  s.summary          = 'A short description of azbouki.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/tdermendjiev/azbouki'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'tdermendjiev' => 'tdermendjievft@gmail.com' }
  s.source           = { :git => 'https://github.com/tdermendjiev/azbouki.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '11.0'

  s.source_files = 'azbouki/Classes/**/*'
  
  # s.resource_bundles = {
  #   'azbouki' => ['azbouki/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  
  s.static_framework = true
  s.dependency 'Firebase'#, '~> 8.10.0'
  s.dependency 'Firebase/Auth'
  s.dependency 'Firebase/Database'
  s.dependency 'Firebase/Storage'
  s.dependency 'Firebase/Firestore'
  s.dependency 'Sentry'
  s.dependency 'FirebaseFirestoreSwift'#, '8.3.0-beta'
end
