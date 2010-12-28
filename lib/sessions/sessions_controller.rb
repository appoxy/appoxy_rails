module Appoxy

    module Sessions

        module SessionsController

            # Todo: have a configuration block for this so user can set things like facebook_api_key and facebook_secret

            def new

            end

            def create
                before_create

                # recaptchas should be optional
#                unless verify_recaptcha
#                    flash[:error] = "You are not human! Please try again."
#                    render :action=>"forgot_password"
#                    return
#                end

                logout_keeping_session!

                @email        = params[:email]
                @has_password = params[:has_password]
                #puts 'has_pass? ' + @has_password.inspect

                if params[:has_password].blank?
                    flash[:error] = "Please click the radio button to let us know if you have a password or not."
                    render :action=>"new"
                    return
                end

                if @has_password == "true"
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
                        flash[:info] = "Invalid email or password. Please try again."
                        render :action => 'new'
                    end
                else
                    # new user
                    redirect_to (new_user_path + "?email=#{@email}")
                end
            end

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
                logout
            end

            def logout
                @current_user = nil
                reset_session
                flash[:info] = "You have been logged out."
                redirect_to('/')
            end


        end
    end
end