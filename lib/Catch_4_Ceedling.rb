require 'ceedling/plugin'
require 'catch_testrunner_generator'

class Catch4_Ceedling < Plugin

  # Set up Ceedling to use this plugin.
  def setup
    # Get the location of this plugin.
    @plugin_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
    puts "Using Catch..."

    GeneratorTestRunner.set_main_location(@plugin_root)
    # Switch out the The unity test runner with the catchy thing.
    # @ceedling[:generator_test_runner] = CatchTestRunnerGenerator.new()
    # @ceedling[:generator_test_runner].find_tests = CatchTestRunnerGenerator.find_tests
    # @ceedling[:generator_test_runner].generate = CatchTestRunnerGenerator.generate

    # Add the path to catch.hpp to the include paths.
    COLLECTION_PATHS_TEST_SUPPORT_SOURCE_INCLUDE_VENDOR << "#{@plugin_root}/vendor/Catch/single_include"
    # Add the interfaces to includes
    COLLECTION_PATHS_TEST_SUPPORT_SOURCE_INCLUDE_VENDOR << "#{@plugin_root}/src/"
  end

end

