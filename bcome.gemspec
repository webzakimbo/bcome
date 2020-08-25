# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'objects/bcome/version'

Gem::Specification.new do |spec|
  spec.name          = ::Bcome::Version.name
  spec.version       = ::Bcome::Version.release
  spec.authors       = ['Webzakimbo']
  spec.email         = ['guillaume@webzakimbo.com']
  spec.summary       = "Bcome is dev-ops application-development framework"
  spec.description   = "Bcome lets you create your own management application on top of your infrastructure - wherever it may be - all driven from simple YAML configuration. On-premise, cloud, hybrid & multi-cloud. Amazon EC2 & GCP integration with more clouds coming."
  spec.homepage      = 'https://bcome.com'
  spec.metadata = {
    'documentation_uri' => 'https://docs.bcome.com',
    'homepage_uri' => 'https://bcome.com',
    'source_code_uri' => 'https://github.com/webzakimbo/bcome'
  }
  spec.license = 'WBZ'
  spec.files = Dir.glob('{bin,lib,filters,patches}/**/*')
  spec.bindir = 'bin'
  spec.executables = ['bcome']
  spec.require_paths = ['lib']
  spec.add_dependency 'activesupport', '5.2.4.3'
  spec.add_dependency 'awesome_print', '1.8.0'
  spec.add_dependency 'diffy', '3.1.0'
  spec.add_dependency 'fog-aws', '~> 0.12.0'
  spec.add_dependency 'google-api-client', '0.29.1'
  spec.add_dependency 'launchy', '2.4.3'
  spec.add_dependency 'net-scp', '~> 1.2', '>= 1.2.1'
  spec.add_dependency 'net-ssh', '4.1.0'
  spec.add_dependency 'pmap', '1.1.1'
  spec.add_dependency 'pry', '0.12.2'
  spec.add_dependency 'rainbow', '~> 2.2'
  spec.add_dependency 'require_all', '1.3.3'
  spec.add_dependency 'strings-ansi', '0.2.0'
  spec.add_dependency 'tty-cursor', '0.2.0'
  spec.post_install_message = "\nWelcome to BCOME\n\nSee our documentation page at https://docs.bcome.com for what's new and for breaking changes in 2.0.0"
end
