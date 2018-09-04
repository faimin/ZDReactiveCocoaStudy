# Uncomment the next line to define a global platform for your project
platform :ios, '8.0'

def usedPod
	pod 'ReactiveObjC'
	pod 'Masonry'
	pod 'AFNetworking'
	pod 'FDStackView'
end

inhibit_all_warnings!
target 'ReactiveCocoaDemo' do
  # Uncomment the next line if you're using Swift or would like to use dynamic frameworks
  # use_frameworks!

  # Pods for ReactiveCocoaDemo
  usedPod()

  target 'ReactiveCocoaDemoTests' do
    inherit! :search_paths
    # Pods for testing
  end

end



