require 'spec_helper'

describe "An operation with two before and two after filters =>" do
  let(:test_operation) do
    Class.new(ActiveOperation::Base) do

      input :flow_control

      attr_accessor :trace

      def initialize(input = [], options = {})
        super
        self.trace = [:initialize]
      end

      before do
        trace << :outer_before
        halt if flow_control.include?(:halt_in_outer_before)
      end

      before do
        trace << :inner_before
        halt if flow_control.include?(:halt_in_inner_before)
      end

      after do
        trace << :inner_after
        halt if flow_control.include?(:halt_in_inner_after)
      end

      after do
        trace << :outer_after
        halt if flow_control.include?(:halt_in_outer_after)
      end

      def execute
        trace << :execute_start
        halt if flow_control.include?(:halt_in_execute)
        trace << :execute_stop
        :final_result
      end
    end
  end

  context "when run and everything works as expected =>" do
    subject       { test_operation.new }
    before(:each) { subject.perform }

    it ("should run 'initialize' first")                    { expect(subject.trace[0]).to eq(:initialize)    }
    it ("should run 'outer before' after 'initialize'")     { expect(subject.trace[1]).to eq(:outer_before)  }
    it ("should run 'inner before' after 'outer before'")   { expect(subject.trace[2]).to eq(:inner_before)  }
    it ("should start 'execute' after 'inner before'")      { expect(subject.trace[3]).to eq(:execute_start) }
    it ("should stop 'execute' after it started 'execute'") { expect(subject.trace[4]).to eq(:execute_stop)  }
    it ("should run 'inner after' after 'execute'")         { expect(subject.trace[5]).to eq(:outer_after)   }
    it ("should run 'outer after' after 'inner after'")     { expect(subject.trace[6]).to eq(:inner_after)   }
    it ("should return :final_result as result")            { expect(subject.output).to eq(:final_result) }
    it { is_expected.to     be_succeeded }
    it { is_expected.not_to be_halted    }
  end

  # Now: TEST ALL! the possible code flows systematically
  test_vectors = [
    {
      :context => "no complications =>",
      :input   => [],
      :output  => :final_result,
      :trace   => [:initialize, :outer_before, :inner_before, :execute_start, :execute_stop, :outer_after, :inner_after],
      :state   => :succeeded
    }, {
      :context => "halting in outer_before filter =>",
      :input   => [:halt_in_outer_before],
      :output  => nil,
      :trace   => [:initialize, :outer_before, :outer_after, :inner_after],
      :state   => :halted
    }, {
      :context => "halting in inner_before filter =>",
      :input   => [:halt_in_inner_before],
      :output  => nil,
      :trace   => [:initialize, :outer_before, :inner_before, :outer_after, :inner_after],
      :state   => :halted
    }, {
      :context => "halting in execute =>",
      :input   => [:halt_in_execute],
      :output  => nil,
      :trace   => [:initialize, :outer_before, :inner_before, :execute_start, :outer_after, :inner_after],
      :state   => :halted
    }
  ]

  context "when initialized with input that leads to =>" do
    subject { test_operation.new(input) }
    before(:each) { subject.perform }

    test_vectors.each do |tv|
      context tv[:context] do
        let(:input) { tv[:input] }
        let(:trace) { subject.trace }

        it("then its trace should be #{tv[:trace].inspect}") { expect(subject.trace).to eq(tv[:trace]) }
        it("then its result should be #{tv[:output].inspect}") { expect(subject.output).to eq(tv[:output]) }
        it("then its succeeded? method should return #{(tv[:state] == :succeeded).inspect}") { expect(subject.succeeded?).to eq(tv[:state] == :succeeded) }
        it("then its halted? method should return #{(tv[:state] == :halted).inspect}") { expect(subject.halted?).to    eq(tv[:state] == :halted)    }
      end
    end
  end
end
