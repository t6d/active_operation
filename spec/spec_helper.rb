if Warning.respond_to?(:[])
  Warning[:deprecated] = true
end

require 'pry'
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'active_operation'
