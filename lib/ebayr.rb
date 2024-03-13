# frozen_string_literal: true

require 'logger'
require 'net/https'
require 'time'
require 'libxml'

# A library to assist in using the eBay Trading API.
module Ebayr
  autoload :Record,         File.expand_path('ebayr/record',        __dir__)
  autoload :Request,        File.expand_path('ebayr/request',       __dir__)
  autoload :Response,       File.expand_path('ebayr/response',      __dir__)
  autoload :Configuration,  File.expand_path('ebayr/configuration', __dir__)

  class << self
    # Customize default settings for the SDK using block.
    #   Ebayr.configure do |config|
    #     config.app_id = "my-ebay-app-id"
    #     config.cert_id = "my-ebay-cert-id"
    #   end
    # If no block given, return the default Configuration object.
    def configure
      if block_given?
        yield(Configuration.default)
      else
        Configuration.default
      end
    end

    # Perform an eBay call (symbol or string). You can pass in these arguments:
    #
    # auth_token:: to use a user's token instead of the general token
    # site_id:: to use a specific eBay site (default is 0, which is US ebay.com)
    # compatability_level:: declare another eBay Trading API compatability_level
    #
    # All other arguments are passed into the API call, and may be nested.
    #
    #     response = call(:GeteBayOfficialTime)
    #     response = call(:get_ebay_official_time)
    #
    # See Ebayr::Request for details.
    #
    # The response is a special Hash of the response, deserialized from the XML
    #
    #     response.timestamp     # => 2010-10-10 10:00:00 UTC
    #     response[:timestamp]   # => 2010-10-10 10:00:00 UTC
    #     response['Timestamp']  # => "2012-10-10T10:00:00.000Z"
    #     response[:Timestamp]   # => "2012-10-10T10:00:00.000Z"
    #     response.ack           # "Success"
    #     response.success?      # true
    #
    #  See Ebayr::Response for details.
    #
    #  To see a list of available calls, check out
    #  http://developer.ebay.com/DevZone/XML/docs/Reference/ebay/index.html
    def call(command, arguments = {}, config = Configuration.default)
      Request.new(command, arguments, config).send
    end

    def configuration
      Configuration.default
    end
  end
end
