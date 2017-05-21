require 'happymapper'

class OverallResults
    include HappyMapper

    tag 'OverallResults'

    def totals
        @successes + @failures + @expectedFailures
    end

    attribute :successes, Integer
    attribute :failures, Integer
    attribute :expectedFailures, Integer
end

class Expression
    include HappyMapper

    tag 'Expression'
    attribute :success, Boolean
    attribute :type, String
    attribute :filename, String
    attribute :line, Integer

    has_one :Original, String
    has_one :Expanded, String
end

class Section
    include HappyMapper

    tag 'Section'
    attribute :name, String
    attribute :filename, String
    attribute :line, Integer

    has_many :Sections, ::Section, :tag => 'Section'
    has_many :Expressions, Expression, :tag => 'Expression', :xpath => '.'
    has_one :OverallResults, OverallResults, :xpath => '.'
end

class OverallResult
    include HappyMapper

    tag 'OverallResult'
    attribute :success, Boolean
end

class TestCase
    include HappyMapper

    tag 'TestCase'
    attribute :name, String
    attribute :tags, String
    attribute :filename, String
    attribute :line, Integer

    has_many :Sections, Section, :tag => 'Section', :xpath => '.'
    has_one :OverallResult, OverallResult, :xpath => '.'
end


class Group
    include HappyMapper

    tag 'Group'
    attribute :name, String

    has_many :TestCases, TestCase, :tag => 'TestCase', :xpath => '.'
    has_one :OverallResults, OverallResults, :xpath => '.'
end



class Catch
    include HappyMapper

    tag 'Catch'
    attribute :name, String

    has_many :Groups, Group, :tag => 'Group', :xpath => '.'
    has_one :OverallResults, OverallResults, :xpath => '.'


    def self.parseXmlResult(data)
        Catch.parse(data, :single => true)
    end
end