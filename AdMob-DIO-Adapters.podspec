#
# Be sure to run `pod lib lint AdMob-DIO-Adapters.podspec' to ensure this is a
# valid spec before submitting.
#

Pod::Spec.new do |s|
    s.name             = 'AdMob-DIO-Adapters'
    s.version          = '2.7.0'
    s.summary          = 'DIO Adapters for mediating through AdMob.'
    s.homepage         = 'https://www.display.io/'
    s.license          = { :type => 'Apache-2.0', :file => 'LICENSE' }
    s.author           = { 'Ariel Malka' => 'arielm@display.io' }
    s.source           = { :git => "https://github.com/displayio/AdMob-DIO-Adapters-iOS.git", :tag => "#{s.version}"}
    s.ios.deployment_target = '10.0'
    s.pod_target_xcconfig = { 'VALID_ARCHS' => 'arm64 x86_64' }
    s.static_framework = true
    s.subspec 'AdMob' do |ms|
       ms.dependency 'Google-Mobile-Ads-SDK'
    end
    s.subspec 'Network' do |ns|
        ns.source_files = 'Classes/*.{h,m}'
        ns.dependency 'DIOSDK', '2.7.0'
        ns.dependency 'Google-Mobile-Ads-SDK'
    end
end
