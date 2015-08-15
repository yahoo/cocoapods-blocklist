# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-blacklist/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-blacklist'
  spec.version       = CocoapodsBlacklist::VERSION
  spec.authors       = ['David Grandinetti']
  spec.email         = ['dbgrandi@yahoo-inc.com']
  spec.description   = %q{Blacklist pods from your project.}
  spec.summary       = %q{A CocoaPods plugin used to check a project against a list of pods that you do not want included in your build. Security is the primary use, but keeping specific pods that have conflicting licenses is another possible use.}
  spec.homepage      = 'https://github.com/yahoo/cocoapods-blacklist'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
