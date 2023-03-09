module Bcome::Orchestration::Catalogue
  class DockerBackdoor < Bcome::Orchestration::Base

    include ::Bcome::LoadingBar::Handler
    include Docker::Menu
    include Docker::Prompt
    include Docker::Input
    include Docker::CommandRunner
    include Docker::Container
    include Docker::Action

    def initialize(*params)
      super
      @selection = :default
      @filter = nil
    end

    def execute
      ::Bcome::Orchestrator.instance.silence_command_output! 
      interactive
    end

    def interactive
      list
      show_menu
      wait_for_command_input 
    end

  end
end
