begin 
  require 'happymapper'
rescue LoadError => e
  puts 'No HappyMapper found: Please execute "gem install nokogiri-happymapper"' if e.message =~ /happymapper/
  raise
end

class OverallResults
    include HappyMapper

    tag 'OverallResults'

    def to_s
        "OverallResults: +#{@successes} -#{@failures} o#{@expectedFailures}"
    end

    def totals
        @successes + @failures + @expectedFailures
    end

    attribute :successes, Integer
    attribute :failures, Integer
    attribute :expectedFailures, Integer

    def make_report(indent=0)
        acc = [do_indent("Results: #{@successes} passed, #{@failures} failed, #{@expectedFailures} ignored", indent)]
        acc
    end
end

class Expression
    include HappyMapper

    def to_s
        "#{@tag}: #{@success}"
    end

    tag 'Expression'
    attribute :success, Boolean
    attribute :type, String
    attribute :filename, String
    attribute :line, Integer

    has_one :Original, String
    has_one :Expanded, String

    def get_attribute_s(attribute_name, attribute, indent)
        attribute_s = attribute.sub(/^\s*/, '').sub(/\s*$/, '')
        do_indent("#{attribute_name}: #{attribute_s}", indent)
    end
    
    def make_report(indent=0)
        next_indent = get_next_indent(indent)
        next_indent2 = get_next_indent(next_indent)
        acc = [
            do_indent("@ line #{@line}:", next_indent),
            get_attribute_s('Original', @Original, next_indent2), 
            get_attribute_s('Expanded', @Expanded, next_indent2)
        ]
        acc
    end
end

class Section
    include HappyMapper

    def to_s
        "#{@tag}: #{@name}"
    end

    tag 'Section'
    attribute :name, String
    attribute :filename, String
    attribute :line, Integer

    has_many :Sections, ::Section, :tag => 'Section', :xpath => '.'
    has_many :Expressions, Expression, :tag => 'Expression' #, :xpath => '.'
    has_one :OverallResults, OverallResults, :xpath => '.'

    def make_report(indent=0, skipResult=false)
        next_indent = get_next_indent(indent)
        acc = [do_indent(name, indent)]
        # acc += @Expressions.flat_map {|expression| expression.make_report(next_indent)}
        acc += @Sections.flat_map {|section| section.make_report(indent, true)}
        unless skipResult
            if @Expressions.empty?
                acc += ['', do_indent('Results: No Assertions in testcase', indent)]
            else
                acc += ['', do_indent('Assertions:', next_indent)]
                # acc.push(do_indent('Assertions:', next_indent))
                acc += @Expressions.flat_map {|expression| expression.make_report(next_indent)}
                acc += @OverallResults.make_report(indent)
            end
        end
        acc
    end
end

class OverallResult
    include HappyMapper

    def to_s
        "OverallResult: #{to_passed_failed}"
    end

    tag 'OverallResult'
    attribute :success, Boolean

    def to_passed_failed
        if (@success)
            'passed'
        else
            'failed'
        end
    end

    def make_report(indent=0)
        acc = [do_indent("Result: #{to_passed_failed}", indent)]
        acc
    end
end

class TestCase
    include HappyMapper

    def to_s
        "#{@tag}: #{@name}"
    end

    tag 'TestCase'
    attribute :name, String
    attribute :tags, String
    attribute :filename, String
    attribute :line, Integer

    has_many :Sections, Section, :tag => 'Section', :xpath => '.'
    has_many :Expressions, Expression, :tag => 'Expression', :xpath => '.'
    has_one :OverallResult, OverallResult, :xpath => '.'

    def make_report(indent=0)
        next_indent = get_next_indent(indent)
        # acc = [do_indent(name, indent)]
        acc = []
        acc += @Sections.flat_map {|section| section.make_report(next_indent, true)}
        acc += ['', do_indent('Assertions:', next_indent)]
        acc += @Expressions.flat_map {|expression| expression.make_report(next_indent)}
        acc += @OverallResult.make_report(next_indent)
        acc
    end
end


class Group
    include HappyMapper

    def to_s
        "#{@tag}: #{@name}"
    end

    tag 'Group'
    attribute :name, String

    has_many :TestCases, TestCase, :tag => 'TestCase', :xpath => '.'
    has_one :OverallResults, OverallResults, :xpath => '.'

    def make_report(indent=0)
        next_indent = get_next_indent(indent)
        acc = [do_indent(name, indent)]
        acc += @TestCases.flat_map {|test_case| test_case.make_report(next_indent)}
        acc += @OverallResults.make_report(next_indent)
        acc
    end
end



class Catch
    include HappyMapper

    def to_s
        "#{@tag}: #{@name}"
    end

    tag 'Catch'
    attribute :name, String

    has_many :Groups, Group, :tag => 'Group', :xpath => '.'
    has_one :OverallResults, OverallResults, :xpath => '.'

    def make_report(indent=0)
        next_indent = get_next_indent(indent)
        acc = [do_indent(name, indent)]
        acc += @Groups.flat_map {|group| group.make_report(next_indent)}
        acc += @OverallResults.make_report(next_indent)
        acc
    end

    def self.parseXmlResult(data)
        Catch.parse(data, :single => true)
    end
end

def get_next_indent(cur_indent)
    cur_indent + 2
end

def do_indent(item, indent)
    (' ' * indent) + item
end

def make_report(xml_node, indent)
    "\n" + xml_node.make_report(2).join("\n")
end