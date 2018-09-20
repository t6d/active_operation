# frozen_string_literal: true
module TestUnit
  module Generators
    class OperationGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('../../../../../support/templates', __FILE__)

      def copy_files
        template 'operation_test.rb.erb', File.join('test/operations', class_path, "#{file_name}_test.rb")
      end
    end
  end
end
