# frozen_string_literal: true

require 'test_helper'
require 'ebayr/record'

module Ebayr
  class RecordTest < Minitest::Test
    def test_lookup_is_case_insensitive
      record = Record.new('Foo' => 'Bar')
      assert_equal 'Bar', record['Foo']
    end

    def test_records_are_nested
      record = Record.new(Foo: { 'Bar' => 'Baz' })
      assert_equal 'Baz', record.foo.bar

      record = Record.new('Foo' => { 'Bars' => [{ 'Value' => 1 }, { 'Value' => 2 }] })
      assert_equal 1, record.foo.bars[0].value
      assert_equal 2, record.foo.bars[1].value
    end

    def test_key_is_available
      str_key = 'Bar'
      sym_key = :sym_bar
      record = Record.new({ str_key => 'Baz', sym_key => 'Foo' })

      assert_respond_to record, :key?
      assert record.key?(sym_key), "Record does not have symbol '#{sym_key}'."
      assert record.key?(str_key), "Record does not have '#{str_key}'."

      %w[
        EBay
        ItemID
        Order
        GetSellerList
        VerifyAddFixedPriceItem
        CompleteSale
        GetSuggestedCategories
      ].each do |k|
        assert_equal k.ebayr_underscore.gsub("e_bay", 'ebay').to_sym, Record.convert_key(k)
      end
    end
  end
end
