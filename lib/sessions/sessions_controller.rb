module Appoxy

  module Sessions

    #
    # logout_session_path
    module SessionsController

      require 'openid/store/filesystem'
      require 'openid/extensions/ax'


      def self.included(base)
        puts 'SessionsController included'
#        base.helper_method :facebook_oauth_url

      end

      # Todo: have a configuration block for this so user can set things like facebook_api_key and facebook_secret
      def new

      end

      def create
        return if before_create == false

        # recaptchas should be optional
#                unless verify_recaptcha
#                    flash[:error] = "You are not human! Please try again."
#                    render :action=>"forgot_password"
#                    return
#                end

        logout_keeping_session!

        @email        = params[:email]
        if @email.blank?
          flash[:error] = "You must enter a valid email address."
          render :action=>"new"
          return
        end

        @has_password = params[:has_password]
        #puts 'has_pass? ' + @has_password.inspect
        @az_style     = params[:az_style]

        if @az_style
          if params[:has_password].blank?
            flash[:error] = "Please click the radio button to let us know if you have a password or not."
            render :action=>"new"
            return
          end
          if @has_password == "true"

          else
            # new user
            redirect_to (new_user_path + "?email=#{@email}")
          end
        end

        user = ::User.find_by_email(@email)
#                    user = User.authenticate(@email, params[:password])
        if user && user.authenticate(params[:password])
          self.current_user = user
          flash[:info]      = "Logged in successfully."
          orig_url          = session[:return_to]
          puts 'orig_url = ' + orig_url.to_s
          session[:return_to] = nil
          if !orig_url.nil?
            redirect_to orig_url # if entered via a different url
          else
            after_create
          end
          user.last_login = Time.now
          user.save(:dirty=>true)
        else
          flash[:error] = "Invalid email or password. Please try again."
          render :action => 'new'
        end
      end

      # Return false to stop before creating.
      def before_create

      end

      def after_create

      end

      def reset_password
        before_reset_password


        @email = params[:email]
        unless User.email_is_valid? @email
          flash[:error] = "You must enter a valid email."
          render :action=>"forgot_password"
          return
        end

        @user = ::User.find_by_email(@email)
        unless @user
          flash[:error] = "Email not found."
          render :action=>"forgot_password"
          return
        end

        @newpass       = random_string(8)

        @user.password = @newpass
        @user.save(:dirty=>true)

        flash[:success] = "Password reset. You should receive an email shortly with a new password."
        redirect_to :action=>"new"

        after_reset_password
      end

      def before_reset_password

      end

      # This is a great spot to send an email with the new password (the only spot actually).
      def after_reset_password

      end

      def destroy
        @current_user = nil
        reset_session
        flash[:info] = "You have been logged out."
        redirect_to root_url
      end

      def logout
        destroy
      end


      def create_facebook
        if facebook_auth(Rails.application.config.facebook_app_id,
                         Rails.application.config.facebook_secret)
          after_create

        end
      end

      def facebook_auth(app_id, app_secret, options={})
        p params
        redirect_uri = options[:redirect_uri] || "#{base_url}/sessions/create_facebook"
        code         = params['code'] # Facebooks verification string
        if code
          access_token_hash = MiniFB.oauth_access_token(app_id,
                                                        redirect_uri,
                                                        app_secret,
                                                        code)
          #            p access_token_hash
          @access_token     = access_token_hash["access_token"]
          unless @access_token
            flash[:warning] = "Authentication did not work, no access_token"
            redirect_to :action=>"new"
            return
          end

          session[:access_token] = @access_token

          me                     = MiniFB.get(@access_token, "me")
          puts 'me=' + me.inspect
          @user    = User.find_by_fb_id(me.id)
          new_user = @user.nil?
          if new_user
            @user = User.create(:fb_id          =>me.id,
                                :email          =>me.email,
                                :first_name     =>me.first_name,
                                :last_name      =>me.last_name,
                                :fb_access_token=>@access_token,
                                :status         =>"active")


          else
            @user.email           = me.email
            @user.fb_access_token = @access_token
            @user.first_name      = me.first_name
            @user.last_name       = me.last_name
            @user.status          = "active"
            #                @user.fake = false
            @user.save(:dirty=>true)
          end
          session[:user_id] = @user.id
          @user

        end
      end


    end
  end
end