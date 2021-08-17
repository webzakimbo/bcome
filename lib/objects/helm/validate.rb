module Bcome::Helm::Validate

  REQUIRED_HELM_MAJOR_VERSION="3".freeze
  HELM_BINARY="helm".freeze

  def validate
    validate_node
    validate_env
  end

  def is_collection?
    @node.is_a?(::Bcome::Node::K8Cluster::Collection::Base)
  end

  def is_namespace?
    @node.is_a?(Bcome::Node::K8Cluster::Namespace)
  end

  private

  def validate_node
    raise ::Bcome::Exception::Generic, "Node type #{@node.class} is not enabled for Helm contextual wrapping." unless is_collection? || is_namespace? 
  end

  def validate_env
    ::Bcome::EnsureBinary.do(HELM_BINARY)
    ensure_version
  end

  def ensure_version
    get_version_command = "#{HELM_BINARY} version"
    raw_version = ::Bcome::Command::Local.run(get_version_command) 

    unless raw_version.is_success?
      raise ::Bcome::Exception::Generic, "Could not determine helm version with command '#{get_version_command}'"
    end

    raw_version.stdout =~ /Version:"(v[0-9]+.[0-9]+.[0-9]+)"/
    version = $1

#    raise ::Bcome::Exception::Generic, "Could not find compatible Helm version. 3.x.x is required" unless version
 
#    unless version =~ /v#{REQUIRED_HELM_MAJOR_VERSION}.[0-9]+.[0-9]+/
#      raise ::Bcome::Exception::Generic, "Error: Helm integration requires Helm version v3.x.x, found '#{version}'"
#    end
  end
end
