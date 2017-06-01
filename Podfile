# Uncomment this line to define a global platform for your project
platform :ios, '9.0'

target 'Relisten' do
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  inhibit_all_warnings!

  pod 'Siesta/Core'
  pod 'Siesta/UI'
  # pod 'AGAudioPlayer', :path => '../AGAudioPlayer'
  pod 'SwiftyJSON'
  pod 'Cache', :git => 'https://github.com/hyperoslo/Cache.git'
  pod 'Firebase/Database'
  pod 'Firebase/RemoteConfig'
  pod 'Firebase/DynamicLinks'
  pod 'Firebase/Core'
  pod 'Firebase/Messaging'
  pod "DownloadButton"
  pod 'ReachabilitySwift', '~> 3'
  pod 'LayoutKit'
  pod 'DWURecyclingAlert'
  pod 'SINQ'
  pod 'AXRatingView'
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

end
