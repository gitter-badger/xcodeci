module Xcodeci
  class ArchiveUtils
    
    def archive_ipa(workspace, scheme, path)      
      build_dir = %x(xctool -configuration Release -workspace "#{workspace}" -scheme "#{scheme}" -sdk iphoneos -showBuildSettings | grep -m1 TARGET_BUILD_DIR | cut -d'=' -f2 | xargs | tr -d '\n')
      app_name  = %x(xctool -configuration Release -workspace "#{workspace}" -scheme "#{scheme}" -sdk iphoneos -showBuildSettings | grep -m1 WRAPPER_NAME     | cut -d'=' -f2 | xargs | tr -d '\n')

      %x( xcrun -sdk iphoneos PackageApplication -v "#{build_dir}/#{app_name}" -o "#{path}" )#--sign "#{SIGN_COMPANY_NAME}" )#--embed "#{PROVISIONING_PATH}")
      $?.exitstatus.zero?
    end

    def save_dsym(workspace, scheme, path)
        build_dir = %x(xctool -configuration Release -workspace "#{workspace}" -scheme "#{scheme}" -sdk iphoneos -showBuildSettings | grep -m1 TARGET_BUILD_DIR | cut -d'=' -f2 | xargs | tr -d '\n')
        app_name  = %x(xctool -configuration Release -workspace "#{workspace}" -scheme "#{scheme}" -sdk iphoneos -showBuildSettings | grep -m1 WRAPPER_NAME     | cut -d'=' -f2 | xargs | tr -d '\n')
        result = 0
        begin
          FileUtils.cp_r "#{build_dir}/#{app_name}.dSYM", path , :verbose => false
        rescue => e
          result = 1
        end
        result.zero?
    end
  end
end