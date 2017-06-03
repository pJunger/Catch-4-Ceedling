require 'ceedling/plugin'
require 'catch_testrunner_generator'
require 'catch_reporter'

require 'fileutils'

class Catch4_Ceedling < Plugin
  # Get the location of this plugin.
  
  def setup
    @plugin_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
    @test_dir = File.join(PROJECT_ROOT, 'build', 'test')
    @main_dir = File.join(@test_dir, 'runners')
    @out = File.join(@test_dir, 'out')
    @out_file = File.join(@out, 'catch_main.o')

    @catch_file = File.join(@plugin_root, 'src', 'catch_main.cpp')

    # Add the path to catch.hpp to the include paths.
    COLLECTION_PATHS_TEST_SUPPORT_SOURCE_INCLUDE_VENDOR << "#{@plugin_root}/vendor/Catch/single_include"
    # Add the interfaces to includes
    COLLECTION_PATHS_TEST_SUPPORT_SOURCE_INCLUDE_VENDOR << "#{@plugin_root}/src/"
  end

  def pre_runner_generate(arg_hash)
    GeneratorTestRunner.set_context(@ceedling, @plugin_root)
    compile_main()
  end

  def compile_main()
    # Todo: Replace through proper rake call respectively add as dependency to ceedling (and then remove linker argument from .yml)
    # Optimization: Create extra catch_main file to reduce compilation times
    # Compile only once, it should be invariant

    unless File.file?(@out_file)
      FileUtils::mkdir_p(@main_dir)
      @ceedling[:generator].generate_object_file(
        TOOLS_TEST_COMPILER,
        OPERATION_COMPILE_SYM,
        TEST_SYM,
        @catch_file,
        @out_file,
        @ceedling[:file_path_utils].form_test_build_list_filepath( @out_file ) 
      )
    end
  end

end
