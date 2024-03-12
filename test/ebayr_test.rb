require 'test_helper'
require 'ebayr'
require 'webmock'

describe Ebayr do
  before { Ebayr.sandbox = true }

  def check_common_methods(mod = Ebayr)
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
  end

  # If this passes without an exception, then we're ok.
  describe "basic usage" do
    before do
      WebMock.stub_request(:post, Ebayr.uri).to_return(status: 200, body: xml, headers: {})
      WebMock.enable!
    end
    date = Time.now.iso8601
    let(:xml) { "<GeteBayOfficialTimeResponse><Ack>Succes</Ack><Timestamp>#{date}</Timestamp></GeteBayOfficialTimeResponse>" }

    it "runs without exceptions" do
      _(Ebayr.call(:GeteBayOfficialTime).timestamp).must_equal date
    end
  end

  it "correctly reports its sandbox status" do
    Ebayr.sandbox = false
    _(Ebayr).wont_be :sandbox?
    Ebayr.sandbox = true
    _(Ebayr).must_be :sandbox?
  end

  it "has the right sandbox URIs" do
    _(Ebayr).must_be :sandbox?
    _(Ebayr.uri_prefix).must_equal "https://api.sandbox.ebay.com/ws"
    _(Ebayr.uri_prefix("blah")).must_equal "https://blah.sandbox.ebay.com/ws"
    _(Ebayr.uri.to_s).must_equal "https://api.sandbox.ebay.com/ws/api.dll"
  end

  it "has the right real-world URIs" do
    Ebayr.sandbox = false
    _(Ebayr.uri_prefix).must_equal "https://api.ebay.com/ws"
    _(Ebayr.uri_prefix("blah")).must_equal "https://blah.ebay.com/ws"
    _(Ebayr.uri.to_s).must_equal "https://api.ebay.com/ws/api.dll"
    Ebayr.sandbox = true
  end

  it "works when as an extension" do
    mod = Module.new { extend Ebayr }
    check_common_methods(mod)
  end

  it "works as an inclusion" do
    mod = Module.new { extend Ebayr }
    check_common_methods(mod)
  end

  it "has the right methods" do
    check_common_methods
  end

  it "has decent defaults" do
    _(Ebayr).must_be :sandbox?
    _(Ebayr.uri.to_s).must_equal "https://api.sandbox.ebay.com/ws/api.dll"
    _(Ebayr.logger).must_be_kind_of Logger
    _(Ebayr.compatability_level).must_equal 1325
    _(Ebayr.site_id).must_equal 0
    _(Ebayr.callbacks[:before_request]).must_equal []
    _(Ebayr.callbacks[:on_error]).must_equal []
    _(Ebayr.authorization_callback_url).must_equal "https://example.com/"
  end

  it "extended class has decent defaults" do
    cls = Class.new { extend Ebayr }
    _(cls).must_be :sandbox?
    _(cls.uri.to_s).must_equal "https://api.sandbox.ebay.com/ws/api.dll"
    _(cls.logger).must_be_kind_of Logger
    _(cls.compatability_level).must_equal 1325
    _(cls.site_id).must_equal 0
    _(cls.callbacks[:before_request]).must_equal []
    _(cls.callbacks[:on_error]).must_equal []
    _(cls.authorization_callback_url).must_equal "https://example.com/"
  end

  it "included class has decent defaults" do
    cls = Class.new { include Ebayr }
    _(cls).must_be :sandbox?
    _(cls.uri.to_s).must_equal "https://api.sandbox.ebay.com/ws/api.dll"
    _(cls.logger).must_be_kind_of Logger
    _(cls.compatability_level).must_equal 1325
    _(cls.site_id).must_equal 0
    _(cls.callbacks[:before_request]).must_equal []
    _(cls.callbacks[:on_error]).must_equal []
    _(cls.authorization_callback_url).must_equal "https://example.com/"
  end

  it "correctly reports its site_id" do
    _(Ebayr.site_id).must_equal 0
    Ebayr.site_id = 77
    _(Ebayr.site_id).must_equal 77
  end
end
