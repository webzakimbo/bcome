module Bcome::Initialization::Utils
  def initialize_empty_yaml_config(path)
    File.write(path, {}.to_yaml)
  end

  def create_as_directory(path)
    ::FileUtils.mkdir_p(path)
  end

  def create_file_utils(method, paths)
    paths.each do |path|
      if path.is_file_or_directory?
        @exists << path
      else
        send(method, path)
        @created << path
      end
    end
  end

  def set_prepopulated_configs(path)
    File.write(path, prepopulated_path_contents(path))  
  end
end
