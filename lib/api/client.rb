module Appoxy
    module Api

        require 'rest_client'

        # Subclass must define:
        #  host: endpoint url for service
        class Client

            attr_accessor :host, :access_key, :secret_key, :version


            def initialize(host, access_key, secret_key, options={})
                @host = host
                @access_key = access_key
                @secret_key = secret_key
            end


            def get(method, params={}, options={})
                begin
#                ClientHelper.run_http(host, access_key, secret_key, :get, method, nil, params)
                    parse_response RestClient.get(append_params(url(method), add_params(method, params)), headers)
                rescue RestClient::BadRequest => ex
#                    puts ex.http_body
                    raise "Bad Request: " + ActiveSupport::JSON.decode(ex.http_body)["msg"].to_s
                end
            end


            def post(method, params={}, options={})
                begin
                    parse_response RestClient.post(url(method), add_params(method, params).to_json, headers)
                    #ClientHelper.run_http(host, access_key, secret_key, :post, method, nil, params)
                rescue RestClient::BadRequest => ex
#                    puts ex.http_body
                    raise "Bad Request: " + ActiveSupport::JSON.decode(ex.http_body)["msg"].to_s
                end

            end


            def put(method, body, options={})
                begin
                    parse_response RestClient.put(url(method), add_params(method, body).to_json, headers)
                    #ClientHelper.run_http(host, access_key, secret_key, :put, method, body, nil)
                rescue RestClient::BadRequest => ex
#                    puts ex.http_body
                    raise "Bad Request: " + ActiveSupport::JSON.decode(ex.http_body)["msg"].to_s
                end
            end


            def delete(method, params={}, options={})
                begin
                    parse_response RestClient.delete(append_params(url(method), add_params(method, params)))
                rescue RestClient::BadRequest => ex
                    raise "Bad Request: " + ActiveSupport::JSON.decode(ex.http_body)["msg"].to_s
                end
            end


            def url(command_path)
                url = host + command_path
                url
            end


            def add_params(command_path, hash)
                v = version||"0.1"
                ts = Appoxy::Api::Signatures.generate_timestamp(Time.now.gmtime)
                # puts 'timestamp = ' + ts
                sig =  case v
                    when "0.2"
                        Appoxy::Api::Signatures.generate_signature(command_path + Appoxy::Api::Signatures.hash_to_s(hash), ts, secret_key)
                    when "0.1"
                        Appoxy::Api::Signatures.generate_signature(command_path, ts, secret_key)
                end

                extra_params = {'sigv'=>v, 'sig' => sig, 'timestamp' => ts, 'access_key' => access_key}
                hash.merge!(extra_params)

            end


            def append_params(host, params)
                host += "?"
                i = 0
                params.each_pair do |k, v|
                    host += "&" if i > 0
                    host += k + "=" + CGI.escape(v)
                    i+=1
                end
                return host
            end


            def headers
                user_agent = "Appoxy API Ruby Client"
                headers = {'User-Agent' => user_agent}
            end


            def parse_response(response)
                begin
                    return ActiveSupport::JSON.decode(response.to_s)
                rescue => ex
                    puts 'response that caused error = ' + response.to_s
                    raise ex
                end
            end


        end

    end
end