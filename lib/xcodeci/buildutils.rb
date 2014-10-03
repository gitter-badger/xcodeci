module Xcodeci
  class BuildUtils
    
    def install_pod
      %x(pod install)
      $?.exitstatus.zero?
    end

    def run_build(repository_url, workspace, scheme)
      %x(xcodebuild -configuration Release -workspace \"#{workspace}\" -scheme \"#{scheme}\" -sdk iphoneos clean build 2>&1)
      $?.exitstatus.zero?
    end
    
    def run_test(repository_name, workspace, scheme)
        %x(xcodebuild -configuration Release -workspace \"#{workspace}\" -scheme \"#{scheme}\"  -sdk iphonesimulator8.0 -arch i386 clean test)
        # %x(xctool -configuration Release -workspace \"#{workspace}\" -scheme \"#{scheme}\" -sdk iphonesimulator test > /dev/null)
        $?.exitstatus.zero?
    end
  end
end
