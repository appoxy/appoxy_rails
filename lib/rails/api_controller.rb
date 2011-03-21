module Appoxy

  module Rails

    # The rails controllers that use this should set:
#        protect_from_forgery :only => [] # can add methods to here, eg: :create, :update, :destroy

#                rescue_from SigError, :with => :send_error
#                rescue_from Api::ApiError, :with => :send_error
    # before_filter :verify_signature(params)

    # Your Controller must define a secret_key_for_signature method which will return the secret key to use to generate signature.

    module ApiController

      def verify_signature
        params2 = nil
        if request.put? || (request.post? && !params["file"]) # we could not load binary in json
          # We'll extract params from body instead here
          # todo: maybe check for json format first in case this is a file or something?
          body = request.body.read
          puts 'body=' + body.inspect
          params2 = ActiveSupport::JSON.decode(body)
          puts 'params2=' + params2.inspect
          params.merge! params2
        end

        #operation = "#{controller_name}/#{action_name}"
        #operation = request.env["PATH_INFO"].gsub(/\/rails\//, "")# here we're getting original request url'

#                #getting clean params (without parsed via routes)
#                params_for_signature = params2||request.query_parameters
#                #removing mandatory params
#                params_for_signature = params_for_signature.delete_if {|key, value| ["access_key", "sigv", "sig", "timestamp"].include? key}


        #puts "params " +operation+Appoxy::Api::Signatures.hash_to_s(params_for_signature)
        access_key = params["access_key"]
        sigv = params["sigv"]
        timestamp = params["timestamp"]
        sig = params["sig"]
        signature = ""
        case sigv
          when "0.1"
#            puts "outdated version of client"
            signature = "#{controller_name}/#{action_name}"
          when "0.2"
#            puts "new version of client"
            operation = request.env["PATH_INFO"].gsub(/\/rails\//, "") # here we're getting original request url'
            params_for_signature = params2||request.query_parameters
            params_for_signature = params_for_signature.delete_if { |key, value| ["access_key", "sigv", "sig", "timestamp"].include? key }
            signature = operation+Appoxy::Api::Signatures.hash_to_s(params_for_signature)
        end
#                puts "signature " + signature
        raise Appoxy::Api::ApiError, "No access_key" if access_key.nil?
        raise Appoxy::Api::ApiError, "No sigv" if sigv.nil?
        raise Appoxy::Api::ApiError, "No timestamp" if timestamp.nil?
        raise Appoxy::Api::ApiError, "No sig" if sig.nil?
        gmtime = Time.now.gmtime
#        timestamp2 = Appoxy::Api::Signatures.generate_timestamp(gmtime)
        if timestamp.is_a?(String)
          timestamp_str = timestamp
          timestamp = Time.parse(timestamp)
        else
          timestamp_str = Appoxy::Api::Signatures.generate_timestamp(timestamp)
        end
        raise Appoxy::Api::ApiError, "Request timed out!" unless (gmtime - timestamp) < 60 # deny all requests older than 60 seconds
        sig2 = Appoxy::Api::Signatures.generate_signature(signature, timestamp_str, secret_key_for_signature(access_key))
        raise Appoxy::Api::ApiError, "Invalid signature!" unless sig == sig2

        puts 'Signature OK'

      end


      def sig_should
        raise "You didn't define a sig_should method in your controller!"
      end


      def send_ok(msg={})
        response_as_string = '' # in case we want to add debugging or something
#                respond_to do |format|
        #                format.json { render :json=>msg }
#                response_as_string = render_to_string :json => msg
        render :json => msg
#                end
        true
      end


      def send_error(statuscode_or_error, msg=nil)
        backtrace = nil
        if statuscode_or_error.is_a? Exception
          backtrace = statuscode_or_error.backtrace.to_s
          msg = statuscode_or_error.message
          statuscode_or_error = 500
        end
        # deprecate status, should use status_code
        json_msg = {"status_code"=>statuscode_or_error, "msg"=>msg, "backtrace"=>backtrace}
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
