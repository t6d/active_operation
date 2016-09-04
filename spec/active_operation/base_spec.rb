require 'spec_helper'

describe ActiveOperation::Base do
  context "callbacks" do
    let(:states) { [:before, :around, :around_after, :execute, :after] }
    let(:error_monitor) { spy("Error monitor") }
    let(:succeeded_monitor) { spy("Succeeded Monitor") }
    let(:halted_monitor) { spy("Succeeded Monitor") }

    subject :operation do
      states = self.states

      Class.new(described_class) do
        attr_reader :log

        property :halt_in, accepts: states
        property :succeed_in, accepts: states
        property :raise_in, accepts: states
        property :error_monitor
        property :succeeded_monitor
        property :halted_monitor

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
          error_monitor.log(error) unless error_monitor.nil?
        end

        succeeded do
          succeeded_monitor.log(:succeeded) unless succeeded_monitor.nil?
        end

        halted do
          halted_monitor.log(:halted) unless halted_monitor.nil?
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
      expect { operation.run(raise_in: :before, error_monitor: error_monitor) }.to raise_error(RuntimeError, "before")
      expect(error_monitor).to have_received(:log).with(an_instance_of(RuntimeError))
    end

    it "should run error callbacks after an exception in a after statement" do
      expect { operation.run(raise_in: :after, error_monitor: error_monitor) }.to raise_error(RuntimeError, "after")
      expect(error_monitor).to have_received(:log).with(an_instance_of(RuntimeError))
    end

    it "should run error callbacks after an exception in a around statement before #execute has been called" do
      expect { operation.run(raise_in: :around, error_monitor: error_monitor) }. to raise_error(RuntimeError, "around")
      expect(error_monitor).to have_received(:log).with(an_instance_of(RuntimeError))
    end

    it "should run error callbacks after an exception in a around statement after #execute has been called" do
      expect { operation.run(raise_in: :around_after, error_monitor: error_monitor) }.to raise_error(RuntimeError, "around_after")
      expect(error_monitor).to have_received(:log).with(an_instance_of(RuntimeError))
    end

    it "should not run error callbacks if operation halted" do
      expect(operation.run(halt_in: :before, error_monitor: error_monitor)).to be_halted
      expect(error_monitor).to_not have_received(:log)
    end

    it "should not run error callbacks if operation succeeded" do
      expect(operation.run(succeed_in: :before, error_monitor: error_monitor)).to be_succeeded
      expect(error_monitor).to_not have_received(:log)
    end

    it "should run succeeded callbacks after when the operation succeeded" do
      expect(operation.run(succeed_in: :before, succeeded_monitor: succeeded_monitor)).to be_succeeded
      expect(succeeded_monitor).to have_received(:log).with(:succeeded)
    end

    it "should run halted callbacks after when the operation halted" do
      expect(operation.run(halt_in: :before, halted_monitor: halted_monitor)).to be_halted
      expect(halted_monitor).to have_received(:log).with(:halted)
    end
  end
end
