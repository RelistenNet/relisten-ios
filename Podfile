# Uncomment this line to define a global platform for your project
platform :ios, '11.0'

def apply_pods
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  inhibit_all_warnings!

  pod 'Siesta/Core', :git => 'https://github.com/bustoutsolutions/siesta.git'
  pod 'Siesta/UI', :git => 'https://github.com/bustoutsolutions/siesta.git'
  pod 'SwiftyJSON'
  pod 'Cache'

  if ENV['TRAVIS']
      pod 'NapySlider', :path => 'TravisPods/NapySlider'
      pod 'BASSGaplessAudioPlayer', :path => 'TravisPods/BASSGaplessAudioPlayer'
      pod 'AGAudioPlayer', :path => 'TravisPods/AGAudioPlayer'
      pod 'FaveButton', :path => 'TravisPods/fave-button'
  else
      pod 'NapySlider', :path => '../NapySlider'
      pod 'BASSGaplessAudioPlayer', :path => '../BASSGaplessAudioPlayer'
      pod 'AGAudioPlayer', :path => '../AGAudioPlayer'
      pod 'FaveButton', :path => '../fave-button'
  end

# pod 'Firebase/Database'
# pod 'Firebase/Auth'
# pod 'Firebase/RemoteConfig'
# pod 'Firebase/DynamicLinks'
# pod 'Firebase' # To enable Firebase module, with `@import Firebase` support
# pod 'FirebaseCore', :git => 'https://github.com/firebase/firebase-ios-sdk.git', :tag => '5.0.0'
# pod 'FirebaseAuth', :git => 'https://github.com/firebase/firebase-ios-sdk.git', :tag => '5.0.0'
# pod 'FirebaseDatabase', :git => 'https://github.com/firebase/firebase-ios-sdk.git', :tag => '5.0.0'
# pod 'FirebaseFirestore', :git => 'https://github.com/firebase/firebase-ios-sdk.git', :tag => '5.0.0'
# pod 'Firebase/Messaging'
  pod 'RealmSwift'

  pod 'AXRatingView'
  pod 'NAKPlaybackIndicatorView'
  pod 'Observable', :git => "https://github.com/alecgorge/Observable.git"

  pod 'LayoutKit'
  pod "Texture"

  pod 'SINQ'
  pod 'KASlideShow'
  pod 'ChameleonFramework'
  pod 'EDColor'
  pod 'FastImageCache', :git => "https://github.com/mallorypaine/FastImageCache.git"
  
  pod "MZDownloadManager", :git => "https://github.com/alecgorge/MZDownloadManager.git"
  pod 'SVProgressHUD'
  pod 'ActionKit'
  pod 'DownloadButton'
  pod 'SDCloudUserDefaults'
 
  # Debug Pods
  pod 'Reveal-SDK', :configurations => ['Debug']
  pod 'Wormholy', :configurations => ['Debug'], :git => "https://github.com/pmusolino/Wormholy.git"
  pod 'DWURecyclingAlert', :configurations => ['Debug']

  # Currently unused pods (but they might be used in the future)
  # pod 'AsyncSwift'
  # pod 'BFNavigationBarDrawer'
  # pod 'CWStatusBarNotification'
  # pod 'Reachability'
  # pod 'SpinnerView'

  pod 'Fabric'
  pod 'Crashlytics'
end

target 'RelistenShared' do
  apply_pods
end

target 'PhishOD' do
  apply_pods

  target 'PhishODUITests' do 
    inherit! :search_paths
  end
end

target 'Relisten' do
  apply_pods

  target 'RelistenUITests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  # Added to work around https://github.com/TextureGroup/Texture/issues/969
  texture = installer.pods_project.targets.find { |target| target.name == 'Texture' }
  texture.build_configurations.each do |config|
    config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
  end

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
