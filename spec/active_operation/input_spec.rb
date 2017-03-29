require 'spec_helper'

describe ActiveOperation::Base do
  context "input" do
    subject(:operation) do
      Class.new(ActiveOperation::Base) do
        input :name
        input :likes_cucumber_tom_collins, type: :keyword

        def execute
          [name, subscribe_to_newsletter]
        end
      end
    end

    specify "the operation should require a name" do
      expect(operation).not_to execute.because_of(ArgumentError)
    end

    specify "the operation should take the name as a positional argument" do
      operation_instance = operation.new("John")
      expect(operation_instance.name).to eq("John")
    end

    specify "the operation should take the subscribe_to_newsletter as a keyword argument" do
      operation_instance = operation.new("John", likes_cucumber_tom_collins: true)
      expect(operation_instance.likes_cucumber_tom_collins).to eq(true)
    end

    context "inheritance" do
      subject(:sub_operation) do
        Class.new(operation) do
          input :email
          input :likes_pizza_hawaii, type: :keyword
        end
      end

      specify "the operation should take the name and email as a positional argument" do
        operation_instance = sub_operation.new("John", "john@doe.com")
        expect(operation_instance.name).to eq("John")
        expect(operation_instance.email).to eq("john@doe.com")
      end

      specify "the operation should take the subscribe_to_newsletter and likes_pizza_hawaii as a keyword argument" do
        operation_instance = sub_operation.new("John", "john@doe.com", likes_pizza_hawaii: true, likes_cucumber_tom_collins: true)
        expect(operation_instance.likes_pizza_hawaii).to eq(true)
        expect(operation_instance.likes_cucumber_tom_collins).to eq(true)
      end
    end
  end
end
