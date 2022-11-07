module Bcome::Initialization::Structure
  def initialization_paths
    [
      { # Configuration directories
        paths: ['bcome', 'bcome/metadata', 'bcome/orchestration'],
        method: :create_as_directory
      },
      { # Configuration files
        paths: ['bcome/networks.yml', 'bcome/registry.yml'],
        method: :initialize_empty_yaml_config
      },
      { # Cloud provider authorisation directories
        paths: ['.gauth', '.aws', '.kubectl'],
        method: :create_as_directory
      },
      { # Pre-populated configuration
        paths: ['bcome/k8_hierarchy.yml','.gauth/googles-not-so-secret-client-secrets.json'],
        method: :set_prepopulated_configs
      }
    ]
  end
end
