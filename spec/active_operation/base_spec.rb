require 'spec_helper'

describe ActiveOperation::Base do
  context "callbacks" do
    let(:states) { [:before, :around, :around_after, :execute, :after] }
    let(:monitor) { spy("Monitor") }

    subject :operation do
      states = self.states
      monitor = self.monitor

      Class.new(described_class) do
        attr_reader :log

        property :halt_in, accepts: states
        property :succeed_in, accepts: states
        property :raise_in, accepts: states
        property :monitor, default: monitor

        def initialize(*)
          super
          @log = []
        end

        before do
          halt :before if halt_in == :before
          succeed :before if succeed_in == :before
          raise RuntimeError, :before if raise_in == :before

          log << :before
        end

        after do
          halt :after if halt_in == :after
          succeed :after if succeed_in == :after
          raise RuntimeError, :after if raise_in == :after

          log << :after
        end

        around do |_, executable|
          halt :around if halt_in == :around
          succeed :around if succeed_in == :around
          raise RuntimeError, :around if raise_in == :around

          log << :around_before
          executable.call
          log << :around_after

          succeed :around_after if succeed_in == :around_after
          halt :around_after if halt_in == :around_after
          raise RuntimeError, :around_after if raise_in == :around_after
        end

        def execute
          halt :execute if halt_in == :execute
          succeed :execute if succeed_in == :execute
          raise RuntimeError, :execute if raise_in == :execute

          log << :execute
          log
        end

        error do
          monitor.log(error)
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

    it "should run after callbacks independent of operation outcome" do
      operation_instance = operation.run(halt_in: :before)
      expect(operation_instance.log).to eq(%i[
        after
      ])
    end

    it "should support halting in before statements" do
      expect(operation.perform(halt_in: :before)).to eq(:before)
    end

    it "should support halting in before statements" do
      expect(operation.perform(halt_in: :before)).to eq(:before)
    end

    it "should support halting in around statements before #execute is called" do
      expect(operation.perform(halt_in: :around)).to eq(:around)
    end

    it "should support succeeding in before statements" do
      expect(operation.perform(succeed_in: :before)).to eq(:before)
    end

    it "should support succeeding in around statements" do
      expect(operation.perform(succeed_in: :around)).to eq(:around)
    end

    it "should raise an error when halting in around statements after #execute has been called" do
      expect { operation.perform(halt_in: :around_after) }.to raise_error(ActiveOperation::AlreadyCompletedError)
    end

    it "should raise an error when succeeding in around statements after #execute has been called" do
      expect { operation.perform(succeed_in: :around_after) }.to raise_error(ActiveOperation::AlreadyCompletedError)
    end

    it "should raise an error when halting in after statements" do
      expect { operation.perform(halt_in: :after) }.to raise_error(ActiveOperation::AlreadyCompletedError)
    end

    it "should raise an error when succeeding in after statements" do
      expect { operation.perform(succeed_in: :after) }.to raise_error(ActiveOperation::AlreadyCompletedError)
    end

    it "should run error callbacks after an exception in a before statement" do
      operation_instance = operation.new(raise_in: :before, monitor: monitor)
      expect { operation_instance.run }.to raise_error(RuntimeError, "before")
      expect(monitor).to have_received(:log).with(an_instance_of(RuntimeError))
    end

    it "should run error callbacks after an exception in a after statement" do
      operation_instance = operation.new(raise_in: :after, monitor: monitor)
      expect { operation_instance.run }.to raise_error(RuntimeError, "after")
      expect(monitor).to have_received(:log).with(an_instance_of(RuntimeError))
    end

    it "should run error callbacks after an exception in a around statement before #execute has been called" do
      operation_instance = operation.new(raise_in: :around, monitor: monitor)
      expect { operation_instance.run }.to raise_error(RuntimeError, "around")
      expect(monitor).to have_received(:log).with(an_instance_of(RuntimeError))
    end

    it "should run error callbacks after an exception in a around statement after #execute has been called" do
      operation_instance = operation.new(raise_in: :around_after, monitor: monitor)
      expect { operation_instance.run }.to raise_error(RuntimeError, "around_after")
      expect(monitor).to have_received(:log).with(an_instance_of(RuntimeError))
    end

    it "should not run error callbacks if operation halted" do
      operation_instance = operation.new(halt_in: :before, monitor: monitor)
      expect(monitor).to_not have_received(:log)
    end

    it "should not run error callbacks if operation succeeded" do
      operation_instance = operation.new(succeed_in: :before, monitor: monitor)
      expect(monitor).to_not have_received(:log)
    end
  end
end
