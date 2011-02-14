require 'active_support/core_ext'
require_relative 'utils'
require_relative 'appoxy_ui'
require_relative 'appoxy_api'
require_relative 'appoxy_sessions'
require_relative 'ui/time_zoner'


if defined?(Rails)
#  puts 'Rails=' + Rails.inspect
#  puts 'vers=' + Rails::VERSION::MAJOR.inspect
  if Rails::VERSION::MAJOR == 2
    raise "appoxy_rails only supports Rails 3+"
  else
    require_relative 'railtie'
  end
end
