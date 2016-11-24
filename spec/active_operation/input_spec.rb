require 'spec_helper'

describe ActiveOperation::Base do
  context "input" do
    subject(:operation) do
      Class.new(ActiveOperation::Base) do
        input :name
        property :likes_cucumber_tom_collins

        def execute
          [name, likes_cucumber_tom_collins]
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

    specify "the operation should take the likes_cucumber_tom_collins as a keyword argument" do
      operation_instance = operation.new("John", likes_cucumber_tom_collins: true)
      expect(operation_instance.likes_cucumber_tom_collins).to eq(true)
    end

    context "optional positional arguments and keyword argument" do
      subject(:operation) do
        Class.new(ActiveOperation::Base) do
          input :id
          property :limit

          def execute
            [id, limit]
          end
        end
      end

      specify "the operation should not require the positional argument" do
        operation_instance = operation.new(limit: 5)
        expect(operation_instance.limit).to eq(5)
      end

      specify "the operation should take the hash as a positional argument" do
        operation_instance = operation.new(123)
        expect(operation_instance.id).to eq(123)
      end

      specify "the operation should take the hash and limit as a positional argument" do
        operation_instance = operation.new(123, limit: 5)
        expect(operation_instance.limit).to eq(5)
      end
    end

    context "optional positional hash argument and hash argument" do
      subject(:operation) do
        Class.new(ActiveOperation::Base) do
          input :hash, accepts: Hash
          property :limit

          def execute
            [hash, limit]
          end
        end
      end

      specify "the operation should not require the positional argument" do
        operation_instance = operation.new(limit: 5)
        expect(operation_instance.limit).to eq(5)
      end

      specify "the operation should take the hash as a positional argument" do
        operation_instance = operation.new({ works: true })
        expect(operation_instance.hash).to eq({ works: true })
      end

      specify "the operation should take the hash and limit as a positional argument" do
        operation_instance = operation.new({ works: true }, limit: 5)
        expect(operation_instance.limit).to eq(5)
      end
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
