# Uncomment the next line to define a global platform for your project
platform :ios, '8.0'

target 'MapPoints' do
  use_frameworks!

  # Pods for MapPoints
  pod 'Firebase/Core'
  pod 'Firebase/Database'
  pod 'GeoFire', :git => 'https://github.com/firebase/geofire-objc.git'
end

# see more https://github.com/firebase/geofire-objc/issues/48
post_install do |installer|
    installer.pods_project.targets.each do |target|
        if target.name == 'GeoFire' then
            target.build_configurations.each do |config|
                config.build_settings['FRAMEWORK_SEARCH_PATHS'] = "#{config.build_settings['FRAMEWORK_SEARCH_PATHS']} ${PODS_ROOT}/FirebaseDatabase/Frameworks/ $PODS_CONFIGURATION_BUILD_DIR/GoogleToolboxForMac"
                config.build_settings['OTHER_LDFLAGS'] = "#{config.build_settings['OTHER_LDFLAGS']} -framework FirebaseDatabase"
            end
        end
    end
end
