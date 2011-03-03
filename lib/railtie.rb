# see http://rails.rubyonrails.org/classes/Rails/Railtie.html

# Nice write-up of hooking gems into the views/layouts/statics of Rails 3 apps: 
# http://numbers.brighterplanet.com/2010/07/26/sharing-views-across-rails-3-apps/

require 'rails'

module AppoxyRails
  class Railtie < ::Rails::Railtie

    initializer "appoxy_rails.configure_rails_initialization" do |app|
      puts 'Initializing appoxy_rails Railtie'

#      routes = app.routes
#      app.paths.app.views.push Appoxy::Rails::Layout.view_path

#        config.app_middleware.use '::ActionDispatch::Static', Appoxy::UI.public_path
#        config.app.append_asset_paths

    end
  end
end
