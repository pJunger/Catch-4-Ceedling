require 'ceedling/plugin'
require 'catch_testrunner_generator'

class Catch < Plugin

  # Set up Ceedling to use this plugin.
  def setup
    # Get the location of this plugin.
    @plugin_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
    puts "Using Catch..."

    # Switch out the The unity test runner with the catchy thing.
    @ceedling[:generator_test_runner] = CatchTestRunnerGenerator.new(@ceedling[:setupinator].config_hash[:unity])

    # Add the path to catch.hpp to the include paths.
    COLLECTION_PATHS_TEST_SUPPORT_SOURCE_INCLUDE_VENDOR << "#{@plugin_root}/vendor/catch/"
    # Add the interfaces to includes
    COLLECTION_PATHS_TEST_SUPPORT_SOURCE_INCLUDE_VENDOR << "#{@plugin_root}/src/"
  end

end

