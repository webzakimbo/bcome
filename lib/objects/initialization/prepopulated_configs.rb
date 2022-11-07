module Bcome::Initialization::PrepopulatedConfigs

  CONFIG_DIR="config"

  def prepopulated_path_contents(path)
    return config_contents[path.to_sym]
  end

  def current_directory
    File.dirname(__FILE__)
  end

  def config_contents
    {
      '.gauth/googles-not-so-secret-client-secrets.json': get_config_file_contents("googles-not-so-secret-client-secrets.json"),
      'bcome/k8_hierarchy.yml': get_config_file_contents("k8_hierarchy.yml")
    }
  end

  def get_config_file_contents(filename)
    full_path_to_config_file = "#{current_directory}/#{CONFIG_DIR}/#{filename}"
    raise ::Bcome::Exception::Generic, "Could not find init config file '#{full_path_to_config_file}'" unless File.exist?(full_path_to_config_file)
    return ::File.read(full_path_to_config_file)
  end
end
