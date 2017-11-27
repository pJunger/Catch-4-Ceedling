require 'ceedling/plugin'
require 'catch_testrunner_generator'
require 'catch_reporter'

require 'thread'
require 'fileutils'

begin 
  require 'concurrent'
rescue LoadError => e
  puts 'No Concurrent Ruby found: Please execute "gem install concurrent-ruby"' if e.message =~ /concurrent/
  raise
end

class Catch4_Ceedling < Plugin
  # Get the location of this plugin.
  @@semaphore = Mutex.new
  @@compile_future = nil

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
  end

  def pre_compile_execute(arg_hash)
    if @@semaphore.try_lock
      @@compile_future = Concurrent::Future.execute {
        compile_main(arg_hash) 
      }
    end
  end

  def pre_link_execute(arg_hash)
    # The object file is needed before linking, so we will wait here
    if @@compile_future.incomplete?
      @@compile_future.wait_or_cancel(20)
    end
  end

  def compile_main(arg_hash)
    # Todo: Replace through proper rake call respectively add as dependency to ceedling (and then remove linker argument from .yml)
    # Compile only once, it should be invariant
    if (arg_hash[:context] != RELEASE_SYM) and (not File.file?(@out_file))
      puts 'Starting compilation of catch_main.c'
      FileUtils::mkdir_p(@main_dir)
      @ceedling[:generator].generate_object_file(
        arg_hash[:tool],
        arg_hash[:operation],
        arg_hash[:context],
        @catch_file,
        @out_file,
        @ceedling[:file_path_utils].form_test_build_list_filepath( @out_file ) 
      )
      puts 'Finished compilation of catch_main.c'
    end
  end

end
