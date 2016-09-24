require "spec_helper"

describe ActiveOperation::Pipeline do
  let(:string_generator) do
    Class.new(ActiveOperation::Base) do
      def self.name
        "StringGenerator"
      end

      def execute
        "chunky bacon"
      end
    end
  end

  let(:string_capitalizer) do
    Class.new(ActiveOperation::Base) do
      input :text

      def self.name
        "StringCapitalizer"
      end

      def execute
        text.upcase
      end
    end
  end

  let(:string_multiplier) do
    Class.new(ActiveOperation::Base) do
      input :text
      property :multiplicator, default: 1, converts: :to_i, required: true
      property :separator, default: ' ', converts: :to_s, required: true

      def self.name
        "StringMultiplier"
      end

      def execute
        (Array(text) * multiplicator).join(separator)
      end
    end
  end

  let(:halting_operation) do
    Class.new(ActiveOperation::Base) do
      def self.name
        "HaltingOperation"
      end

      def execute
        halt
      end
    end
  end

  context "when composed of one operation that generates" do
    subject(:composed_operation) do
      operation = string_generator

      Class.new(described_class) do
        use operation
      end
    end

    it "should return this string as result" do
      expect(composed_operation.perform).to eq("chunky bacon")
    end
  end

  context "when composed of two operations, one that generates a string and one that multiplies it" do
    subject(:composed_operation) do
      string_generator = self.string_generator
      string_multiplier = self.string_multiplier

      Class.new(described_class) do
        property :multiplicator, default: 3

        use string_generator
        use string_multiplier, separator: ' - ', multiplicator: lambda { multiplicator }
      end.new
    end

    it { is_expected.to succeed_to_perform.and_return('chunky bacon - chunky bacon - chunky bacon') }
  end

  context "when composed of two operations using the factory method '.compose'" do
    subject(:composed_operation) do
      described_class.compose(string_generator, string_capitalizer).new
    end

    it { is_expected.to succeed_to_perform.and_return("CHUNKY BACON") }
    it { is_expected.to utilize_operations(string_generator, string_capitalizer) }
  end

  context "when composed of two operations, one that generates a string and one that capitalizes strings, " do
    subject(:composed_operation) do
      operations = [string_generator, string_capitalizer]

      Class.new(described_class) do
        use operations.first
        use operations.last
      end
    end

    it "should return a capitalized version of the generated string" do
      expect(composed_operation.perform).to eq("CHUNKY BACON")
    end

    it { is_expected.to utilize_operations(string_generator, string_capitalizer) }
  end

  context "when composed of three operations, one that generates a string, one that halts and one that capatalizes strings" do
    subject(:composed_operation) do
      described_class.compose(string_generator, halting_operation, string_capitalizer)
    end

    it "should return a capitalized version of the generated string" do
      expect(composed_operation.perform).to eq(nil)
    end

    it "should only execute the first two operations" do
      expect_any_instance_of(string_generator).to receive(:perform).and_call_original
      expect_any_instance_of(halting_operation).to receive(:perform).and_call_original
      expect_any_instance_of(string_capitalizer).not_to receive(:perform)
      composed_operation.perform
    end
    it { is_expected.to utilize_operations(string_generator, halting_operation, string_capitalizer) }
  end

  context "when composed of two operations; one that that capitalizes a string and one that repeats the string" do
    subject(:composed_operation) do
      operations = [string_capitalizer, string_multiplier]

      Class.new(described_class) do
        use operations.first
        use operations.last, multiplicator: 2
      end
    end

    it "should raise when instantiated with no input" do
      expect { composed_operation.new }.to raise_error(ArgumentError)
    end

    it "should not raise when instantiated with a string" do
      expect { composed_operation.new("some string") }.to_not raise_error
    end

    it "should have an input argument with the same name as the first operation" do
      expect(composed_operation.inputs.map(&:name)).to eq(string_capitalizer.inputs.map(&:name))
    end

    it { is_expected.to succeed_to_perform.when_initialized_with("hello").and_return("HELLO HELLO") }
  end
end

