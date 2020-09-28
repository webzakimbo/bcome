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
        paths: [".gauth",".aws"],
       method: :create_as_directory
      }
    ]
  end
end
