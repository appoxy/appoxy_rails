module Appoxy

  module Sessions
    module UsersController

      def self.included(base)
        puts 'UsersController included'
        # Initialize module.
        base.protect_from_forgery :except => [:location, :timezone]

      end

      def new
        before_new
        if params[:id]
          @user = ::User.find params[:id]
        else
          @user = ::User.new
          @user.email = params[:email] if params[:email]
        end
        @user.activation_code = params[:ac] if params[:ac]
        after_new
      end

      def before_new

      end

      def after_new

      end

      def create

        before_create

        @user = ::User.new(params[:user])

        if @user.password != params[:password_confirmation]
          flash[:error] = "Confirmation password does not match. Please try again."
          render :action=>"new"
          return
        end

        if params[:user][:password].length < 6
          flash[:error] = "Password can not be less than 6 characters."
          render :action=>"new"
          return
        end

        existing_user = ::User.find_by_email(@user.email)

        if existing_user
          if params[:ac]

          end
          # todo: remove activation_code on user
          if @user.activation_code.present?
            # hasn't logged in yet, probably invited, need to check access key
            if existing_user.activation_code == @user.activation_code
              existing_user.activate!
              existing_user.password = @user.password
              @user                  = existing_user
            end
          else
            flash[:error] = "The email you entered already exists in our system. You might want to try logging in if you already have an account."
            render :action=>"new"
            return
          end
        else
          @user.status = "active"
        end

        before_save_in_create
        if @user.save
          self.current_user = @user
          flash[:success]   = "Your account was created successfully."
          after_save_in_create
          after_create
        else
          render :action => "new"
        end

      end

      def before_create

      end

      def before_save_in_create

      end

      def after_save_in_create

      end

      def after_create

      end


      # Usually a user gets here via an activation link in email.
      def activate
        logout_keeping_session!
        @user = ::User.find_by_activation_code(params[:ac]) unless params[:ac].blank?
        case
          when (!params[:ac].blank?) && @user && !@user.is_active?
            flash[:info] = "Account activated. please login."
            @user.activate!
            redirect_to login_url
          when params[:ac].blank?
            flash[:error] = "The activation code was missing.  Please follow the URL from your email."
            redirect_to(root_url)
          else
            flash[:error] = "We couldn't find a user with that activation code -- check your email? Or maybe you've already activated -- try signing in."
            redirect_to(root_url)
        end
      end

      # To use this, add "post 'timezone'" to a member resources :users in routes.rb
      # Also, be sure you have <%= appoxy_footer in view %>
      def timezone
        ret = {}
        if logged_in?
          puts 'SET TIMEZONE ' + params.inspect
          tz = ActiveSupport::TimeZone[params[:offset].to_i]
          if tz
            puts 'tz=' + tz.name
            current_user.time_zone = tz.name
            current_user.save(:dirty=>true)
            ret[:timezone] = tz.name
          end
        end
        render :json=>ret
      end

      def geo_location
        puts 'updating users location'
        ret = {}
        if current_user
          current_user.update_position(params[:lat], params[:lng])
          ret[:status]="success"
        else
          logger.info("Could not update user location because no current_user")
          ret[:status]="failed"
          ret[:msg] = "No user"
        end
        render :json=>ret
      end

    end


  end


end

