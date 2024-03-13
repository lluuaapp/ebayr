# frozen_string_literal: true

module Ebayr
  class Configuration
    # To make a call, you need to have a registered user and app. Then you must
    # fill in the <code>dev_id</code>, <code>app_id</code>, <code>cert_id</code>
    # and <code>ru_name</code>. You will also need an <code>auth_token</code>,
    # though you may use any user's token here.
    # See http://developer.ebay.com/DevZone/XML/docs/HowTo/index.html for more
    # details.
    attr_accessor :dev_id, :app_id, :cert_id, :ru_name, :auth_token, :oauth_token

    # Defines a Proc used to fetch or refresh access tokens (Bearer) used with OAuth2.
    # Overrides the oauth_token if set
    # @return [Proc]
    attr_accessor :oauth_token_getter

    # The eBay Site to use for calls. The full list of available sites can be
    # retrieved with <code>GeteBayDetails(:DetailName => "SiteDetails")</code>
    attr_accessor :site_id

    # eBay Trading API version to use. For more details, see
    # http://developer.ebay.com/devzone/xml/docs/HowTo/eBayWS/eBaySchemaVersioning.html
    attr_accessor :compatability_level

    attr_accessor :http_timeout, :verify_tls_cert, :logger, :debug

    def debug?
      !!debug
    end

    # Determines whether to use the eBay sandbox or the real site.
    attr_accessor :sandbox

    def sandbox?
      !!sandbox
    end

    # enable this if you want strings that only contains integers to be converted to ints (via to_i)
    attr_accessor :convert_integers

    def convert_integers?
      !!convert_integers
    end

    # Set to true to generate fancier objects for responses (will decrease
    # performance).
    attr_accessor :normalize_responses

    def normalize_responses?
      !!normalize_responses
    end

    # This URL is used to redirect the user back after a successful registration.
    # For more details, see here:
    # http://developer.ebay.com/DevZone/XML/docs/WebHelp/wwhelp/wwhimpl/js/html/wwhelp.htm?context=eBay_XML_API&topic=GettingATokenViaFetchToken
    attr_accessor :authorization_callback_url

    # This URL is used if the authorization process fails - usually because the user
    # didn't click 'I agree'. If you leave it nil, the
    # <code>authorization_callback_url</code> will be used (but the parameters will be
    # different).
    attr_accessor :authorization_failure_url

    # Callbacks which are invoked at various points throughout a request.
    attr_accessor :callbacks

    def initialize
      @dev_id = nil
      @app_id = nil
      @cert_id = nil
      @ru_name = nil
      @auth_token = nil
      @oauth_token = nil
      @site_id = 0
      @compatability_level = 1325
      @http_timeout = 60
      @verify_tls_cert = true
      @sandbox = true
      @convert_integers = false
      @normalize_responses = false
      @authorization_callback_url = 'https://example.com/'
      @authorization_failure_url = 'https://example.com/'
      @callbacks = {
        before_request: [],
        after_request: [],
        before_response: [],
        after_response: [],
        on_error: []
      }

      @logger = Logger.new($stdout)
      @logger.level = Logger::INFO
      @debug = false

      yield(self) if block_given?
    end

    # The default Configuration object.
    def self.default
      @@default ||= Configuration.new
    end

    def configure
      yield(self) if block_given?
    end

    # Gets access_token using access_token_getter or uses the static access_token
    def oauth_token_with_refresh
      return oauth_token if oauth_token_getter.nil?

      oauth_token_getter.call
    end

    # Gets either ebay.com/ws or sandbox.ebay.com/ws, as appropriate, with
    # "service" prepended. E.g.
    #
    #     Ebayr.configuration.uri_prefix("blah")  # => https://blah.ebay.com/ws
    #     Ebayr.configuration.uri_prefix          # => https://api.ebay.com/ws
    def uri_prefix(service = 'api')
      "https://#{service}#{sandbox ? '.sandbox' : ''}.ebay.com/ws"
    end

    # Gets the URI used for API calls (as a URI object)
    def uri(*args)
      URI.parse("#{uri_prefix(*args)}/api.dll")
    end

    # Gets the URI for eBay authorization/login. The session_id should be obtained
    # via an API call to GetSessionID (be sure to use the right ru_name), and the
    # ru_params can contain anything (they will be passed back to your app in the
    # redirect from eBay upon successful login and authorization).
    def authorization_uri(session_id, ru_params = {})
      ruparams = CGI.escape(ru_params.map { |k, v| "#{k}=#{v}" }.join('&'))
      URI.parse("#{uri_prefix('signin')}/eBayISAPI.dll?SignIn&RuName=#{ru_name}&SessId=#{session_id}&ruparams=#{ruparams}")
    end
  end
end
