# Uncomment this line to define a global platform for your project
platform :ios, '14.0'

def apply_pods
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  inhibit_all_warnings!

  pod 'AXRatingView'
  pod 'ActionKit'
  pod 'CWStatusBarNotification'
  pod 'Cache'
  pod 'ChameleonFramework', :git => "https://github.com/farktronix/Chameleon.git" # https://github.com/viccalexander/Chameleon/pull/234
  pod 'CleanroomLogger', :git => "https://github.com/farktronix/CleanroomLogger" # Needed because the authors refuse to add CocoaPods support https://github.com/emaloney/CleanroomLogger/issues/69
  pod 'Crashlytics'
  pod 'CSwiftV'
  pod 'DownloadButton', :git => "https://github.com/farktronix/DownloadButton" # Temporary fork to fix a progress over/underflow bug
  pod 'EDColor'
  pod 'Fabric'
  pod 'FastImageCache', :git => "https://github.com/mallorypaine/FastImageCache.git" # The new official fork
  pod 'FaveButton', :git => "https://github.com/farktronix/fave-button.git" # Waiting on https://github.com/xhamr/fave-button/pull/42
  pod 'google-cast-sdk'
  pod 'KASlideShow'
  pod 'LastFm', :git => "https://github.com/farktronix/LastFm.git" # Waiting on https://github.com/gangverk/LastFm/pull/20
  pod 'LicensesViewController', :git => "https://github.com/tsukisa/LicenseGenerator-iOS.git"
  pod 'MZDownloadManager', :git => 'https://github.com/farktronix/MZDownloadManager' # Waiting on https://github.com/mzeeshanid/MZDownloadManager/pull/81
  pod 'NAKPlaybackIndicatorView'
  pod 'NapySlider'
  pod 'Observable', :git => 'https://github.com/farktronix/Observable.git'
  pod 'PathKit'
  pod 'PinpointKit'
  pod 'PinpointKit/ScreenshotDetector'
  pod 'Realm' 
  pod 'RealmSwift' 
  pod 'RealmConverter', :git => "https://github.com/farktronix/realm-cocoa-converter.git" # https://github.com/realm/realm-cocoa-converter/pull/56
  pod 'SDCloudUserDefaults'
  pod 'SINQ'
  pod 'SVProgressHUD'
  pod 'Siesta/Core'
  pod 'Siesta/UI'
  pod 'SwiftyJSON'
  pod 'DZNEmptyDataSet'
  pod 'SQLite.swift'
  
  pod 'Texture/Core'
  pod 'Texture/MapKit'
 
  # Development pods (checked out locally)
  if ENV['CI']
      pod 'BASSGaplessAudioPlayer', :path => 'CIPods/BASSGaplessAudioPlayer'
      pod 'AGAudioPlayer', :path => 'CIPods/AGAudioPlayer'
  else
      pod 'BASSGaplessAudioPlayer', :path => '../BASSGaplessAudioPlayer'
      pod 'AGAudioPlayer', :path => '../AGAudioPlayer'
  end

  # Debug Pods
  pod 'Reveal-SDK', :configurations => ['Debug']
  pod 'Wormholy', :configurations => ['Debug']
  pod 'DWURecyclingAlert', :configurations => ['Debug']

end

target 'RelistenShared' do
  apply_pods
end

target 'Relisten for Phish' do
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
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64' # https://github.com/realm/realm-cocoa/issues/6685
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
    end
  end
end
