require 'active_support/core_ext'
require 'digest/hmac'
require 'net/http'
require 'base64'

require_relative 'utils'
require_relative 'appoxy_ui'
require_relative 'appoxy_sessions'
require_relative 'ui/time_zoner'

require_relative "rails/api_controller"
require_relative "rails/signatures"


# backwards compatible.
# @deprecated
module Appoxy
  module Api
    include Appoxy::Rails
    extend Appoxy::Rails
  end
end


if defined?(Rails)
#  puts 'Rails=' + Rails.inspect
#  puts 'vers=' + Rails::VERSION::MAJOR.inspect
  if Rails::VERSION::MAJOR == 2
    raise "appoxy_rails only supports Rails 3+"
  else
    require_relative 'railtie'
  end
end
