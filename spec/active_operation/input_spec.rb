require 'spec_helper'

describe ActiveOperation::Base do
  context "input handling" do
    subject(:operation) do
      Class.new(ActiveOperation::Base) do
        input :name
        input :subscribe_to_newsletter, type: :keyword

        def execute
          [name, subscribe_to_newsletter]
        end
      end
    end

    specify "the operation should require a name" do
      expect { operation.new }.to raise_error(ArgumentError)
    end

    specify "the operation should take the name as a positional argument" do
      operation_instance = operation.new("John")
      expect(operation_instance.name).to eq("John")
    end
  end
end
