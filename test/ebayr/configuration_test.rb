require 'test_helper'
require 'ostruct'
require 'ebayr/configuration'
require 'ebayr/request'

describe Ebayr::Configuration do
  before do
    Ebayr.configure do |c|
      c.sandbox = true
      c.verify_tls_cert = false
      c.auth_token = nil
      c.oauth_token = nil
      c.oauth_token_getter = nil
    end
  end

  it "uses correct auth token" do
    Ebayr.configure do |c|
      c.auth_token = "auth_token"
      c.oauth_token = "oauth_token"
      c.oauth_token_getter = lambda {
        "oauth_token_getter"
      }
    end

    request = Ebayr::Request.new(:Blah)
    _(Ebayr.configuration.oauth_token_with_refresh).must_equal "oauth_token_getter"
    _(request.headers['X-EBAY-API-IAF-TOKEN']).must_equal "oauth_token_getter"

    _(request.body).wont_include "<RequesterCredentials>", "</RequesterCredentials>"
    _(request.body).wont_include "<eBayAuthToken>", "</eBayAuthToken>"

    Ebayr.configure do |c|
      c.auth_token = "auth_token"
      c.oauth_token = "oauth_token"
      c.oauth_token_getter = nil
    end

    request = Ebayr::Request.new(:Blah)
    _(Ebayr.configuration.oauth_token_with_refresh).must_equal "oauth_token"
    _(request.headers['X-EBAY-API-IAF-TOKEN']).must_equal "oauth_token"
    _(request.body).wont_include "<RequesterCredentials>", "</RequesterCredentials>"
    _(request.body).wont_include "<eBayAuthToken>", "</eBayAuthToken>"

    Ebayr.configure do |c|
      c.auth_token = "auth_token"
      c.oauth_token = nil
      c.oauth_token_getter = nil
    end

    request = Ebayr::Request.new(:Blah)
    _(request.headers['X-EBAY-API-IAF-TOKEN']).must_be_nil
    _(request.body).must_include ">auth_token<"
    _(request.body).must_include "<RequesterCredentials>", "</RequesterCredentials>"
    _(request.body).must_include "<eBayAuthToken>", "</eBayAuthToken>"
  end
end
