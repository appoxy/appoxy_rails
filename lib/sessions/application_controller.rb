module Appoxy

  module Sessions
    module ApplicationController

      def self.included(base)
        # Initialize module.
        helper_method :logged_in?
        helper_method :current_user
        helper_method :base_url
      end


      protected


      def logout_keeping_session!
        @current_user     = nil # not logged in, and don't do it for me
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
        @current_user ||= (login_from_session)
        @current_user
      end


      def login_from_session
        #puts 'Login from session=' + session[:user_id].inspect
        ::User.find_by_id(session[:user_id]) if session[:user_id]
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
        chars    = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789'
        password = ''
        length.times { password << chars[rand(chars.size)] }
        password
      end

      def authenticate
        if !logged_in?
          flash[:warning]     = "You need to login to access this page."
          session[:return_to] = request.request_uri # return to after logging in
          puts "ac=" + params[:ac].inspect
          if params[:user_id] && params[:ac]
            # todo: should we store ac in cookie?  Make it easier to pass around
            cookies[:ac] = params[:ac]
            # then from an invite
            user         = ::User.find(params[:user_id])
            if user && user.password.blank? # is this the best way to decide of user has not logged in? Could also check status.
              redirect_to :controller=>"users", :action=>"new", :email=>user.email, :ac=>params[:ac]
              return
            end
          end
          redirect_to :controller=>"sessions", :action=>"new", :ac=>params[:ac]
        end

        after_authenticate

      end

      def after_authenticate

      end


    end

  end

end
