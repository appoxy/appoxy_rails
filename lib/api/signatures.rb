module Appoxy
    module Api
        module Signatures


            def self.generate_timestamp(gmtime)
                return gmtime.strftime("%Y-%m-%dT%H:%M:%SZ")
            end


            def self.generate_signature(operation, timestamp, secret_key)
                my_sha_hmac = Digest::HMAC.digest(operation + timestamp, secret_key, Digest::SHA1)
                my_b64_hmac_digest = Base64.encode64(my_sha_hmac).strip
                return my_b64_hmac_digest
            end


            def self.hash_to_s(hash)
                str = ""
                hash.each_pair {|key, value| str+= "#{key}#{value}" }
                #removing all characters that could differ after parsing with rails
                return str.delete "\"\/:{}[]\' T"
            end
        end
    end
end
