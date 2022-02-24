# frozen_string_literal: true

class ::Bcome::Workspace
  include ::Singleton

  attr_reader :context
  attr_reader :estate

  def initialize
    @context = nil
    @console_set = false
    @estate = nil
  end

  def set(params)
    init_irb unless console_set?

    @context = params[:context]
    @context.load_nodes if @context.respond_to?(:load_nodes) && !@context.nodes_loaded?

    main_context = IRB.conf[:MAIN_CONTEXT]

    @context.irb_workspace = main_context.workspace if main_context
    @context.previous_irb_workspace = params[:current_context] if params[:current_context]

    show_welcome if params[:show_welcome]

    spawn_into_console_for_context
    nil
  end

  def screen_width
    return 0 unless ::Bcome::EnsureBinary.do("tput")
    return ::Bcome::Command::Local.run("tput cols").stdout.chomp.to_i
  end

  def print_divider(width)
    print ("─" * width).bc_grey + "\n" 
  end

  def show_welcome
    puts "\nWelcome to bcome v#{::Bcome::Version.release}".bc_yellow
    puts "\nType\s" + 'menu'.underline + "\sfor a command list, or\s" + 'registry'.underline + "\sfor your custom tasks."
    puts "\n"

    width = screen_width 
    print_divider(width) if width

    puts "\n"
  end

  def console_set!
    @console_set = true
  end

  def console_set?
    @console_set
  end

  def object_is_current_context?(object)
    @context == object
  end

  def spawn_into_console_for_context
    ::IRB.start_session(self, @context)
  end

  def has_context?
    !context.nil?
  end

  def kubernetes_focus_on
    @focus_on ||= default_kubernetes_focus_on
  end

  def default_kubernetes_focus_on
    ::Bcome::Node::K8Cluster::Pod
  end

  def set_kubernetes_focus(klass)
    @focus_on = klass
  end

  def irb_prompt
    prompt = @context ? @context.prompt_breadcrumb : default_prompt
    return prompt
  end

  def default_prompt
    'bcome'
  end

  protected

  def init_irb
    IRB.setup nil
    IRB.conf[:MAIN_CONTEXT] = IRB::Irb.new.context
    console_set!
  end
end
