module Bcome::Initialization::Utils

  def initialize_empty_yaml_config(path)
    File.write(path, {}.to_yaml)
  end

  def create_as_directory(path)
    ::FileUtils.mkdir_p(path)
  end

  def create_file_utils(method, paths)
     paths.each do |path|
       unless path.is_file_or_directory?
        send(method, path)
        @created << path
      else
        @exists << path
      end
    end
  end

end
