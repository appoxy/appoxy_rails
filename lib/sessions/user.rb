module Appoxy

  module Sessions

    class User < SimpleRecord::Base

      def self.included(base)
        puts self.name + " included in " + base.name
      end

      has_strings :email,
                  :username,
                  :open_id,
                  :twitter_id, :twitter_screen_name,
                  :fb_id, :fb_access_token,
                  {:name => :password, :hashed=>true},
                  :first_name,
                  :last_name,
                  :remember_token,
                  :activation_code,
                  :status, # invited, active
                  :oauth_access_key,
                  :oauth_secret_key,
                  :time_zone,
                  :lat, :lng

      has_dates :last_login,
                :remember_token_expires


      def validate
#        errors.add("email", "is not valid") unless User.email_is_valid?(email)

        if status == "invited"
          # doesn't need password
        elsif open_id
          # doesn't need password
        else
#          errors.add("password", "must be at least 6 characters long.") if password.blank?
        end
      end


      def self.email_is_valid?(email)
        return email.present? && email =~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
      end


      def is_active?
        status == "active"
      end


      def set_activation_code
        self.activation_code=Digest::SHA1.hexdigest(email.to_s+Time.now.to_s)
      end


      def activate!
        self.activation_code=nil
        self.status         = "active"
      end


      def authenticate(password)

        return nil if attributes["password"].blank? # if the user has no password (will this happen?  maybe for invites...)

        # This is a normal unencrypted password, temporary
        if attributes["password"][0].length < 100
          self.password = attributes["password"][0]
          self.save
        end

        (self.password == password) ? self : nil
      end

      def set_remember
        rme_string            = Appoxy::Utils.random_string(50)
        self.remember_token   = rme_string
        self.remember_token_expires = 30.days.since
      end


    end

  end

end

