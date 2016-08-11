# Uncomment this line to define a global platform for your project
platform :ios, '9.0'

target 'Relisten' do
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  pod 'Siesta', :git => 'https://github.com/bustoutsolutions/siesta.git'
  pod 'AGAudioPlayer', :path => '../AGAudioPlayer'
  pod 'ScrubberBar'
  pod 'Unbox'

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