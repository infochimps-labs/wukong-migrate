# -*- encoding: utf-8 -*-
require File.expand_path('../lib/wukong-migrate/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = 'wukong-migrate'
  gem.homepage    = 'https://github.com/infochimps-labs/wukong-migrate'
  gem.licenses    = ['Apache 2.0']
  gem.email       = 'coders@infochimps.com'
  gem.authors     = ['Travis Dempsey']
  gem.version     = Wukong::Migrate::VERSION

  gem.summary     = 'Wukong utility to push database schema changes based upon your defined models'
  gem.description = <<-DESC.gsub(/^ {4}/, '')
    wukong-migrate, inspired by rails, all up in yer deploy pack, pushing yer schema changes
  DESC

  gem.files         = `git ls-files`.split("\n")
  gem.executables   = ['wu-migrate']
  gem.test_files    = gem.files.grep(/^spec/)
  gem.require_paths = ['lib']

  gem.add_dependency('wukong-deploy', '>= 0.1.1')
  gem.add_dependency('gorillib',      '~> 0.5')
  gem.add_dependency('httparty',      '~> 0.11')
  gem.add_dependency('rake',          '>= 0.8.7')
end

