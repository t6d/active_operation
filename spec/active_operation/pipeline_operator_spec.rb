require 'spec_helper'

describe ActiveOperation::Base do
  subject(:upcase_operation) do
    Class.new(ActiveOperation::Base) do
      input :string, accepts: String

      def execute
        string.upcase
      end
    end
  end

  subject(:addbang_operation) do
    Class.new(ActiveOperation::Base) do
      input :string, accepts: String

      def execute
        string.concat("!")
      end
    end
  end

  subject(:addpoop_operation) do
    Class.new(ActiveOperation::Base) do
      input :string, accepts: String

      def execute
        string.concat("💩")
      end
    end
  end

  it "should executes a pipeline with two operations" do
    pipeline = upcase_operation >> addbang_operation
    result = ["hello", "world"].map(&pipeline)
    expect(result).to eq(["HELLO!", "WORLD!"])
  end

  it "should executes a pipeline with three operations" do
    pipeline = upcase_operation >> addbang_operation >> addpoop_operation
    result = ["hello", "world"].map(&pipeline)
    expect(result).to eq(["HELLO!💩", "WORLD!💩"])
  end

  it "should always return a new pipeline when chaining" do
    pipeline1 = upcase_operation >> addbang_operation
    pipeline2 = pipeline1 >> addpoop_operation

    expect(pipeline1).not_to equal(pipeline2)
  end
end
