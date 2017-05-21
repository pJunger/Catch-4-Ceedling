require 'ceedling/plugin'
require 'catch_testrunner_generator'
require 'catch_reporter'

class Catch4_Ceedling < Plugin

  # Set up Ceedling to use this plugin.
  def setup
    # Get the location of this plugin.
    @plugin_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
    puts "Using Catch..."
    @main_c = ''
    @main_o = ''

    GeneratorTestRunner.set_main_location(@plugin_root)
    # Switch out the The unity test runner with the catchy thing.
    # Yeah, did not work as planned, so plan B: Monkey patching :(
    # @ceedling[:generator_test_runner] = CatchTestRunnerGenerator.new()

    # Add the path to catch.hpp to the include paths.
    COLLECTION_PATHS_TEST_SUPPORT_SOURCE_INCLUDE_VENDOR << "#{@plugin_root}/vendor/Catch/single_include"
    # Add the interfaces to includes
    COLLECTION_PATHS_TEST_SUPPORT_SOURCE_INCLUDE_VENDOR << "#{@plugin_root}/src/"
  end

  def compile_main_file_if_nonexisting()
    # Compile only once, it should be invariant
  end

  #  { :tool => tool,
  #    :context => context,
  #    :objects => objects,
  #    :executable => executable,
  #    :map => map,
  #    :libraries => libraries
  #  }
  def pre_link_execute(arg_hash)
    # if gcc, change to g++?
    # or if gcc, add stl?

    # if arg_hash[:tool][:]
    
    # Add compiled main_file to :objects
  end

end

