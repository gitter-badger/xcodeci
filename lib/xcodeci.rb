module Xcodeci
  require 'colorize'
  require 'yaml'
  require 'ipa_reader'
  require 'open-uri'

  autoload :Command,        'xcodeci/command'
  autoload :Database,       'xcodeci/database'
  autoload :GitUtils,       'xcodeci/gitutils'
  autoload :BuildUtils,     'xcodeci/buildutils'
  autoload :ArchiveUtils,   'xcodeci/archiveUtils'
  autoload :Logger,         'xcodeci/logger'
  autoload :HtmlReporter,   'xcodeci/html_reporter'
  autoload :Configuration,   'xcodeci/configuration'

  HOME     = File.join(Dir.home, ".xcodeci")
  TEMPLATE = File.expand_path("../../templates/", __FILE__)

end