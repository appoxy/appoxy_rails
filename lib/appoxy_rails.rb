require 'active_support/core_ext'
require 'net/http'
require 'base64'

require_relative 'utils'
require_relative 'appoxy_ui'
require_relative 'appoxy_sessions'
require_relative 'ui/time_zoner'

require_relative "server_api/api_controller"
require_relative "server_api/signatures"


# backwards compatible.
# @deprecated
module Appoxy
  module Api
    include Appoxy::ServerApi
    extend Appoxy::ServerApi
  end
end


if defined?(::Rails) && defined?(::Rails::VERSION)
#  puts 'Rails=' + Rails.inspect
#  puts 'vers=' + Rails::VERSION::MAJOR.inspect
  if ::Rails::VERSION::MAJOR == 2
    raise "appoxy_rails only supports Rails 3+"
  else
    require_relative 'railtie'
  end
end
