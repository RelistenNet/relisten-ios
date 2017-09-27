# Uncomment this line to define a global platform for your project
platform :ios, '10.0'

target 'Relisten' do
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  inhibit_all_warnings!

  pod 'Siesta/Core', :git => 'https://github.com/bustoutsolutions/siesta.git'
  pod 'Siesta/UI', :git => 'https://github.com/bustoutsolutions/siesta.git'
  pod 'SwiftyJSON'
  pod 'Cache', '3.3.0'
  pod 'ReachabilitySwift', '~> 3'
  pod 'ActionKit', '~> 2.0'

  pod 'NapySlider', :path => '../NapySlider'
  pod 'BASSGaplessAudioPlayer', :path => '../gapless-audio-bass-ios'
  pod 'AGAudioPlayer', :path => '../AGAudioPlayer'

# pod 'Firebase/Database'
# pod 'Firebase/Auth'
# pod 'Firebase/RemoteConfig'
# pod 'Firebase/DynamicLinks'
# pod 'Firebase/Core'
# pod 'Firebase/Messaging'

  pod "DownloadButton"
  pod 'AXRatingView'
  pod 'FaveButton', :path => '../fave-button'
  pod 'NAKPlaybackIndicatorView'

  pod 'LayoutKit'
  pod 'DWURecyclingAlert'

  pod 'SINQ'
  pod 'Reveal-SDK', :configurations => ['Debug']

  # pod 'BFNavigationBarDrawer'
  target 'PhishOD' do
  	inherit! :search_paths

  	target 'PhishODUITests' do 
  		inherit! :search_paths
  	end
  end

  target 'RelistenUITests' do
    inherit! :search_paths
    # Pods for testing
  end

  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['ENABLE_BITCODE'] = 'NO'
      end
    end
  end
end
