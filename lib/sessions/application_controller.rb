module Appoxy

  module Sessions
    module ApplicationController

      def self.included(base)
        # Initialize module.
        base.helper_method :logged_in?
        base.helper_method :current_user
        base.helper_method :base_url

        base.after_filter :close_sdb_connection
        base.before_filter :clear_sdb_stats

        base.helper_method :facebook_oauth_url
        base.helper_method :is_mobile_device?
        base.helper_method :is_device?

      end


      protected

      def clear_sdb_stats
        SimpleRecord.stats.clear
      end

      def close_sdb_connection
        SimpleRecord.close_connection
      end


      def logout_keeping_session!
        @current_user = nil # not logged in, and don't do it for me
        session[:user_id] = nil # keeps the session but kill our variable
      end


      def logged_in?
        #puts 'logged_in??'
        #puts 'current_user=' + current_user.inspect
        current_user
      end


      def current_user=(new_user)
        set_current_user(new_user)
      end

      def set_current_user(user)
        session[:user_id] = user.id if user
        @current_user = user
      end


      def current_user
        @current_user ||= login_from_session
        @current_user
      end


      def login_from_session
        #puts 'Login from session=' + session[:user_id].inspect
        user = nil
        if session[:user_id]
          begin
            user = ::User.find(session[:user_id])
          rescue => ex
            puts 'User not found: ' + ex.message
          end
        end
        unless user
          # else try with cookie
          if cookies[:rme]
            # todo: should this also check a user_id cookie too?
            user = ::User.find_by_remember_token(cookies[:rme])
          end
          if user && !user.remember_token_expires.nil? && Time.now < user.remember_token_expires
            @current_user = user
            session[:user_id] = user.id
          end
        end
        user
      end

      def current_url
        request.url
      end


      def base_url
        r = "#{request.protocol}#{request.host}"
        if request.port != 80
          r << ":#{request.port}"
        end
        @base_url = r
        r
      end

      def random_string(length=10)
        Appoxy::Utils.random_string(length)
      end

      def authenticate
        if !logged_in?
          flash[:warning] = "You need to login to access this page."
          session[:return_to] = request.request_uri # return to after logging in
          puts "ac=" + params[:ac].inspect
          if params[:user_id] && params[:ac]
            # todo: should we store ac in cookie?  Make it easier to pass around
            cookies[:ac] = params[:ac]
            # then from an invite
            user = ::User.find(params[:user_id])
            if user && user.password.blank? # is this the best way to decide of user has not logged in? Could also check status.
              redirect_to :controller=>"users", :action=>"new", :email=>user.email, :ac=>params[:ac]
              return
            end
          end
          redirect_to :controller=>"sessions", :action=>"new", :ac=>params[:ac]
        else
          after_authenticate
        end


      end

      def after_authenticate

      end


      def facebook_oauth_url(options={})
#        puts 'appconfig==' + Rails.application.config.inspect
        raise "Please config your facebook id and api keys." unless ::Rails.application.config.respond_to?(:facebook_app_id)
        raise "Scope must be specified." unless options[:scope]
        app_id = ::Rails.application.config.facebook_app_id
        if app_id
          @facebook_oauth_url = MiniFB.oauth_url(app_id,
                                                 "#{base_url}/sessions/create_facebook", # redirect url
                                                 :scope=>options[:scope].join(","))
        end
      end

      MOBILE_USER_AGENTS = 'palm|blackberry|nokia|phone|midp|mobi|symbian|chtml|ericsson|minimo|' +
          'audiovox|motorola|samsung|telit|upg1|windows ce|ucweb|astel|plucker|' +
          'x320|x240|j2me|sgh|portable|sprint|docomo|kddi|softbank|android|mmp|' +
          'pdxgw|netfront|xiino|vodafone|portalmmm|sagem|mot-|sie-|ipod|up\\.b|' +
          'webos|amoi|novarra|cdm|alcatel|pocket|ipad|iphone|mobileexplorer|' +
          'mobile'

      # SOME MOBILE STUFF FROM MOBILE_FU
      def is_mobile_device?
        request.user_agent.to_s.downcase =~ Regexp.new(MOBILE_USER_AGENTS)
      end

      def is_device?(type)
        request.user_agent.to_s.downcase.include?(type.to_s.downcase)
      end


    end

  end

end
