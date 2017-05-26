require 'ceedling/plugin'
require 'catch_testrunner_generator'
require 'catch_reporter'

require 'fileutils'


class Catch4_Ceedling < Plugin
  @@main_dir = "#{PROJECT_ROOT}/build/test/main"
  @@main_location = "#{@@main_dir}/catch_main.c"
  # Get the location of this plugin.
  @@plugin_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
  
  # Set up Ceedling to use this plugin.
  def setup
    puts "Using Catch..."

    copy_main()

    TestIncludesExtractor.set_main_location(@@main_location)
    # Switch out the The unity test runner with the catchy thing.
    # Yeah, did not work as planned, so plan B: Monkey patching :(
    # @ceedling[:generator_test_runner] = CatchTestRunnerGenerator.new()

    # Add the path to catch.hpp to the include paths.
    COLLECTION_PATHS_TEST_SUPPORT_SOURCE_INCLUDE_VENDOR << "#{@@plugin_root}/vendor/Catch/single_include"
    # Add the interfaces to includes
    COLLECTION_PATHS_TEST_SUPPORT_SOURCE_INCLUDE_VENDOR << "#{@@plugin_root}/src/"
  end

  def copy_main()
    # Optimization: Create extra catch_main file to reduce compilation times
    # Compile only once, it should be invariant
    # (Otherwise it would take ages to compile)
    unless File.file?(@@main_location)
      FileUtils::mkdir_p(@@main_dir)
      FileUtils.copy_file("#{@@plugin_root}/src/catch_main.cpp", @@main_location)
    end
  end

end

# monkey patch
class TestIncludesExtractor
  @@main_location = "#{PROJECT_ROOT}/build/test/main/catch_main.c"

  def self.set_main_location(f_name)
    @@main_location = f_name
  end

  def lookup_includes_list(file)
    file_key = form_file_key(file)

    includes = [@@main_location]

    return includes if (@includes[file_key]).nil?
    return includes + @includes[file_key]
  end
end