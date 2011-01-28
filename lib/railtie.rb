# see http://api.rubyonrails.org/classes/Rails/Railtie.html

require 'rails'

module SimpleWorker
  class Railtie < Rails::Railtie

    initializer "appoxy_rails.configure_rails_initialization" do |app|
      puts 'Initializing appoxy_rails Railtie'

#      routes = app.routes

    end
  end
end
