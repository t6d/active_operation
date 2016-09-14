require 'spec_helper'

describe ActiveOperation::Base do
  context "callbacks" do
    let(:states) { [:before, :around, :around_after, :execute, :after] }
    let(:error_monitor) { spy("Error monitor") }
    let(:succeeded_monitor) { spy("Succeeded Monitor") }
    let(:halted_monitor) { spy("Halted Monitor") }

    subject :operation do
      states = self.states

      Class.new(described_class) do
        property :halt_in, accepts: states
        property :succeed_in, accepts: states
        property :raise_in, accepts: states
        property :error_monitor
        property :succeeded_monitor
        property :halted_monitor
        property :log, default: -> { [] }

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
      log = []
      operation_instance = operation.new(log: log)
      expect { operation_instance.call }.to change { log }.from([]).to(%i[
        before
        around_before
        execute
        around_after
        after
      ])
    end

    it "should call after callbacks independent of operation outcome" do
      log = []
      operation_instance = operation.new(halt_in: :before, log: log)
      expect { operation_instance.call }.to change { log }.from([]).to(%i[
        after
      ])
    end

    it "should support halting in before statements" do
      expect(operation.call(halt_in: :before)).to eq(:before)
    end

    it "should support halting in before statements" do
      expect(operation.call(halt_in: :before)).to eq(:before)
    end

    it "should support halting in around statements before #execute is called" do
      expect(operation.call(halt_in: :around)).to eq(:around)
    end

    it "should support succeeding in before statements" do
      expect(operation.call(succeed_in: :before)).to eq(:before)
    end

    it "should support succeeding in around statements" do
      expect(operation.call(succeed_in: :around)).to eq(:around)
    end

    it "should raise an error when halting in around statements after #execute has been called" do
      expect { operation.call(halt_in: :around_after) }.to raise_error(ActiveOperation::AlreadyCompletedError)
    end

    it "should raise an error when succeeding in around statements after #execute has been called" do
      expect { operation.call(succeed_in: :around_after) }.to raise_error(ActiveOperation::AlreadyCompletedError)
    end

    it "should raise an error when halting in after statements" do
      expect { operation.call(halt_in: :after) }.to raise_error(ActiveOperation::AlreadyCompletedError)
    end

    it "should raise an error when succeeding in after statements" do
      expect { operation.call(succeed_in: :after) }.to raise_error(ActiveOperation::AlreadyCompletedError)
    end

    it "should call error callbacks after an exception in a before statement" do
      expect { operation.call(raise_in: :before, error_monitor: error_monitor) }.to raise_error(RuntimeError, "before")
      expect(error_monitor).to have_received(:log).with(an_instance_of(RuntimeError))
    end

    it "should call error callbacks after an exception in a after statement" do
      expect { operation.call(raise_in: :after, error_monitor: error_monitor) }.to raise_error(RuntimeError, "after")
      expect(error_monitor).to have_received(:log).with(an_instance_of(RuntimeError))
    end

    it "should call error callbacks after an exception in a around statement before #execute has been called" do
      expect { operation.call(raise_in: :around, error_monitor: error_monitor) }. to raise_error(RuntimeError, "around")
      expect(error_monitor).to have_received(:log).with(an_instance_of(RuntimeError))
    end

    it "should call error callbacks after an exception in a around statement after #execute has been called" do
      expect { operation.call(raise_in: :around_after, error_monitor: error_monitor) }.to raise_error(RuntimeError, "around_after")
      expect(error_monitor).to have_received(:log).with(an_instance_of(RuntimeError))
    end

    it "should not call error callbacks if operation halted" do
      operation_instance = operation.new(halt_in: :before, error_monitor: error_monitor)
      operation_instance.call

      expect(operation_instance).to be_halted
      expect(error_monitor).to_not have_received(:log)
    end

    it "should not call error callbacks if operation succeeded" do
      operation_instance = operation.new(succeed_in: :before, error_monitor: error_monitor)
      operation_instance.call

      expect(operation_instance).to be_succeeded
      expect(error_monitor).to_not have_received(:log)
    end

    it "should call succeeded callbacks after when the operation succeeded" do
      operation_instance = operation.new(succeed_in: :before, succeeded_monitor: succeeded_monitor)
      operation_instance.call

      expect(operation_instance).to be_succeeded
      expect(succeeded_monitor).to have_received(:log).with(:succeeded)
    end

    it "should call halted callbacks after when the operation halted" do
      operation_instance = operation.new(halt_in: :before, halted_monitor: halted_monitor)
      operation_instance.call

      expect(operation_instance).to be_halted
      expect(halted_monitor).to have_received(:log).with(:halted)
    end
  end

  context "callback objects" do
    let(:monitor) do
      monitor = Object.new

      class << monitor
        def log
          @log ||= []
        end

        def before(operation)
          log << :before
        end

        def around(operation, &execute)
          log << :around
          execute.call
        end

        def after(operation)
          log << :after
        end

        def halted(operation)
          log << :halted
        end

        def succeeded(operation)
          log << :succeeded
        end

        def error(operation)
          log << :error
        end
      end

      monitor
    end

    subject(:operation) do
      monitor = self.monitor

      Class.new(described_class) do
        input :desired_outcome, accepts: [:succeed, :halt, :error], required: true, type: :keyword

        before monitor
        around monitor
        after monitor
        halted monitor
        succeeded monitor
        error monitor

        def execute
          case desired_outcome
          when :succeed
            succeed
          when :halt
            halt
          when :error
            raise
          end
        end
      end
    end

    it 'should run the before, around, after and succeed callbacks on the monitor if the operation succeeds' do
      operation.call(desired_outcome: :succeed)
      expect(monitor.log).to eq(%i[
        before
        around
        after
        succeeded
      ])
    end

    it 'should run the before, around, after and halted callbacks on the monitor if the operation halts execution' do
      operation.call(desired_outcome: :halt)
      expect(monitor.log).to eq(%i[
        before
        around
        after
        halted
      ])
    end

    it 'should run the before, around and error callbacks on the monitor if the operation fails because of an exception' do
      operation.call(desired_outcome: :error) rescue nil
      expect(monitor.log).to eq(%i[
        before
        around
        error
      ])
    end
  end
end
