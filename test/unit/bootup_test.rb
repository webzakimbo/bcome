

load "#{File.dirname(__FILE__)}/../base.rb"
load "#{File.dirname(__FILE__)}/bootup_helper.rb"

class BootupTest < ActiveSupport::TestCase
  include UnitTestHelper

  def test_should_initialize_a_bootup
    # Given
    breadcrumbs = 'foo:bar'
    argument = given_a_random_string_of_length(5)

    # When
    bootup = ::Bcome::Bootup.new(breadcrumbs: breadcrumbs,
                                 argument: argument)

    # Then
    assert bootup.breadcrumbs == breadcrumbs
    assert bootup.argument == argument
    assert bootup.crumbs == %w[foo bar]
  end

  def test_should_parse_breadcrmbs
    # Given
    crumb1 = given_a_random_string_of_length(5)
    crumb2 = given_a_random_string_of_length(5)

    breadcrumbs = "#{crumb1}:#{crumb2}"

    # When
    bootup = ::Bcome::Bootup.new(breadcrumbs: breadcrumbs)

    # Then
    assert bootup.crumbs == [crumb1, crumb2]
  end

  def test_should_initialize_estate_tree_to_get_estate
    # Given
    bootup = ::Bcome::Bootup.new(breadcrumbs: nil)

    estate = Bcome::Node::Collection.new(given_estate_setup_params)
    ::Bcome::Node::Factory.instance.expects(:init_tree).returns(estate)

    # When/then
    bootup_estate = bootup.estate

    # Then
    assert estate == bootup_estate
  end

  def test_should_set_context_if_no_crumbs
    # Given
    bootup = ::Bcome::Bootup.new(breadcrumbs: nil)

    estate = Bcome::Node::Collection.new(given_estate_setup_params)
    bootup.expects(:estate).returns(estate)
    ::Bcome::Workspace.instance.expects(:set).with(context: estate).returns(nil)

    # When/then
    bootup.do
  end

  def test_should_traverse_tree_if_crumbs
    # Given
    bootup = ::Bcome::Bootup.new(breadcrumbs: 'foo:bar')

    assert bootup.crumbs.size == 2

    estate = Bcome::Node::Collection.new(given_estate_setup_params)
    bootup.expects(:estate).returns(estate)
    bootup.expects(:traverse).with(estate)

    # When/then
    bootup.do
  end

  def test_should_traverse_dummy_tree
    # Given
    estate = given_a_dummy_estate

    breadcrumbs = 'one:two:three:four'
    view_data = given_basic_dummy_view_data
    ::Bcome::Node::Factory.instance.create_tree(estate, view_data)

    found_context = test_traverse_tree(estate, %w[one two three four])

    ::Bcome::Node::Factory.instance.expects(:init_tree).returns(estate)

    # We expect to have traversed to our found context, at which point we enter a console session, thus:
    ::Bcome::Workspace.instance.expects(:set).with(context: found_context)

    # When/then
    ::Bcome::Bootup.do(breadcrumbs: breadcrumbs)
  end

  def test_should_invoke_crumb_as_method_on_context
    # Given
    estate = given_a_dummy_estate
    breadcrumbs = 'one:two:three:four:five'
    view_data = given_basic_dummy_view_data
    ::Bcome::Node::Factory.instance.create_tree(estate, view_data)

    found_context = test_traverse_tree(estate, %w[one two three four])

    ::Bcome::Node::Factory.instance.expects(:init_tree).returns(estate)

    # We expect to have not found a context for "five", and so we'll invoke "five" on "four"
    found_context.expects(:invoke).with('five', nil)

    # When/then
    ::Bcome::Bootup.do(breadcrumbs: breadcrumbs)
  end

  def test_should_invoke_crumb_as_method_on_context_passing_in_an_argument
    # Given
    estate = given_a_dummy_estate
    breadcrumbs = 'one:two:three:four:five'
    argument = 'an argument'

    view_data = given_basic_dummy_view_data
    ::Bcome::Node::Factory.instance.create_tree(estate, view_data)

    found_context = test_traverse_tree(estate, %w[one two three four])

    ::Bcome::Node::Factory.instance.expects(:init_tree).returns(estate)

    # We expect to have not found a context for "five", and so we'll invoke "five" on "four" passing in our argument "argument"
    found_context.expects(:invoke).with('five', argument)

    # When/then
    ::Bcome::Bootup.do(breadcrumbs: breadcrumbs, argument: argument)
  end

  def test_should_be_able_to_pass_an_argument_to_an_invoked_method_on_a_context
    # Given
    identifier = given_a_random_string_of_length(4)
    method_name = :methodthattakesinoneargument
    arguments = 'args'

    config = {
      identifier: 'toplevel',
      description: 'top level node',
      type: 'collection',
      views: [
        { identifier: identifier, type: 'collection', description: "the node we'll execute our method on" }
      ]
    }

    YAML.expects(:load_file).returns(config)
    estate = Bcome::Node::Factory.instance.init_tree

    Bcome::Node::Factory.instance.expects(:init_tree).returns(estate)

    # When/then
    ::Bcome::Bootup.do(breadcrumbs: "#{identifier}:#{method_name}", argument: arguments)

    # And all our expectations are met
  end

  def test_should_be_able_to_invoke_a_method_on_a_context
    # Given
    identifier = given_a_random_string_of_length(4)
    method_name = :methodthatdoesnotrequirearguments # Method added in our bootup helper

    config = {
      identifier: 'toplevel',
      description: 'top level node',
      type: 'collection',
      views: [
        { identifier: identifier, type: 'collection', description: "the node we'll execute our method on" }
      ]
    }

    YAML.expects(:load_file).returns(config)
    estate = Bcome::Node::Factory.instance.init_tree

    Bcome::Node::Factory.instance.expects(:init_tree).returns(estate)

    # When/then
    ::Bcome::Bootup.do(breadcrumbs: "#{identifier}:#{method_name}", argument: nil)

    # And all our expectations are met
  end

  def test_should_raise_when_invoking_a_method_on_a_context_without_arguments_when_one_is_required
    # Given
    identifier = given_a_random_string_of_length(4)
    method_name = :methodthattakesinoneargument

    config = {
      identifier: 'toplevel',
      description: 'top level node',
      type: 'collection',
      views: [
        { identifier: identifier, type: 'collection', description: "the node we'll execute our method on" }
      ]
    }

    YAML.expects(:load_file).returns(config)
    estate = Bcome::Node::Factory.instance.init_tree

    Bcome::Node::Factory.instance.expects(:init_tree).returns(estate)

    # When/then
    assert_raise Bcome::Exception::MethodInvocationRequiresParameter do
      ::Bcome::Bootup.do(breadcrumbs: "#{identifier}:#{method_name}", arguments: nil)
    end
    # And all our expectations are met
  end

  def test_should_raise_when_invoking_a_method_on_a_context_with_arguments_when_none_are_required
    # Given
    identifier = given_a_random_string_of_length(4)
    method_name = :methodthattakesinoneargument # Method added in our bootup helper

    config = {
      identifier: 'toplevel',
      description: 'top level node',
      type: 'collection',
      views: [
        { identifier: identifier, type: 'collection', description: "the node we'll execute our method on" }
      ]
    }

    YAML.expects(:load_file).returns(config)
    estate = Bcome::Node::Factory.instance.init_tree

    Bcome::Node::Factory.instance.expects(:init_tree).returns(estate)

    # When/then
    assert_raise Bcome::Exception::MethodInvocationRequiresParameter do
      ::Bcome::Bootup.do(breadcrumbs: "#{identifier}:#{method_name}", argument: nil)
    end
    # and also that all our expectations are met
  end

  def test_should_raise_when_penultimate_crumb_references_neither_node_nor_invokable_method
    # Given
    identifier = given_a_random_string_of_length(4)
    method_name = :i_dont_exist

    # When/then
    assert_raise Bcome::Exception::InvalidBcomeBreadcrumb do
      ::Bcome::Bootup.do(breadcrumbs: "#{identifier}:#{method_name}", arguments: nil)
    end
  end
end
