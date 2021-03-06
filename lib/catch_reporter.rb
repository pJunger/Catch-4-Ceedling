require 'xml_parser'

# Monkey patch the original
class GeneratorHelper

    # The only change to the original is the replaced regex match
    def test_results_error_handler(executable, shell_result)
    
        if (shell_result[:output].nil? or shell_result[:output].strip.empty?)
            error = true
            # mirror style of generic tool_executor failure output
            notice  = "\n" +
                        "ERROR: Test executable \"#{File.basename(executable)}\" failed.\n" +
                        "> Produced no output to $stdout.\n"
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
    results = get_results_structure

    xml_output = unity_shell_result[:output]

    check_if_catch_successful(xml_output)
    
    results[:source][:path] = File.dirname(test_file)
    results[:source][:file] = File.basename(test_file)
      

    begin
      catch_xml = Catch.parseXmlResult(xml_output)
    rescue Nokogiri::XML::SyntaxError => exception
      get_info_before_seg_fault(xml_output)
    end    
      
    # process test statistics
    xml_result = catch_xml.OverallResults
    # puts xml_result
    results[:counts][:total]   = xml_result.totals
    results[:counts][:failed]  = xml_result.failures
    results[:counts][:passed]  = xml_result.successes
    results[:counts][:ignored]  = xml_result.expectedFailures


    # remove test statistics lines
    output_string = unity_shell_result[:output].sub(CATCH_STDOUT_STATISTICS_PATTERN, '')
    
    catch_xml.Groups.each do |group|
      group.TestCases.each do |test_case|
        should_it_fail = test_case.tags =~ /\[!shouldfail\]/
        sections = test_case.Sections
        if sections.length == 0
          result = test_case.OverallResult
          if result.success == true
            results[:successes] << create_line_elements(test_case)
          else
            results[:failures]  << create_line_elements(test_case)
          end
        else
          sections.each_with_index do |section, index|
            result = section.OverallResults
            line_elem = create_line_elements(test_case, section, index)
            if (result.successes == 0 and result.failures == 0 and result.expectedFailures == 0)
              # No assertions?
              results[:failures]   << line_elem
            elsif (result.successes == 0 and result.failures == 0)
              results[:ignores]   << line_elem
            elsif (result.failures > 0)
              results[:failures]   << line_elem
            else
              results[:successes]   << line_elem
            end
          end
          results[:stdout]    << make_report(result, 0)
        end
      end
    end
    
    output_file = results_file.ext(@configurator.extension_testfail) if (results[:counts][:failed] > 0)
      
    @yaml_wrapper.dump(output_file, results)

    return { :result_file => output_file, :result => results }
  end

  def create_line_elements(test_case, section=nil, index=nil)
    name = test_case.name
    message = []
    if (section.nil?)
      line = test_case.line
    else
      name += ", Path ##{index + 1}"
      line = section.line
      message += section.make_report(2)
    end
    message += test_case.make_report(0)

    {:test => name, :line => line.to_i, :message => make_string(message), :xml => test_case}
  end

  def get_results_structure
    return {
      :source         => {:path => '', :file => ''},
      :successes      => [],
      :failures       => [],
      :ignores        => [],
      :counts         => {:total => 0, :passed => 0, :failed => 0, :ignored  => 0},
      :stdout         => [],
      }
  end

  private


  def check_if_catch_successful(output)
    check_if_multiple_tests_with_same_name(output)
  end

  def check_if_multiple_tests_with_same_name(output)
    match = output.match(/[\s\S]*?error:\s+TEST_CASE\(\s*"(.*?)"\s*\)\s+already\s+defined.
      \s+First\s+seen\s+at\s+([\w.\/]+):(\d+)
      \s+Redefined\s+at\s+([\w.\/]+):(\d+)/x)

    if (match)
      notice = "\nFATAL ERROR:\n"
      notice += %Q(One or more testcases have already been defined with the same name: "#{match[1]}"\n)
      notice += "Location #1: #{match[2]} @ line #{match[3]}\n"
      notice += "Location #2: #{match[4]} @ line #{match[5]}\n\n"
      raise notice
    end
  end

  def get_info_before_seg_fault(output)
    # match = output.match(/(?><(?:(?:\/TestCase)|(?:\/Section)|(?:Group\s+name="[\w\s]+?"))>\s*)
    #                       (<TestCase.*?>.*?)(?!<\/TestCase|Group|Catch>)$/xs)

    match = output.match(/(?>                           # Atomic group to prevent backtracking explosions
                            <  (?:                      # Before capturing, one of these must happen
                                 \/TestCase             # End of a previous testcase
                                 |  Group\s+name=".+?") # or a group just started
                            >  \s*) 
                          (  <TestCase 
                                      \s+ name="(.*?)"
                                      \s+ tags=".*?"
                                      \s+ filename="(.*?)"
                                      \s+ line="(.*?)">  .*?  )      # Take the unfinished TestCase
                          (?!  <\/  TestCase  |  Group  |  Catch  >  )$  # and this testcase should not end
                          /xs)

    if (match)
      notice = "\nFATAL ERROR:\n"
      notice += "There has been a segmentation fault in:\n" 
      notice += "\"#{match[2]}\" @ #{match[3]}:#{match[4]}\n\n"
      notice += "The remaining output is:\n"
      notice += match[1]
      notice += "\n\nStack trace:"
      raise notice
    end
  end

end


CATCH_XML_STATISTICS_PATTERN = /<OverallResults successes="(\d+)" failures="(\d+)" expectedFailures="(\d+)"\/>/
CATCH_STDOUT_STATISTICS_PATTERN = /test cases:\s+(\d+)\s+[|]\s+(\d+)\s+passed\s+[|]\s+(\d+)\s+failed\s+assertions:\s+(\d+)\s+[|]\s+(\d+)\s+passed\s+[|]\s+(\d+)\s+failed\s*/i
