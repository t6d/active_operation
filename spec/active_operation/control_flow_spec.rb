require 'spec_helper'

describe ActiveOperation::Base do
  context "control flow" do
    subject(:operation) do
      Class.new(described_class) do
        property :desired_outcome, accepts: [:succeeded, :halted], required: true

        def execute
          case desired_outcome
          when :succeeded
            succeed :succeeded
          when :halted
            halt :halted
          end
        end
      end
    end

    it "should call #when_succeeded callbacks if the operation succeeded" do
      operation_instance = operation.call(desired_outcome: :succeeded)
      expect { operation_instance.when_succeeded { throw :succeeded } }.to throw_symbol(:succeeded)
    end

    it "should invoke #when_succeeded callbacks with the output" do
      operation_instance = operation.call(desired_outcome: :succeeded)
      operation_instance.when_succeeded do |output|
        expect(output).to be(:succeeded)
      end
    end

    it "should call #when_halted callbacks if the operation halted" do
      operation_instance = operation.call(desired_outcome: :halted)
      expect { operation_instance.when_halted { throw :halted } }.to throw_symbol(:halted)
    end

    it "should invoke #when_halted callbacks with the output" do
      operation_instance = operation.call(desired_outcome: :halted)
      operation_instance.when_halted do |output|
        expect(output).to be(:halted)
      end
    end
  end
end
