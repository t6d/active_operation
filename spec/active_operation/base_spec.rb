require 'spec_helper'

describe ActiveOperation::Base do
  subject(:operation) do
    Class.new(ActiveOperation::Base) do
      def execute
        Random.rand
      end
    end
  end

  specify ".call should return the operation output" do
    expect(operation.call).to be_kind_of(Float)
  end

  specify "#call should return the operation output" do
    operation_instance = operation.new
    expect(operation_instance.call).to be_kind_of(Float)
  end

  specify "#output should run the operation" do
    operation_instance = operation.new
    expect { operation_instance.output }.to change { operation_instance.state }.from(:initialized).to(:succeeded)
  end

  specify "#output should return the output" do
    operation_instance = operation.new
    expect(operation_instance.output).to be_kind_of(Float)
  end

  specify "#output should memoize the result" do
    operation_instance = operation.new
    expect(operation_instance.output).to eq(operation_instance.output)
  end

  specify ".to_proc should generate a proc that will run the operation" do
    doubler = Class.new(described_class) do
      input :number

      def execute
        number * 2
      end
    end

    expect([2, 4].map(&doubler)).to eq([4, 8])
  end

  specify ".to_proc should generate a proc that will run the operation and maps multiple arguments to the input" do
    value_extractor = Class.new(described_class) do
      input :key
      input :value

      def execute
        value
      end
    end

    value_generator = Class.new do
      include Enumerable

      def each
        yield 1, 2
      end
    end

    expect(value_generator.new.map(&value_extractor)).to eq([2])
  end

  context "when overriding perform" do
    subject(:operation) do
      Class.new(described_class) do
        def perform
          "overwritten"
        end
      end
    end

    specify "the #call alias should be resolved at runtime not at boot time" do
      expect(operation.new.perform).to eq("overwritten")
      expect(operation.new.call).to eq("overwritten")
    end

    specify "the .call alias should be resolved at runtime not at boot time" do
      expect(operation.perform).to eq("overwritten")
      expect(operation.call).to eq("overwritten")
    end
  end
end
