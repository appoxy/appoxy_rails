class OauthToken < SimpleRecord::Base

    belongs_to :user

    has_strings :type, # request or access
                :site,
                :token,
                :secret

#    has_clobs :access_token

end
