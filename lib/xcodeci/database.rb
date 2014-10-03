class Database
  require "yaml/store"
  
  def initialize (file_path = "data.yml")
    @store = YAML::Store.new(file_path)
  end

  def should_build_commit appname, commit_hash
    report = @store.transaction {
      commits = @store[appname]
      if commits.nil?
        nil
      else
        @store[appname][commit_hash]
      end
    }
    report.nil?
  end

  def store_result appname, commit_hash, result
    @store.transaction do
      @store[appname] ||= Hash.new
      @store[appname][commit_hash] = result
      @store.commit
    end
  end
end