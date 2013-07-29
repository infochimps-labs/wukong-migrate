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
    Wukong-migrate, inspired by rails, makes updating database schemas and settings painless and straightforward.

    Utilizing your app's models and the settings discovered by Wukong-deploy, only a simple migrate script is required
    to be able to make changes to databases. Keep your databases in sync with your app code more cleanly and with less
    effort.
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

