require 'test_helper'
require 'ebayr'
require 'webmock'

describe Ebayr do
  before do
    Ebayr.configure do |c|
      c.sandbox = true
      c.verify_tls_cert = false
      c.auth_token = nil
      c.oauth_token = nil
      c.oauth_token_getter = nil
    end
  end

  def check_common_methods(mod = Ebayr::Configuration.default)
    assert_respond_to mod, :dev_id
    assert_respond_to mod, :'dev_id='
    assert_respond_to mod, :cert_id
    assert_respond_to mod, :'cert_id='
    assert_respond_to mod, :ru_name
    assert_respond_to mod, :'ru_name='
    assert_respond_to mod, :auth_token
    assert_respond_to mod, :'auth_token='
    assert_respond_to mod, :compatability_level
    assert_respond_to mod, :'compatability_level='
    assert_respond_to mod, :site_id
    assert_respond_to mod, :'site_id='
    assert_respond_to mod, :sandbox
    assert_respond_to mod, :'sandbox='
    assert_respond_to mod, :sandbox?
    assert_respond_to mod, :authorization_callback_url
    assert_respond_to mod, :'authorization_callback_url='
    assert_respond_to mod, :authorization_failure_url
    assert_respond_to mod, :'authorization_failure_url='
    assert_respond_to mod, :callbacks
    assert_respond_to mod, :'callbacks='
    assert_respond_to mod, :logger
    assert_respond_to mod, :'logger='
    assert_respond_to mod, :uri
    assert_respond_to mod, :convert_integers
    assert_respond_to mod, :'convert_integers='
  end

  # If this passes without an exception, then we're ok.
  describe "basic usage" do
    before do
      WebMock.stub_request(:post, Ebayr.configuration.uri).to_return(status: 200, body: xml, headers: {})
      WebMock.enable!
    end
    date = Time.now.iso8601
    let(:xml) { "<GeteBayOfficialTimeResponse><Ack>Succes</Ack><Timestamp>#{date}</Timestamp></GeteBayOfficialTimeResponse>" }

    it "runs without exceptions" do
      _(Ebayr.call(:GeteBayOfficialTime).timestamp).must_equal date
    end
  end

  it "correctly reports its sandbox status" do
    config = Ebayr::Configuration.default
    config.sandbox = false
    _(config).wont_be :sandbox?
    config.sandbox = true
    _(config).must_be :sandbox?
  end

  it "has the right sandbox URIs" do
    config = Ebayr::Configuration.default
    _(config).must_be :sandbox?
    _(config.uri_prefix).must_equal "https://api.sandbox.ebay.com/ws"
    _(config.uri_prefix("blah")).must_equal "https://blah.sandbox.ebay.com/ws"
    _(config.uri.to_s).must_equal "https://api.sandbox.ebay.com/ws/api.dll"
  end

  it "has the right real-world URIs" do
    config = Ebayr::Configuration.default
    config.sandbox = false
    _(config.uri_prefix).must_equal "https://api.ebay.com/ws"
    _(config.uri_prefix("blah")).must_equal "https://blah.ebay.com/ws"
    _(config.uri.to_s).must_equal "https://api.ebay.com/ws/api.dll"
    config.sandbox = true
  end

  it "has the right methods" do
    check_common_methods
  end

  it "has decent defaults" do
    config = Ebayr::Configuration.default
    _(config).must_be :sandbox?
    _(config.uri.to_s).must_equal "https://api.sandbox.ebay.com/ws/api.dll"
    _(config.logger).must_be_kind_of Logger
    _(config.compatability_level).must_equal 1325
    _(config.site_id).must_equal 0
    _(config.callbacks[:before_request]).must_equal []
    _(config.callbacks[:on_error]).must_equal []
    _(config.authorization_callback_url).must_equal "https://example.com/"
  end

  it "correctly reports its site_id" do
    config = Ebayr::Configuration.default
    _(config.site_id).must_equal 0
    config.site_id = 77
    _(config.site_id).must_equal 77
    config.site_id = 0
  end
end
