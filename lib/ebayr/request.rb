# frozen_string_literal: true

module Ebayr # :nodoc:
  # Encapsulates a request which is sent to the eBay Trading API.
  class Request
    # The Configuration object holding settings to be used in the API client.
    attr_accessor :config

    attr_reader :command

    # Make a new call. The URI used will be that of Ebayr::uri, unless
    # overridden here (same for auth_token, site_id and compatability_level).
    def initialize(command, options = {}, config = Configuration.default)
      @config = config
      @command = self.class.camelize(command.to_s)
      @uri = options.delete(:uri) || @config.uri
      @uri = URI.parse(@uri) unless @uri.is_a? URI
      @auth_token = (options.delete(:auth_token) || @config.auth_token).to_s
      @oauth_token = (options.delete(:oauth_token) || @config.oauth_token_with_refresh).to_s
      @site_id = (options.delete(:site_id) || @config.site_id).to_s
      @compatability_level = (options.delete(:compatability_level) || @config.compatability_level).to_s
      @http_timeout = (options.delete(:http_timeout) || @config.http_timeout).to_i
      # Remaining options are converted and used as input to the call
      @input = options.delete(:input) || options
    end

    def input_xml
      self.class.xml(@input)
    end

    # Gets the path to which this request will be posted
    def path
      @uri.path
    end

    # Gets the headers that will be sent with this request.
    def headers
      {
        'X-EBAY-API-COMPATIBILITY-LEVEL' => @compatability_level.to_s,
        'X-EBAY-API-DEV-NAME' => @config.dev_id.to_s,
        'X-EBAY-API-APP-NAME' => @config.app_id.to_s,
        'X-EBAY-API-CERT-NAME' => @config.cert_id.to_s,
        'X-EBAY-API-CALL-NAME' => @command.to_s,
        'X-EBAY-API-SITEID' => @site_id.to_s,
        'X-EBAY-API-IAF-TOKEN' => @oauth_token,
        'Content-Type' => 'text/xml'
      }.reject { |_k, v| v.nil? || v.empty? }
    end

    # Gets the body of this request (which is XML)
    def body
      <<-XML
        <?xml version="1.0" encoding="utf-8"?>
        <#{@command}Request xmlns="urn:ebay:apis:eBLBaseComponents">#{requester_credentials_xml}#{input_xml}</#{@command}Request>
      XML
    end

    # Returns eBay requester credential XML unless @oauth_token is present
    def requester_credentials_xml
      return '' if @oauth_token&.length&.positive?
      return '' unless @auth_token&.length&.positive?

      <<-XML
      <RequesterCredentials>
        <eBayAuthToken>#{@auth_token}</eBayAuthToken>
      </RequesterCredentials>
      XML
    end

    # Makes a HTTP connection and sends the request, returning an
    # Ebayr::Response
    def send
      http = Net::HTTP.new(@uri.host, @uri.port)
      http.read_timeout = @http_timeout
      http.set_debug_output(@config.logger) if @config.debug

      if @uri.port == 443
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE unless @config.verify_tls_cert
      end

      post = Net::HTTP::Post.new(@uri.path, headers)
      post.body = body

      response = http.start { |conn| conn.request(post) }

      @response = Response.new(self, response)
    end

    def to_s
      "#{@command}[#{@input}] <#{@uri}>"
    end

    # A very, very simple XML serializer.
    #
    #     Ebayr.xml("Hello!")       # => "Hello!"
    #     Ebayr.xml(:foo=>"Bar")  # => <foo>Bar</foo>
    #     Ebayr.xml(:foo=>["Bar","Baz"])  # => <foo>Bar</foo>
    def self.xml(*args)
      args.map do |structure|
        case structure
        when Hash then serialize_hash(structure)
        when Array then structure.map { |v| xml(v) }.join
        else serialize_input(structure).to_s
        end
      end.join
    end

    def self.serialize_hash(hash)
      hash.map do |k, v|
        if v.is_a?(Hash) && v.key?(:value) && v.key?(:attr)
          serialize_hash_with_attr(k, v)
        elsif v.is_a?(Array)
          serialize_array(k, v)
        else
          "<#{k}>#{xml(v)}</#{k}>"
        end
      end.join
    end

    # Converts an array to multiple xml nodes
    # {:foo=>["Bar", "baz"]}
    # gives <foo>Bar</foo><foo>baz</foo>
    def self.serialize_array(key, array)
      result = ""
      array.each do |value|
        result += "<#{key}>#{xml(value)}</#{key}>"
      end
      result
    end

    # Converts a hash with attributes to a tag
    # {:foo=>{:value=>"Bar", :attr=>{:name=>"baz"}}}
    # gives <foo name="baz">Bar</foo>
    def self.serialize_hash_with_attr(key, value)
      attr = value[:attr].map { |k_attr, v_attr| "#{k_attr}=\"#{v_attr}\"" }.join
      "<#{key} #{attr}>#{xml(value[:value])}</#{key}>"
    end

    # Prepares an argument for input to an eBay Trading API XML call.
    # * Times are converted to ISO 8601 format
    def self.serialize_input(input)
      case input
      when Time then input.to_time.utc.iso8601
      else input
      end
    end

    # Converts a command like get_ebay_offical_time to GeteBayOfficialTime
    def self.camelize(string)
      string = string.to_s
      return string unless string == string.downcase

      string.split('_').map(&:capitalize).join.gsub('Ebay', 'eBay')
    end

    # Gets a HTTP connection for this request. If you pass in a block, it will
    # be run on that HTTP connection.
    def http(&)
      http = Net::HTTP.new(@uri.host, @uri.port)
      if @uri.port == 443
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      return http.start(&) if block_given?

      http
    end
  end
end
