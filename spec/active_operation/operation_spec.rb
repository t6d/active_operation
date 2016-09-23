require 'spec_helper'

describe ActiveOperation::Base do
  context "that always returns nil when executed" do
    let(:nil_operation) do
       Class.new(described_class) do
        def execute
          nil
        end
      end
    end

    subject { nil_operation.new }

    it { is_expected.to succeed_to_perform.and_return(nil) }
  end

  context "that always halts and returns its original input" do
    let(:halting_operation) do
      Class.new(described_class) do
        input :message
        def execute
          halt message
        end
      end
    end

    subject(:halting_operation_instance) do
      halting_operation.new("Test")
    end

    it "should return the input value when executed using the class' method perform" do
      expect(halting_operation.perform("Test")).to be == "Test"
    end

    it "should return the input value when executed using the instance's peform method" do
      expect(halting_operation_instance.perform).to be == "Test"
    end

    it "should have halted after performing" do
      halting_operation_instance.perform
      expect(halting_operation_instance).to be_halted
    end
  end

  context "that always returns something when executed" do
    let(:simple_operation) do
      Class.new(described_class) do
        def execute
          ""
        end
      end
    end

    subject(:simple_operation_instance) do
      simple_operation.new
    end

    before(:each) do
      simple_operation_instance.perform
    end

    it "should have a result" do
      expect(simple_operation_instance.output).to be
    end

    it "should have succeeded" do
      expect(simple_operation_instance).to be_succeeded
    end

    context "when extended with a preparator and a finalizer" do
      let(:logger) { double("Logger") }

      subject(:simple_operation_with_preparator_and_finalizer) do
        logger = logger()
        Class.new(simple_operation) do
          before { logger.info("preparing") }
          after { logger.info("finalizing") }
        end
      end

      it "should execute the preparator and finalizer when performing" do
        expect(logger).to receive(:info).ordered.with("preparing")
        expect(logger).to receive(:info).ordered.with("finalizing")
        simple_operation_with_preparator_and_finalizer.perform
      end
    end
  end

  context "that can be parameterized" do
    subject(:string_multiplier) do
      Class.new(described_class) do
        input :text
        property :multiplier, :default => 3

        def execute
          text.to_s * multiplier
        end
      end
    end

    it { is_expected.to succeed_to_perform.when_initialized_with("-").and_return("---") }
    it { is_expected.to succeed_to_perform.when_initialized_with("-", multiplier: 5).and_return("-----") }
  end

  context "that takes two values (a string and a multiplier)" do
    subject(:string_multiplier) do
      Class.new(described_class) do
        input :string
        input :multiplier

        def execute
          string * multiplier
        end
      end
    end

    it { is_expected.to succeed_to_perform.when_initialized_with("-", 3).and_return("---") }
  end

  context "inheritance" do
    let(:base_operation) do
      Class.new(described_class) do
        input :text
      end
    end

    let(:sub_operation) do
      Class.new(base_operation) do
        def execute
          text.upcase
        end
      end
    end

    let(:sub_operation_with_different_input) do
      Class.new(base_operation) do
        input :multiplier
        def execute
          text * multiplier
        end
      end
    end

    context "the base operation" do
      subject! { base_operation }

      it "should take one argument" do
        expect(base_operation.inputs.count).to eq(1)
        expect(base_operation.inputs.map(&:name)).to eq([:text])
      end
    end

    context "the sub operation" do
      subject! { sub_operation }

      it "should take one argument" do
        expect(base_operation.inputs.count).to eq(1)
        expect(base_operation.inputs.map(&:name)).to eq([:text])
      end

      it { is_expected.to succeed_to_perform.when_initialized_with("lorem ipsum").and_return("LOREM IPSUM") }
    end

    context "the sub operation with different input" do
      subject! { sub_operation_with_different_input }

      it "should take two arguments" do
        expect(sub_operation_with_different_input.inputs.count).to eq(2)
        expect(sub_operation_with_different_input.inputs.map(&:name)).to eq([:text, :multiplier])
      end

      it "should not influence the arguments of base operation" do
        expect(base_operation.inputs.count).to eq(1)
        expect(base_operation.inputs.map(&:name)).to eq([:text])
      end

      it { is_expected.to succeed_to_perform.when_initialized_with("-", 3).and_return("---") }
    end
  end
end
