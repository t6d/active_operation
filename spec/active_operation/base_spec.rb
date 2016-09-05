require 'spec_helper'

describe ActiveOperation::Base do
  subject(:operation) do
    Class.new(ActiveOperation::Base) do
      def execute
        Random.rand
      end
    end
  end

  specify ".call should return the operation instance" do
    expect(operation.call).to be_kind_of(operation)
  end

  specify ".call should invoke the operation" do
    operation_instance = operation.call
    expect(operation_instance).to be_succeeded
  end

  specify ".call should generate and memoize an output" do
    operation_instance = operation.call
    expect(operation_instance.output).to eq(operation_instance.output)
  end

  specify ".output should return the operation output" do
    expect(operation.output).to be_kind_of(Float)
  end

  specify "#call should return self" do
    operation_instance = operation.new
    expect(operation_instance.call).to eq(operation_instance)
  end

  specify "#output should run the operation" do
    operation_instance = operation.new
    expect { operation_instance.output }.to change { operation_instance.state }.from(:initialized).to(:succeeded)
  end

  specify "#output should return the output" do
    expect(operation.output).to be_kind_of(Float)
  end

  specify "#output should memoize the result" do
    operation_instance = operation.new
    expect(operation_instance.output).to eq(operation_instance.output)
  end
end
