# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'xcodeci/version'

Gem::Specification.new do |spec|
	spec.name          = "hola_ignazioc"
	spec.version       = Xcodeci::VERSION
	spec.authors       = ["Ignazio Calò"]
	spec.email         = ["ignazioc@gmail.com"]
	spec.summary       = %q{This gem it's only a test.}
	spec.description   = %q{This gem it's only a test, please don't use it.}
	spec.homepage      = ""
	spec.license       = "MIT"

	spec.files         = `git ls-files -z`.split("\x0")
	spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
	spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
	spec.require_paths = ["lib"]

	spec.add_development_dependency "bundler", "~> 1.6"
	spec.add_development_dependency "rspec"
	spec.add_development_dependency "rake"
	spec.add_runtime_dependency "colorize"
	spec.add_runtime_dependency "cocoapods"
	spec.add_runtime_dependency "ipa_reader"
end
