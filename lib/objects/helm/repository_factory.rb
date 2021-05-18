module Bcome::Helm
  class RepositoryFactory

    class << self
      def add_from_config(configs)
        factory = new(configs)
        factory.add
      end
    end 
 
    def initialize(configs)
      @configs = configs
      @repositories = set_repositories
    end

    def set_repositories
      @repositories ||= @configs.collect{|config|
        ::Bcome::Helm::Repository.new(config)
      }
    end

    def add
      @repositories.each{|repo| repo.add }
    end

  end
end
