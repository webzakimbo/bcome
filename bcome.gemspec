# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'objects/bcome/version'

Gem::Specification.new do |spec|
  spec.name          = ::Bcome::Version.name
  spec.version       = ::Bcome::Version.release
  spec.authors       = ['Webzakimbo']
  spec.email         = ['info@webzakimbo.com']
  spec.summary       = 'The DevOps Control Panel Framework'
  spec.description   = 'Generate custom management interfaces from simple configuration and Ruby code. On-premise, cloud, hybrid & multi-cloud. Amazon AWS (EC2) & Google Cloud (GCP) integration with more cloud providers coming. Fully extensible. Free for commercial and non-commercial use.'
  spec.homepage      = 'https://bcome.com'
  spec.metadata = {
    'documentation_uri' => 'https://docs.bcome.com/en/2.0.0',
    'homepage_uri' => 'https://bcome.com',
    'source_code_uri' => 'https://github.com/webzakimbo/bcome'
  }
  spec.license = 'Nonstandard'
  spec.files = Dir.glob('{bin,lib,filters,patches}/**/*')
  spec.bindir = 'bin'
  spec.required_ruby_version = '>= 2.5.0'
  spec.executables = %w[bcome]
  spec.require_paths = ['lib']
  spec.add_dependency 'readline', '0.0.3'
  spec.add_dependency 'reline', '0.3.0'
  spec.add_dependency 'psych', '3.2.0' # Last stable version before safe_load was broken
  spec.add_dependency 'activesupport', '5.2.4.3'
  spec.add_dependency 'diffy', "3.4.1"
  spec.add_dependency 'fog-aws', '~> 0.12.0'
  spec.add_dependency 'google-api-client', '0.53.0'
  spec.add_dependency 'google-cloud-container', '1.1.2'
  spec.add_dependency 'launchy', '2.4.3'
  spec.add_dependency 'net-scp', '~> 1.2', '>= 1.2.1'
  spec.add_dependency 'net-ssh', '6.1.0'
  spec.add_dependency 'pmap', '1.1.1'
  spec.add_dependency 'pry', '0.14.1'
  spec.add_dependency 'rainbow', '~> 2.2'
  spec.add_dependency 'require_all', '1.3.3'
  spec.add_dependency 'strings-ansi', '0.2.0'
  spec.add_dependency 'tty-cursor', '0.2.0'
  spec.add_dependency 'jsonpath', '1.0.5'
  spec.add_dependency 'awesome_print', '1.9.2'
  spec.add_dependency 'cronex', '0.11.1'
  spec.post_install_message = <<-END

  Welcome to Bcome, the DevOps Control Panel Framework

  Version 3.0.0 introduces Kubernetes drivers for GCP GKE & Amazon's EKS. 

  Visit our new documentation site here: https://docs.bcome.com/en/3.0.0

  See implementation demos at our guides site: https://guides.bcome.com/en/3.0.0

  For full release notes see: https://github.com/webzakimbo/bcome/releases/tag/3.0.0

END
end
