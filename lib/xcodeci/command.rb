module Xcodeci
  class Command
    def self.root_output_folder
      File.join(@@dropbox_folder, "xcodeci")
    end

    def self.workspace_folder repo_url, prj_workspace
      folder_name = repo_url[repo_url.rindex('/') + 1..-1].sub('.git', '')
      folder_name = File.join(Xcodeci::HOME, folder_name)
      path = Dir.glob("#{folder_name}/**/#{prj_workspace}").first
      File.dirname(path)
    end

    def self.execute_in_workspace_folder (repository_url, workspace ,&block)
      Dir.chdir workspace_folder repository_url, workspace
      result = block.call
      Dir.chdir "#{Xcodeci::HOME}"
      result
    end

    def self.repository_name repo_url
      repo_url[repo_url.rindex('/') + 1..-1].sub('.git', '')
    end

    def self.execute_in_repo_folder (repository_url, &block)
      Dir.chdir "#{Xcodeci::HOME}/#{repository_name repository_url}"
      result = block.call
      Dir.chdir "#{Xcodeci::HOME}"
      result
    end


    def self.run
      # Create the folder for storing all the projects
      unless File.exists?(Xcodeci::HOME)
        Dir.mkdir File.join(Xcodeci::HOME) 
        FileUtils.cp_r File.join(Xcodeci::TEMPLATE, "xcodeci.conf.yaml"), File.join(Xcodeci::HOME, "xcodeci.conf.yaml") , :verbose => false
        puts "A sample configuration file was created on your ~/.xcodeci folder.".red
        exit 0
      end

      configuration = Configuration.new ( File.join(Xcodeci::HOME, "xcodeci.conf.yaml") )
      unless configuration.is_ok? 
        puts "Your configuration file is doesn't contain any project.".red
        exit(1)
      end

      @@dropbox_folder  = configuration.app_config[:DROPBOX_FOLDER]
      @@dropbox_user_id = configuration.app_config[:DROPBOX_USER_ID]


      database      = Database.new ( File.join(Xcodeci::HOME, "data.yaml") )
      gitUtils      = GitUtils.new
      buildUtils    = BuildUtils.new
      archiveUtils  = ArchiveUtils.new
      l             = Logger.new

      

      #TODO check if the configuration is ok
      puts "=== Start Loop ==="

      configuration.each_project do | project |
        puts "=== Start #{project[:APP_NAME]} ==="
        
        # Create the dropbox shared folder
        output_folder = File.join(root_output_folder, project[:APP_NAME])
        FileUtils.mkdir_p(output_folder) unless File.exists?(output_folder)

        # Cloning the repository
        puts "> Cloning the repository #{project[:REPO_URL]}"
        clone_result = gitUtils.cloning_repo project[:REPO_URL]
        puts l.log_result clone_result, "Repository clone"

        # Checkout, fetch and pull
        puts "> Updating the repository"

        last_commits = []
        execute_in_repo_folder(project[:REPO_URL]) {
          #Fetch the new commits
          fetch_result = gitUtils.fetch_repo
          puts l.log_result fetch_result, "Repository fetch"

          # Checkout the target branch
          checkout_result = gitUtils.checkout_repo project[:TARGET_BRANCH]
          puts l.log_result checkout_result, "Repository checkout"

          # Pull the repository
          pull_result = gitUtils.pull_repo
          puts l.log_result pull_result, "Repository pull"
        
          # Get list of the five most recent commits
          puts "> Getting list of commits"
          last_commits = gitUtils.get_commit_lists
          puts l.log_result true, "Found #{last_commits.length} commit(s)"
        }
        

        # Iterate on each commit to build
        last_commits.each do |commit_line|
          commit, email = commit_line.split(' ')

          puts "> Commit #{commit}"
          unless database.should_build_commit( project[:APP_NAME], commit)
            puts l.log_result false, "Commit #{commit} skipped"
            next
          end

          # Checkout del repository al commit specifico
          puts "> Rollaback repo to #{commit}"
          execute_in_repo_folder(project[:REPO_URL]) {
            rollback_result = gitUtils.rollback_repo commit
            puts l.log_result rollback_result, "Rollback"
          }
          

          # Run "Pod install" on the repository
          puts "> Updating dependencies"
          execute_in_workspace_folder(project[:REPO_URL], project[:WORKSPACE] ) {
            pod_result = buildUtils.install_pod
            puts l.log_result pod_result, "Pod installed"
          }
          



          # BUILD
          puts "> Build"
          build_result = false
          execute_in_workspace_folder(project[:REPO_URL], project[:WORKSPACE] ) {
            build_result = buildUtils.run_build(project[:REPO_URL], project[:WORKSPACE], project[:SCHEME])
            puts l.log_result build_result, "Build"
          }
          

          unless build_result
            test_result   = false
            puts l.log_result false, "Unit tests skipped"

            ipa_result    = false
            puts l.log_result false, "IPA build skipped"

            dsym_result   = false
            puts l.log_result false, "dSym copy skipped"

          else
            # Create the folder for storing the ipa files and the dSym file.
            output_folder = File.join(root_output_folder , project[:APP_NAME], commit)
            FileUtils.mkdir_p(output_folder) unless File.exists?(output_folder)

            # Run unit test
            puts "> Test"
            execute_in_workspace_folder(project[:REPO_URL], project[:WORKSPACE] ) {
              test_result = buildUtils.run_test(project[:REPO_URL], project[:WORKSPACE], project[:SCHEME])
              puts l.log_result test_result, "Unit Test"
            }

            # Create ipa file
            puts "> Archiving"
            execute_in_workspace_folder(project[:REPO_URL], project[:WORKSPACE] ) {
              ipa_result = archiveUtils.archive_ipa(project[:WORKSPACE], project[:SCHEME], "#{output_folder}/app.ipa")
              puts l.log_result ipa_result, "Create Ipa"
            }
            

            # Copy dSym frile from the "derivedata" folder.
            execute_in_workspace_folder(project[:REPO_URL], project[:WORKSPACE] ) {
              dsym_result = archiveUtils.save_dsym(project[:WORKSPACE], project[:SCHEME], "#{output_folder}/")
              puts l.log_result dsym_result, "Copy dSym"
            }
            

            # Extract info from the ipa file
            ipa_file = IpaReader::IpaFile.new("#{output_folder}/app.ipa")
            bundle_identifier = ipa_file.bundle_identifier
            bundle_version     = ipa_file.version

            # Copy the manifest
            manifest_template_path = File.join(Xcodeci::TEMPLATE, 'manifest.plist')
            manifest_template = File.open(manifest_template_path, 'rb') { |f| f.read }
            link = URI::encode("https://dl.dropboxusercontent.com/u/#{@@dropbox_user_id}/xcodeci/#{project[:APP_NAME]}/#{commit}/app.ipa")
            manifest_template.gsub!('__IPA_URL_PLACEHOLDER__', link)
            manifest_template.gsub!('__BUNDLE_IDENTIFIER_PLACEHOLDER__', bundle_identifier)
            manifest_template.gsub!('__VERSION_PLACEHOLDER__', bundle_version)
            manifest_template.gsub!("__APP_NAME_PLACEHOLDER__", project[:APP_NAME])


            output = File.join(root_output_folder, project[:APP_NAME],commit,'manifest.plist')
            File.open(output, 'w') { |file| file.write(manifest_template) }

          end
          commit_report = {
            build: build_result,
            test: test_result,
            ipa: ipa_result,
            dSym: dsym_result,
            author: email,
            date: Time.now
          }

          database.store_result project[:APP_NAME], commit, commit_report

        end # <- end loop commit
        puts "=== End #{project[:APP_NAME]} ==="
      end # <- End single project
      puts "=== End Loop ==="
      if (File.exists?(File.join(Xcodeci::HOME, "data.yaml")))
          # Create html report
          reporter = HtmlReporter.new File.join(Xcodeci::HOME, "data.yaml") , @@dropbox_user_id
          output = File.join(root_output_folder, 'index.html')
          File.open(output, 'w') { |file| file.write(reporter.html_report) }

          %x(open -a Safari #{output})
      end
      
    end # <- end run method
  end # <- end class
end # <- end module
