require 'test_helper'
require 'ebayr/request'

describe Ebayr::Request do
  before do
    Ebayr.configure do |c|
      c.sandbox = true
      c.verify_tls_cert = false
      c.auth_token = nil
      c.oauth_token = nil
      c.oauth_token_getter = nil
    end
  end

  describe "serializing input" do
    it "converts times" do
      result = Ebayr::Request.serialize_input(Time.utc(2010, 'oct', 31, 3, 15))
      _(result).must_equal "2010-10-31T03:15:00Z"
    end
  end

  describe "uri" do
    it "is the Ebayr one" do
      _(Ebayr::Request.new(:Blah).config.uri).must_equal(Ebayr::Configuration.default.uri)
    end
  end

  describe "arrays" do
    it "converts multiple arguments in new function" do
      args = [{ a: 1 }, { a: { b: [1, 2] } }]
      _(Ebayr::Request.new(:Blah, input: args).input_xml).must_equal '<a>1</a><a><b>1</b><b>2</b></a>'
    end

    it "converts times" do
      args = [{ Time: Time.utc(2010, 'oct', 31, 3, 15) }]
      result = Ebayr::Request.new(:Blah, args).input_xml
      _(result).must_equal "<Time>2010-10-31T03:15:00Z</Time>"
    end
  end

  describe "xml" do
    def request(*args)
      Ebayr::Request.xml(*args)
    end

    it "convets a hash" do
      _(request(a: { b: 123 })).must_equal '<a><b>123</b></a>'
    end

    it "converts a hash with attributes" do
      hash = { b: { value: 123, attr: { name: 'c' } } }
      _(request(hash)).must_equal '<b name="c">123</b>'
    end

    it "converts an array" do
      _(request([{ a: 1 }, { a: 2 }])).must_equal "<a>1</a><a>2</a>"
    end

    it "converts a string" do
      _(request('boo')).must_equal 'boo'
    end

    it "converts a number" do
      _(request(1234)).must_equal '1234'
    end

    it "converts multiple arguments" do
      args = [{ a: 1 }, { a: { b: [1, 2] } }]
      _(request(*args)).must_equal '<a>1</a><a><b>1</b><b>2</b></a>'
    end

    describe "requester credentials" do
      it 'includes requester credentials when auth_token present' do
        my_token = "auth-token-123xyz"
        request = Ebayr::Request.new(:Blah, auth_token: my_token)
        _(request.body).must_include "<RequesterCredentials>", "</RequesterCredentials>"
        _(request.body).must_include "<eBayAuthToken>#{my_token}</eBayAuthToken>"
      end

      it 'excludes requester credentials when auth_token not present' do
        request = Ebayr::Request.new(:Blah, auth_token: nil)
        _(request.body).wont_include "<RequesterCredentials>", "</RequesterCredentials>"
        _(request.body).wont_include "<eBayAuthToken>", "</eBayAuthToken>"
      end

      it 'includes token header when oauth_token present' do
        my_token = "auth-token-123xyz"
        request = Ebayr::Request.new(:Blah, oauth_token: my_token)

        _(request.headers).must_include "X-EBAY-API-IAF-TOKEN"
        _(request.headers['X-EBAY-API-IAF-TOKEN']).must_equal my_token
      end

      it 'includes token header but no requester credentials when oauth_token and auth_token present (prefer oauth)' do
        my_token = "auth-token-123xyz"
        request = Ebayr::Request.new(:Blah, oauth_token: my_token, auth_token: my_token)

        _(request.headers).must_include "X-EBAY-API-IAF-TOKEN"
        _(request.headers['X-EBAY-API-IAF-TOKEN']).must_equal my_token
        _(request.body).wont_include "<RequesterCredentials>", "</RequesterCredentials>"
        _(request.body).wont_include "<eBayAuthToken>", "</eBayAuthToken>"
      end
    end
  end
end
