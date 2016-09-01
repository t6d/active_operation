require 'spec_helper'

describe ActiveOperation::Base do
  context "callbacks" do
    STATES = [:before, :around, :execute, :after]

    subject :operation do
      Class.new(described_class) do
        attr_reader :log

        property :halt_in, accepts: STATES
        property :succeed_in, accepts: STATES

        def initialize(*)
          super
          @log = []
        end

        before do
          halt :before if halt_in == :before
          succeed :before if succeed_in == :before

          log << :before
        end

        after do
          halt :after if halt_in == :after
          succeed :after if succeed_in == :after

          log << :after
        end

        around do |_, execute|
          halt :around if halt_in == :around
          succeed :around if succeed_in == :around

          log << :around_before
          execute.call
          log << :around_after
        end

        def execute
          halt :execute if halt_in == :execute
          succeed :execute if succeed_in == :execute

          log << :execute
          log
        end
      end
    end

    it "should appear in the expected order when the operation is executed" do
      log = operation.perform
      expect(log).to eq(%i[
        before
        around_before
        execute
        around_after
        after
      ])
    end

    STATES.each do |state|
      it "should support halting in #{state} statements when executed using #perform" do
        output = operation.perform(halt_in: state)
        expect(output).to eq(state)
      end

      it "should support succeeding in #{state} statements when executed using #perform" do
        output = operation.perform(succeed_in: state)
        expect(output).to eq(state)
      end

      it "should support halting in #{state} statements when executed using #run" do
        operation_instance = operation.run(halt_in: state)
        expect(operation_instance.output).to eq(state)
        expect(operation_instance).to be_halted
      end

      it "should support succeeding in #{state} statements when executed using #run" do
        operation_instance = operation.run(succeed_in: state)
        expect(operation_instance.output).to eq(state)
        expect(operation_instance).to be_succeeded
      end
    end
  end
end
