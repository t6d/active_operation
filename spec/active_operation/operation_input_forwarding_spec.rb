require 'spec_helper'

describe ActiveOperation::Pipeline, "input forwarding:" do
  describe "An operation pipeline that first constructs an array with two elements and then passes it to an operation that accepts two input parameters and returns the second one" do

    let(:array_generator) do
      Class.new(ActiveOperation::Base) do
        def execute
          [:first_element, :second_element]
        end
      end
    end

    let(:extractor) do
      Class.new(ActiveOperation::Base) do
        input :first_parameter
        input :second_parameter
        def execute
          second_parameter
        end
      end
    end

    subject(:pipeline) do
      ActiveOperation::Pipeline.compose(array_generator, extractor)
    end

    it "should return the correct element" do
      result = pipeline.perform
      expect(result).to eq(:second_element)
    end
  end

  describe "An operation pipeline that first constructs an enumerator, then passes it from operation to operation and finally returns it as the result" do
    let(:enum_generator) do
      Class.new(ActiveOperation::Base) do
        def execute
          %w[just some text].enum_for(:each)
        end
      end
    end

    let(:null_operation) do
      Class.new(ActiveOperation::Base) do
        input :enumerator
        def execute
          enumerator
        end
      end
    end

    subject(:pipeline) do
      ActiveOperation::Pipeline.compose(enum_generator, null_operation)
    end

    it "should actually return an enumerator" do
      result = pipeline.perform
      expect(result).to be_kind_of(Enumerator)
    end
  end

  describe "An operation pipeline that first constructs an object that responds #to_a, then passes it from operation to operation and finally returns it as the result" do
    let(:dummy) do
      Object.new.tap do |o|
        def o.to_a
          %w[just some text]
        end
      end
    end

    let(:object_representable_as_array_generator) do
      spec_context = self
      Class.new(ActiveOperation::Base) do
        define_method(:execute) do
          spec_context.dummy
        end
      end
    end

    let(:null_operation) do
      Class.new(ActiveOperation::Base) do
        input :object_representable_as_array
        def execute
          object_representable_as_array
        end
      end
    end

    subject(:pipeline) do
      ActiveOperation::Pipeline.compose(object_representable_as_array_generator, null_operation)
    end

    it "should actually return this object" do
      result = pipeline.perform
      expect(result).to eq(dummy)
    end
  end
end
