require 'test_helper'
require 'ostruct'
require 'ebayr/response'

# rubocop:disable Style/OpenStructUse

describe Ebayr::Response do
  it "builds objects from XML" do
    xml = "<GetSomethingResponse><Foo>Bar</Foo></GetSomethingResponse>"
    response = Ebayr::Response.new(
      OpenStruct.new(command: 'GetSomething', config: Ebayr::Configuration.default),
      OpenStruct.new(body: xml)
    )
    _(response['Foo']).must_equal 'Bar'
    _(response.foo).must_equal 'Bar'
  end
  it "handes responses" do
    xml = "<GeteBayResponse><eBayFoo>Bar</eBayFoo></GeteBayResponse>"
    response = Ebayr::Response.new(
      OpenStruct.new(command: 'GeteBay', config: Ebayr::Configuration.default),
      OpenStruct.new(body: xml)
    )
    _(response.ebay_foo).must_equal 'Bar'
  end
  it "handles responses with many html entities" do
    xml = "<GeteBayResponse><eBayFoo>Bar</eBayFoo><Description>#{'<p class="p1"><span class="s1"><br/></span></p>' * 5000}</Description></GeteBayResponse>"
    response = Ebayr::Response.new(
      OpenStruct.new(command: 'GeteBay', config: Ebayr::Configuration.default),
      OpenStruct.new(body: xml)
    )
    _(response.ebay_foo).must_equal 'Bar'
  end

  def test_response_nesting
    response_nesting_convert_integers(true)
    response_nesting_convert_integers(false)
  end

  def response_nesting_convert_integers(convert)
    Ebayr::Configuration.default.convert_integers = convert
    item_ids = %w[
      905477661122
      805477661122
      705477661122
    ]
    xml = <<-XML
      <GetOrdersResponse>
        <OrdersArray>
          <Order>
            <OrderID>1</OrderID>
            <ItemID>905477661122</ItemID>
          </Order>
          <Order>
            <OrderID>2</OrderID>
            <ItemID>805477661122</ItemID>
          </Order>
          <Order>
            <OrderID>3</OrderID>
            <ItemID>705477661122</ItemID>
          </Order>
        </OrdersArray>
      </GetOrdersResponse>
    XML
    response = Ebayr::Response.new(
      OpenStruct.new(command: 'GetOrders', config: Ebayr::Configuration.default),
      OpenStruct.new(body: xml)
    )
    assert_kind_of Hash, response.orders_array

    if convert
      (0..2).each do |i|
        _(response.orders_array.order[i].order_id).must_equal(i + 1)
        _(response.orders_array.order[i].item_id).must_equal item_ids[i].to_i
        _(response.orders_array.order[i].item_id).must_be :positive?
      end
    else
      (0..2).each do |i|
        _(response.orders_array.order[i].order_id).must_equal (i + 1).to_s
        _(response.orders_array.order[i].item_id).must_equal item_ids[i]
      end
    end
  end
end

# rubocop:enable Style/OpenStructUse
