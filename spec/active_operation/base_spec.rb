require 'spec_helper'

describe ActiveOperation::Base do
  context "callbacks" do
    subject :operation do
      Class.new(described_class) do
        attr_reader :log

        property :halt_in, accepts: [:before, :around, :execute, :after]
        property :succeed_in, accepts: [:before, :around, :execute, :after]

        def initialize(*)
          super
          @log = []
        end

        before do
          halt log if halt_in == :before
          succeed log if succeed_in == :before
          log << :before
        end

        after do
          halt log if halt_in == :after
          succeed log if succeed_in == :after
          log << :after
        end

        around do |_, execute|
          halt log if halt_in == :around
          succeed log if succeed_in == :around
          log << :around_before
          execute.call
          log << :around_after
        end

        def execute
          halt log if halt_in == :execute
          succeed log if succeed_in == :execute
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

    it "should support early exit in the before filters" do
      log = operation.perform(halt_in: :before)
      expect(log).to eq([])
    end

    it "should support early exit in the before filters" do
      operation_instance = operation.run(halt_in: :before)
      expect(operation_instance.output).to eq([])
      expect(operation_instance).to be_halted
    end

    it "should support early exit in the before filters" do
      operation_instance = operation.run(succeed_in: :before)
      expect(operation_instance.output).to eq([])
      expect(operation_instance).to be_succeeded
    end

    it "should support early exit in the around filters" do
      log = operation.perform(halt_in: :around)
      expect(log).to eq([:before])
    end
  end
end
