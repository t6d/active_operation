require 'rails/generators/base'
require 'rails/generators/active_record'

module ActiveOperation
  module Generators
    class OperationGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('../../../../../support/templates', __FILE__)

      def create_operation
        template 'operation.rb', File.join('app/operations', class_path, "#{file_name}.rb")
      end
    end
  end
end
