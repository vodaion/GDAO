source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '11.0'
use_frameworks!

target 'GDAOTests' do
    pod 'CwlCatchException', :git => 'https://github.com/mattgallagher/CwlCatchException.git'
    pod 'CwlPreconditionTesting', :git => 'https://github.com/mattgallagher/CwlPreconditionTesting.git'
end

post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '4.2'
    end
  end
