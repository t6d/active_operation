require 'spec_helper'

describe ActiveOperation::Matcher::Execute::Matcher do
  context 'successful execution' do
    subject(:execute) { described_class.new }

    it "should match if an no error occurs" do
      expect(execute.matches? -> {}).to eq(true)
    end

    it "should match if the output matches the expected output" do
      expect(execute.and_return(nil).matches? -> {}).to eq(true)
    end

    it "should forward inputs" do
      expect(execute.when_called_with(1).and_return(2).matches? ->(number) { number * 2 }).to eq(true)
    end

    it "should indicate if the output is not as expected" do
      matcher = execute.when_called_with(1).and_return(1)

      expect(matcher.matches? ->(number) { number * 2 }).to eq(false)
      expect(matcher.failure_message).to eq(<<~MESSAGE.rstrip)
      incorrect return value:
      expected: 1
      got: 2
      MESSAGE
    end

    it "should indicate if an error occured" do
      matcher = execute.when_called_with(1).and_return(1)

      expect(matcher.matches? ->(number) { raise }).to eq(false)
      expect(matcher.failure_message).to eq(<<~MESSAGE.rstrip)
      the execution failed with the following error: RuntimeError
      MESSAGE
    end
  end

  context 'unsuccessful execution' do
    subject(:execute) { described_class.new }

    it "should match if an error occurs" do
      expect(execute.does_not_match? -> { raise }).to eq(true)
    end

    it "should match if the error matches and no message was given" do
      expect(execute.because_of(ArgumentError).does_not_match? -> { raise ArgumentError }).to eq(true)
    end

    it "should match if the error class and error message match" do
      expect(execute.because_of(ArgumentError, "Some message").does_not_match? -> { raise ArgumentError, "Some message" }).to eq(true)
    end

    it "should forward inputs" do
      expect(execute.when_called_with(true).does_not_match? ->(should_raise) { raise if should_raise }).to eq(true)
    end

    it "should not match if the error message differs" do
      matcher = execute.because_of(ArgumentError, "Some message")

      expect(matcher.does_not_match? -> { raise ArgumentError, "Other message" }).to eq(false)
      expect(matcher.failure_message_when_negated).to eq(<<~MESSAGE.rstrip)
      wrong error raised:
      expected: ArgumentError, "Some message"
      got: ArgumentError, "Other message"
      MESSAGE
    end

    it "should not match if the error message differs" do
      matcher = execute.because_of(ArgumentError)

      expect(matcher.does_not_match? -> { raise }).to eq(false)
      expect(matcher.failure_message_when_negated).to eq(<<~MESSAGE.rstrip)
      wrong error raised:
      expected: ArgumentError
      got: RuntimeError
      MESSAGE
    end
  end

  context "integration using a lambda expression as subject" do
    subject { ->(x) { x } }
    it { is_expected.to execute.when_called_with(1).and_return(1) }
  end
end
