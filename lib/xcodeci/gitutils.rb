module Xcodeci
  class GitUtils
    
    def repository_name repo_url
      repo_url[repo_url.rindex('/') + 1..-1].sub('.git', '')
    end
    # def execute_in_repo_folder (repository_url, &block)
    #   Dir.chdir "#{Xcodeci::HOME}/#{repository_name repository_url}"
    #   result = block.call
    #   Dir.chdir "#{Xcodeci::HOME}"
    #   result
    # end

    def cloning_repo repository_url
      #Cloning the repository, it fails if the repository is already cloned
      dest_folder = File.join(Xcodeci::HOME, (repository_name repository_url))
      clone_result = %x(git clone #{repository_url} #{dest_folder} 2>&1)
      $?.exitstatus.zero?
    end

    def fetch_repo
      %x(git fetch 2>&1)
      $?.exitstatus.zero?
    end

    def checkout_repo branch 
      %x(git checkout #{branch} 2>&1)
      $?.exitstatus.zero?
    end

    def pull_repo      
      %x(git pull 2>&1)
      $?.exitstatus.zero?
    end

    def get_commit_lists      
      last_commit = %x(git log  -1 --date-order --pretty=format:"%h %ce").split(/\n/)
      # a single line shoud be in this format  "e2d4a86 ignaziocgmail.com"
      last_commit
    end

    def rollback_repo commit
        %x(git checkout "#{commit}" 2>&1)
        $?.exitstatus.zero?
    end
    
  end
end