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

        @email = params[:email]
        if @email.blank?
          flash[:error] = "You must enter a valid email address."
          render :action=>"new"
          return
        end

        @has_password = params[:has_password]
        #puts 'has_pass? ' + @has_password.inspect
        @az_style = params[:az_style]

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
          user.last_login = Time.now
          user.save(:dirty=>true)
          flash[:info] = "Logged in successfully."
          after_create
        else
          flash[:error] = "Invalid email or password. Please try again."
          render :action => 'new'
        end
      end

      # Return false to stop before creating.
      def before_create

      end

      def after_create
        orig_url = session[:return_to]
        puts 'orig_url = ' + orig_url.to_s
        session[:return_to] = nil
        if !orig_url.nil?
          redirect_to orig_url # if entered via a different url
        end
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

        @newpass = random_string(8)

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

      def openid_start

        begin
          identifier = params[:openid_identifier]
          if identifier.nil?
            flash[:warning] = "There is no openid identifier."
            redirect_to root_path
            return
          end
          oidreq = consumer.begin(identifier)
        rescue OpenID::OpenIDError => e
          flash[:error] = "Discovery failed for #{identifier}: #{e}"
          redirect_to root_path
          return
        end
        if true || params[:use_ax]
          sregreq = OpenID::AX::FetchRequest.new
          sregreq.add(OpenID::AX::AttrInfo.new("http://schema.openid.net/contact/email", "email", true))
          oidreq.add_extension(sregreq)
          oidreq.return_to_args['did_ax'] = 'y'
        end
        if params[:use_sreg]
          sregreq = OpenID::SReg::Request.new
          # required fields
          sregreq.request_fields(['email', 'nickname'], true)
          # optional fields
          sregreq.request_fields(['dob', 'fullname'], false)
          oidreq.add_extension(sregreq)
          oidreq.return_to_args['did_sreg'] = 'y'
        end
        if params[:use_pape]
          papereq = OpenID::PAPE::Request.new
          papereq.add_policy_uri(OpenID::PAPE::AUTH_PHISHING_RESISTANT)
          papereq.max_auth_age = 2*60*60
          oidreq.add_extension(papereq)
          oidreq.return_to_args['did_pape'] = 'y'
        end
        if params[:force_post]
          oidreq.return_to_args['force_post']='x'*2048
        end
        return_to = base_url + "/sessions/openid_complete"
        realm = base_url

        puts 'about to redirect'

        if oidreq.send_redirect?(realm, return_to, params[:immediate])
          url = oidreq.redirect_url(realm, return_to, params[:immediate])
          puts 'yep, redirecting to ' + url
#                response["x-test-yo"] = "fuck me"
          redirect_to url
        else
          haml oidreq.html_markup(realm, return_to, params[:immediate], {'id' => 'openid_form'})
        end
#            dump_flash

      end


      def openid_complete

        return if before_create == false

        temp1 = session

        current_url = base_url + "/sessions/openid_complete" # url_for(:action => 'complete', :only_path => false)
        puts 'current_url=' + current_url.inspect
        puts 'path_params=' + request.path_parameters.inspect
        parameters = params.reject { |k, v| request.path_parameters[k.to_sym] }
        puts 'PARAMETERS=' + parameters.inspect
        oidresp = consumer.complete(parameters, current_url)
        puts 'oidresp=' + oidresp.inspect
        user_data = {}
        case oidresp.status
          when OpenID::Consumer::FAILURE
            if oidresp.display_identifier
              flash[:error] = ("Verification of #{oidresp.display_identifier} failed: #{oidresp.message}")
            else
              flash[:error] = "Verification failed: #{oidresp.message}"
            end
          when OpenID::Consumer::SUCCESS
            logger.info ("Verification of #{oidresp.display_identifier} succeeded.")

            user_data[:open_id] = oidresp.identity_url
            if params[:did_ax]
              sreg_resp = OpenID::AX::FetchResponse.from_success_response(oidresp)
              sreg_message = "AX Registration data was requested"
              if sreg_resp.data.empty?
                sreg_message << ", but none was returned."
              else
                sreg_message << ". The following data were sent:"
                sreg_resp.data.each { |k, v|
                  sreg_message << "<br/><b>#{k}</b>: #{v}"
                }
                user_data[:email] = sreg_resp.data["http://schema.openid.net/contact/email"][0]
              end
              puts sreg_message
            end
            if params[:did_sreg]
              sreg_resp = OpenID::SReg::Response.from_success_response(oidresp)
              sreg_message = "Simple Registration data was requested"
              if sreg_resp.empty?
                sreg_message << ", but none was returned."
              else
                sreg_message << ". The following data were sent:"
                sreg_resp.data.each { |k, v|
                  sreg_message << "<br/><b>#{k}</b>: #{v}"
                }

              end
              puts sreg_message
            end
            if params[:did_pape]
              pape_resp = OpenID::PAPE::Response.from_success_response(oidresp)
              pape_message = "A phishing resistant authentication method was requested"
              if pape_resp.auth_policies.member? OpenID::PAPE::AUTH_PHISHING_RESISTANT
                pape_message << ", and the server reported one."
              else
                pape_message << ", but the server did not report one."
              end
              if pape_resp.auth_time
                pape_message << "<br><b>Authentication time:</b> #{pape_resp.auth_time} seconds"
              end
              if pape_resp.nist_auth_level
                pape_message << "<br><b>NIST Auth Level:</b> #{pape_resp.nist_auth_level}"
              end
              puts pape_message
            end
            # todo: CREATE A USER FOR THIS PROJECT HERE WITH IDENITY AND EMAIL
            user = create_or_update_user(user_data)
            if user
              flash[:success] = "Authentication successful."
            end

          when OpenID::Consumer::SETUP_NEEDED
            flash[:warning] = "Immediate request failed - Setup Needed"
          when OpenID::Consumer::CANCEL
            flash[:warning] = "OpenID transaction cancelled."
          else
        end
#            dump_flash
#        return_to = session[:return_to]
#        puts 'return_to=' + return_to.inspect
#        redirect_to (return_to || after_login_url || root_path)


      end

      def create_facebook
        return if before_create == false
        if facebook_auth(::Rails.application.config.facebook_app_id,
                         ::Rails.application.config.facebook_secret)
          after_create

        end
      end

      def facebook_auth(app_id, app_secret, options={})
        p params
        redirect_uri = options[:redirect_uri] || "#{base_url}/sessions/create_facebook"
        code = params['code'] # Facebooks verification string
        if code
          access_token_hash = MiniFB.oauth_access_token(app_id,
                                                        redirect_uri,
                                                        app_secret,
                                                        code)
          #            p access_token_hash
          @access_token = access_token_hash["access_token"]
          unless @access_token
            flash[:warning] = "Authentication did not work, no access_token"
            redirect_to :action=>"new"
            return
          end

          session[:access_token] = @access_token

          me = MiniFB.get(@access_token, "me")
          puts 'me=' + me.inspect
          @user = User.find_by_fb_id(me.id)
          new_user = @user.nil?
          if new_user
            @user = User.create(:fb_id =>me.id,
                                :email =>me.email,
                                :first_name =>me.first_name,
                                :last_name =>me.last_name,
                                :fb_access_token=>@access_token,
                                :status =>"active")


          else
            @user.email = me.email
            @user.fb_access_token = @access_token
            @user.first_name = me.first_name
            @user.last_name = me.last_name
            @user.status = "active"
            #                @user.fake = false
            @user.save(:dirty=>true)
          end

          after_save_setup @user

        end
      end


      def oauth_start(key, secret, callback_url, site, request_token_path, authorize_path, access_token_path, options={})
        consumer = oauth_consumer(key, secret,
                                  callback_url,
                                  site,
                                  request_token_path,
                                  authorize_path,
                                  access_token_path,
                                  options
        )
        @request_token = consumer.get_request_token(:oauth_callback => callback_url)
        session[:request_token] = @request_token
        auth_url = @request_token.authorize_url(:oauth_callback => callback_url)
        puts auth_url.inspect
        redirect_to auth_url
      end

      def twitter_auth
        signin = true
        callback_url = "#{base_url}/sessions/#{(signin ? "create_twitter" : "create_twitter_oauth")}"
        auth_path = signin ? "authenticate" : "authorize"
        consumer = oauth_start(::Rails.application.config.twitter_consumer_key, ::Rails.application.config.twitter_consumer_secret,
                               callback_url,
                               "https://server_api.twitter.com",
                               "/oauth/request_token",
                               "/oauth/#{auth_path}",
                               "/oauth/access_token"
        )
      end

      # OAUTH VERSION for oauthing, shouldn't be in this controller
      def create_twitter_oauth
        puts 'params=' + params.inspect
        @request_token = session[:request_token]
        @access_token = @request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
        puts 'access_token = ' + @access_token.inspect

        token = OauthToken.find_by_user_id_and_site_and_type(current_user.id, @access_token.consumer(:signin=>true).site, "access")
        puts 'found token? ' + token.inspect
        unless token
          token = OauthToken.new(:type =>"access",
                                 :user =>current_user,
                                 :site =>@access_token.consumer.site,
                                 :token =>@access_token.token,
                                 :secret=>@access_token.secret)
          token.save!
        else
          token.token = @access_token.token
          token.secret = @access_token.secret
          token.save(:dirty=>true)
        end
        @token = token

        flash[:success] = "Authorized with Twitter."

      end

      def get_oauth_access_token
        @request_token = session[:request_token]
        @access_token = @request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
        puts 'access_token = ' + @access_token.inspect
        p @access_token.params
        @access_token
      end

      def create_twitter
        return if before_create == false
        puts 'params=' + params.inspect
        get_oauth_access_token()

        @user = User.find_by_twitter_id(@access_token.params[:user_id])
        unless @user
          @user = User.new(# shouldn't set this, because can't say it will be unique ':username =>@access_token.params[:screen_name],
          :twitter_screen_name=>@access_token.params[:screen_name],
          :twitter_id =>@access_token.params[:user_id])
          @user.set_remember
          @user.save
          puts '@user=' + @user.inspect
        else
          @user.username = @access_token.params[:screen_name]
          @user.set_remember
          @user.save(:dirty=>true)
        end

        after_save_setup @user

        flash[:success] = "Authorized with Twitter."

        after_create

      end

      def google_oauth

      end

      private

      def after_save_setup(user)
        if user.errors.present?
          flash[:error] = "Error saving user: #{user.errors.full_messages}"
          return false
        else
          set_user_cookies(user)
#          after_create
          return user
        end
      end

      def create_or_update_user(user_data)
        user = User.find_by_email(user_data[:email]) # google returns different openid all the time so using email User.find_by_openid user_data[:openid]

        unless user
          user = User.new(user_data)
          user.set_remember
          user.save
        else
          if user.email.nil? || user.email != user_data[:email]
            user.email = user_data[:email]
          end
#          if user.remember_me.nil? || user.remember_me_expires.nil? || user.remember_me_expires < Time.now
#            logger.debug "Remember me expired."
#            user.remember_me         = user_data[:remember_me]
#            user.remember_me_expires = 30.days.since
#          end
          user.set_remember
          user.save(:dirty=>true)
        end

#        puts 'user=' + user.inspect
        return after_save_setup(user)
      end

      def set_user_cookies(user)
        set_current_user(user)
        response.set_cookie('user_id', :value => user.id, :expires => user.remember_token_expires.to_time)
        response.set_cookie('rme', :value=>user.remember_token, :expires => user.remember_token_expires.to_time)
      end


      # todo: allow user to specify store type in options
      def openid_consumer(options={})
        @openid_consumer ||= OpenID::Consumer.new(session,
                                                  OpenID::Store::Filesystem.new("/mnt/tmp/openid"))
        # todo: add S3Store to appoxy_sessions
        #            @openid_consumer ||= OpenID::Consumer.new(session,
        #                                                      S3Store.new(S3BucketWrapper.new(context, main_bucket)))
      end


      def oauth_consumer(key, secret, callback, site, request_token_path, authorize_path, access_token_path, options={})
        params = {:site => site,
                  :oauth_callback => callback,
                  :request_token_path => request_token_path,
                  :authorize_path => authorize_path,
                  :access_token_path => access_token_path}
        params[:signature_method] = options[:signature_method] if options[:signature_method]
        params[:scheme] = options[:scheme] if options[:scheme]

        @consumer = OAuth::Consumer.new(key,
                                        secret,
                                        params)
        p @consumer
        @consumer
      end


    end
  end
end