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
