# Uncomment this line to define a global platform for your project
platform :ios, '11.0'

def apply_pods
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  inhibit_all_warnings!

  pod 'PathKit'
  pod 'AXRatingView'
  pod 'ActionKit'
  pod 'CWStatusBarNotification'
  pod 'Cache'
  pod 'ChameleonFramework'
  pod 'CleanroomLogger', :git => "https://github.com/farktronix/CleanroomLogger"
  pod 'Crashlytics'
  pod 'CSwiftV', :git => "https://github.com/UberJason/CSwiftV.git" # Needed for RealmConverter until PR https://github.com/Daniel1of1/CSwiftV/pull/38 is accepted
  pod 'DownloadButton', :git => "https://github.com/farktronix/DownloadButton"
  pod 'EDColor'
  pod 'Fabric'
  pod 'FastImageCache', :git => "https://github.com/mallorypaine/FastImageCache.git"
  pod 'KASlideShow'
  pod 'LayoutKit'
  pod 'LastFm', :git => "https://github.com/farktronix/LastFm.git"
  pod 'LicensesViewController', :git => "https://github.com/tsukisa/LicenseGenerator-iOS.git"
  pod 'MZDownloadManager', :git => "https://github.com/alecgorge/MZDownloadManager.git"
  pod 'NAKPlaybackIndicatorView'
  pod 'NapySlider'
  pod 'Observable', :git => "https://github.com/alecgorge/Observable.git"
  pod 'PinpointKit'
  pod 'PinpointKit/ScreenshotDetector'
  pod 'RealmSwift'
  pod 'RealmConverter', :git => "https://github.com/farktronix/realm-cocoa-converter.git"
  pod 'SDCloudUserDefaults'
  pod 'SINQ'
  pod 'SVProgressHUD'
  pod 'Siesta/Core', :git => 'https://github.com/bustoutsolutions/siesta.git'
  pod 'Siesta/UI', :git => 'https://github.com/bustoutsolutions/siesta.git'
  pod 'SwiftyJSON'
  pod 'Texture'
 
  # Development pods (checked out locally)
  if ENV['TRAVIS']
      pod 'BASSGaplessAudioPlayer', :path => 'TravisPods/BASSGaplessAudioPlayer'
      pod 'AGAudioPlayer', :path => 'TravisPods/AGAudioPlayer'
      pod 'FaveButton', :path => 'TravisPods/fave-button'
  else
      pod 'BASSGaplessAudioPlayer', :path => '../BASSGaplessAudioPlayer'
      pod 'AGAudioPlayer', :path => '../AGAudioPlayer'
      pod 'FaveButton', :path => '../fave-button'
  end

  # Debug Pods
  pod 'Reveal-SDK', :configurations => ['Debug']
  pod 'Wormholy', :configurations => ['Debug']
  pod 'DWURecyclingAlert', :configurations => ['Debug']

  # Currently unused pods (but they might be used in the future)
  # pod 'AsyncSwift'
  # pod 'BFNavigationBarDrawer'
  # pod 'Reachability'
  # pod 'SpinnerView'

end

target 'RelistenShared' do
  apply_pods
end

target 'PhishOD' do
  apply_pods
end

target 'PhishODUITests' do 
  apply_pods
end

target 'Relisten' do
  apply_pods
end

target 'RelistenUITests' do
  apply_pods
  pod 'SimulatorStatusMagic'
end

target 'RelistenScreenshots' do
  apply_pods
  pod 'SimulatorStatusMagic'
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
