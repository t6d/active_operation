# frozen_string_literal: true
require 'rails/generators/base'
require 'rails/generators/active_record'

module ActiveOperation
  module Generators
    class OperationGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('../../../../../support/templates', __FILE__)

      hook_for :test_framework

      def create_operation
        template 'operation.rb.erb', File.join('app/operations', class_path, "#{file_name}_operation.rb")
      end
    end
  end
end
