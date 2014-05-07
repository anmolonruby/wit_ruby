## client.rb
## Facilitates the secure connection between the Wit servers and ruby application.
## Quite confusing as Net::HTTP and Net::HTTPs is a messy library.
## Do look it up if you need more help understanding!

module Wit
  module REST
    ## Wit::Session::Client class holds the authentication parameters and
    ## handles making the HTTP requests to the Wit API. These methods should be
    ## internally called and never called directly from the user.

    ## An example call to instantiate client is done like this with defaults:
    ##
    ## => @client = Wit::Session:Client.new
    ##
    class Client

      ## Default settings for the client connection to the Wit api.
      DEFAULTS = {
          :token => ENV["WIT_AI_TOKEN"],
          :addr => 'api.wit.ai',
          :port => 443,
          :use_ssl => true,
          :ssl_verify_peer => true,
          :ssl_ca_file => File.dirname(__FILE__) + '/../../../conf/cacert.pem',
          :timeout => 30,
          :proxy_addr => nil,
          :proxy_port => nil,
          :proxy_user => nil,
          :proxy_pass => nil,
          :retry_limit => 1,
      }

      ## Allows for the reading of the last request, last response, and the
      ## current session.
      attr_reader :last_req, :last_response, :session

      ## Initialize the new instance with either the default parameters or
      ## given parameters.
      ## Token is either the set token in ENV["WIT_AI_TOKEN"] or given in the
      ## options.
      def initialize(options = {})
        ## Token is overidden if given in set params.
        @params = DEFAULTS.merge options
        @auth_token = @params[:token].strip
        setup_conn
        setup_session
      end


      ## Change the given auth token.
      def change_auth(new_auth)
        @auth_token = new_auth.strip
      end

      ## Defines each REST method for the given client. GET, PUT, POST and DELETE
      [:get, :put, :post, :delete].each do |rest_method|
        ## Get the given class for Net::HTTP depending on the current method.
        method_rest_class = Net::HTTP.const_get rest_method.to_s.capitalize

        ## Define the actual method for Wit::Session:Client
        define_method rest_method do |path|#|path, params|
          request = method_rest_class.new path, {"Authorization" => "Bearer #{@auth_token}"}
          #request.set_form_data(params)#params if [:post, :put].include?(rest_method)
          return connect_send(request)
        end
      end

#################################
      private

      ## Setup the session that allows for calling of
      def setup_session
        @session = Wit::REST::Session.new(self)
      end

      ## Used to setup a connection using Net::HTTP object when making requests
      ## to the API.
      def setup_conn

        ## Setup connection through the @conn instance variable and proxy if
        ## if given.
        @conn = Net::HTTP.new(@params[:addr], @params[:port],
          @params[:proxy_addr], @params[:proxy_port],
          @params[:proxy_user], @params[:proxy_pass]
          )
        setup_ssl
        ## Set timeouts
        @conn.open_timeout = @params[:timeout]
        @conn.read_timeout = @params[:timeout]
      end

      ## Setup SSL for the given connection in @conn.
      def setup_ssl
        @conn.use_ssl = @params[:use_ssl]
        if @params[:ssl_verify_peer]
          @conn.verify_mode = OpenSSL::SSL::VERIFY_PEER
          @conn.ca_file = @params[:ssl_ca_file]
        else
          @conn.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
      end

      ## Connect and send the given request to Wit server.
      def connect_send(request)
        ## Set the last request parameter
        @last_req = request
        ## Set the retries if necessary to send again.
        left_retries = @params[:retry_limit]
        ## Start sending request
        begin
          ## Save last response and depending on the response, return back the
          ## given body as a hash.
          response = @conn.request request
          @last_response = response
          case response.code
            when "200" then Wit::REST::Result.new(MultiJson.load response.body)
            when "401" then raise Unauthorized, "Incorrect token or not set. Set ENV[\"WIT_AI_TOKEN\"] or pass into the options parameter as :token"
            #else raise BadResponse, "response code: #{response.status}"
          end

        end
      end


    end
  end
end