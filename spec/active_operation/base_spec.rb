require 'spec_helper'

describe ActiveOperation::Base do
  context "callbacks" do
    subject :operation do
      Class.new(described_class) do
        property :early_exit_in, accepts: [:before, :around, :execute, :after]
        property :log, default: -> { [] }

        before do
          abort log if early_exit_in == :before
          log << :before
        end

        after do
          abort log if early_exit_in == :after
          log << :after
        end

        around do |_, execute|
          abort log if early_exit_in == :around
          log << :around_before
          execute.call
          log << :around_after
        end

        def execute
          abort log if early_exit_in == :execute
          log << :execute
          log
        end
      end
    end

    it "should appear in the expected order when the operation is executed" do
      log = operation.call
      expect(log).to eq(%i[
        before
        around_before
        execute
        around_after
        after
      ])
    end

    it "should support early exit in the before filters" do
      log = operation.call(early_exit_in: :before)
      expect(log).to eq([])
    end

    it "should support early exit in the around filters" do
      log = operation.call(early_exit_in: :around)
      expect(log).to eq([:before])
    end
  end
end
