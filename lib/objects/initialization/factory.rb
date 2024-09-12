require 'fileutils'

module Bcome::Initialization
  class Factory
    include ::Bcome::Initialization::Utils
    include ::Bcome::Initialization::Structure
    include ::Bcome::Initialization::PrepopulatedConfigs

    class << self
      def do
        new.do
      end
    end

    def initialize
      @created = []
      @exists = []
    end

    def do
      puts "\nInitialising Bcome".title.bold
      initialization_paths.each do |conf|
        create_file_utils(conf[:method], conf[:paths])
      end
      summarize(@created, "\nThe following paths were created")
      summarize(@exists, "\nThe following paths exist already, and were untouched")
      puts "\n"
    end

    def summarize(paths, caption)
      return unless paths.any?

      puts "#{caption}:".informational
      paths.each { |path| puts path.resource_key }
    end
  end
end
