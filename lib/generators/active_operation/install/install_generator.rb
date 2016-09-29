require 'rails/generators/base'
require 'rails/generators/active_record'

module ActiveOperation
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      def create_application_operation
        template 'application_operation.rb', 'app/operations/application_operation.rb'
      end
    end
  end
end
