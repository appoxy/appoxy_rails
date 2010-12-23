module Appoxy

    module Api

        # The api controllers that use this should set:
#        protect_from_forgery :only => [] # can add methods to here, eg: :create, :update, :destroy

#                rescue_from SigError, :with => :send_error
#                rescue_from Api::ApiError, :with => :send_error
        # before_filter :verify_signature(params)

        # Your Controller must define a secret_key_for_signature method which will return the secret key to use to generate signature.

        module ApiController

            def verify_signature
                params2 = nil
                if request.put? || request.post?
                    # We'll extract params from body instead here
                    # todo: maybe check for json format first in case this is a file or something?
                    body = request.body.read
                    puts 'body=' + body.inspect
                    params2 = ActiveSupport::JSON.decode(body)
                    puts 'params2=' + params2.inspect
                    params.merge! params2
                end

                #operation = "#{controller_name}/#{action_name}"
                operation = request.env["PATH_INFO"].gsub(/\/api\//, "")# here we're getting original request url'
                puts "XXX " + operation

                #getting clean params (without parsed via routes)
                params_for_signature = params2||request.query_parameters
                #removing mandatory params
                params_for_signature = params_for_signature.delete_if {|key, value| ["access_key", "sigv", "sig", "timestamp"].include? key}


                #p "params " +operation+Appoxy::Api::Signatures.hash_to_s(params_for_signature)
                access_key = params["access_key"]
                sigv = params["sigv"]
                timestamp = params["timestamp"]
                sig = params["sig"]

                raise Appoxy::Api::ApiError, "No access_key" if access_key.nil?
                raise Appoxy::Api::ApiError, "No sigv" if sigv.nil?
                raise Appoxy::Api::ApiError, "No timestamp" if timestamp.nil?
                raise Appoxy::Api::ApiError, "No sig" if sig.nil?
                timestamp2 = Appoxy::Api::Signatures.generate_timestamp(Time.now.gmtime)
                raise Appoxy::Api::ApiError, "Request timed out!" unless (Time.parse(timestamp2)-Time.parse(timestamp))<60 # deny all requests older than 60 seconds
                sig2 = Appoxy::Api::Signatures.generate_signature(operation+Appoxy::Api::Signatures.hash_to_s(params_for_signature), timestamp, secret_key_for_signature(access_key))
                #p "signature 1 " + sig2 + " signature 2 " + sig
                raise Appoxy::Api::ApiError, "Invalid signature!" unless sig == sig2

                puts 'Verified OK'

            end


            def sig_should
                raise "You didn't define a sig_should method in your controller!"
            end


            def send_ok(msg={})
                response_as_string = '' # in case we want to add debugging or something
#                respond_to do |format|
                #                format.json { render :json=>msg }
                response_as_string = render_to_string :json => msg
                render :json => response_as_string
#                end
                true
            end


            def send_error(statuscode_or_error, msg=nil)
                exc = nil
                if statuscode_or_error.is_a? Exception
                    exc = statuscode_or_error
                    statuscode_or_error = 400
                    msg = exc.message
                end
                # deprecate status, should use status_code
                json_msg = {"status_code"=>statuscode_or_error, "msg"=>msg}
                render :json=>json_msg, :status=>statuscode_or_error
                true
            end


        end


        class ApiError < StandardError

            def initialize(msg=nil)
                super(msg)

            end

        end

    end

end
