module Xcodeci
  class Configuration
    def initialize path
      @database = YAML.load_file(path)
    end

    def each_project
      @database.each {|key, value|
        yield(value) unless key == "App_Config"
      }
    end
    def is_ok?
      not @database.nil?  and not @database.empty?
    end

    def app_config
      @database['App_Config']
    end

  end
end