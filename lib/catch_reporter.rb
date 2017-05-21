# Monkey patch the original
require 'xml_parser'

class GeneratorHelper

    # The only change to the original is the replaced regex match
    def test_results_error_handler(executable, shell_result)
    
        if (shell_result[:output].nil? or shell_result[:output].strip.empty?)
            error = true
            # mirror style of generic tool_executor failure output
            notice  = "\n" +
                        "ERROR: Test executable \"#{File.basename(executable)}\" failed.\n" +
                        "> Produced no output to $stdout.\n"
        # elsif ((shell_result[:output] =~ CATCH_XML_STATISTICS_PATTERN).nil?)
        #     error = true
        #     # mirror style of generic tool_executor failure output
        #     notice  = "\n" +
        #                 "ERROR: Test executable \"#{File.basename(executable)}\" failed.\n" +
        #                 "> Produced no final test result counts in $stdout:\n" +
        #                 "#{shell_result[:output].strip}\n"
        end
    
        if (error)
            # since we told the tool executor to ignore the exit code, handle it explicitly here
            notice += "> And exited with status: [#{shell_result[:exit_code]}] (count of failed tests).\n" if (shell_result[:exit_code] != nil)
            notice += "> And then likely crashed.\n"                                                       if (shell_result[:exit_code] == nil)

            notice += "> This is often a symptom of a bad memory access in source or test code.\n\n"

            @streaminator.stderr_puts(notice, Verbosity::COMPLAIN)
            raise      
        end

    end

end


# Monkey patch the original
class GeneratorTestResults
  
  def process_and_write_results(unity_shell_result, results_file, test_file)
    output_file   = results_file
    xml_output = unity_shell_result[:output]
    catch_xml = Catch.parseXmlResult(xml_output)

    results = get_results_structure
        
    results[:source][:path] = File.dirname(test_file)
    results[:source][:file] = File.basename(test_file)
    
    # process test statistics
    xml_result = catch_xml.OverallResults
    # puts xml_result
    results[:counts][:total]   = xml_result.totals
    results[:counts][:failed]  = xml_result.failures
    results[:counts][:passed]  = xml_result.successes
    results[:counts][:ignored]  = xml_result.expectedFailures


    # remove test statistics lines
    output_string = unity_shell_result[:output].sub(CATCH_STDOUT_STATISTICS_PATTERN, '')
    
    output_string.lines do |line|
      # process unity output
      case line
      when /(:IGNORE)/
        elements = extract_line_elements(line, results[:source][:file])
        results[:ignores]   << elements[0]
        results[:stdout]    << elements[1] if (!elements[1].nil?)
      when /(:PASS$)/
        elements = extract_line_elements(line, results[:source][:file])
        results[:successes] << elements[0]
        results[:stdout]    << elements[1] if (!elements[1].nil?)
      when /(:FAIL)/
        elements = extract_line_elements(line, results[:source][:file])
        results[:failures]  << elements[0]
        results[:stdout]    << elements[1] if (!elements[1].nil?)
      else # collect up all other
        results[:stdout] << line.chomp
      end
    end
    
    @generator_test_results_sanity_checker.verify(results, unity_shell_result[:exit_code])
    
    output_file = results_file.ext(@configurator.extension_testfail) if (results[:counts][:failed] > 0)
    
    @yaml_wrapper.dump(output_file, results)
    
    return { :result_file => output_file, :result => results }
  end

  def get_results_structure
    return {
      :source         => {:path => '', :file => ''},
      :successes      => [],
      :failures       => [],
      :ignores        => [],
      :counts         => {:total => 0, :passed => 0, :failed => 0, :ignored  => 0},
      :countsAsserts  => {:total => 0, :passed => 0, :failed => 0, :ignored  => 0},
      :stdout         => [],
      }
  end
end


CATCH_XML_STATISTICS_PATTERN = /<OverallResults successes="(\d+)" failures="(\d+)" expectedFailures="(\d+)"\/>/
CATCH_STDOUT_STATISTICS_PATTERN = /test cases:\s+(\d+)\s+[|]\s+(\d+)\s+passed\s+[|]\s+(\d+)\s+failed\s+assertions:\s+(\d+)\s+[|]\s+(\d+)\s+passed\s+[|]\s+(\d+)\s+failed\s*/i
