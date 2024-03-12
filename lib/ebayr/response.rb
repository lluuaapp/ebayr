# frozen_string_literal: true

module Ebayr # :nodoc:
  # A response to an Ebayr::Request.
  class Response < Record
    def initialize(request, response)
      @request = request
      @command = @request.command if @request
      @response = response
      @body = response.body if @response
      hash = self.class.from_xml(@body) if @body
      response_data = hash["#{@command}Response"] if hash
      super(response_data) if response_data
    end

    def to_struct(struct_name)
      Struct.new(struct_name, *keys).new(*values)
    end

    class << self
      def from_xml(xml_io)
        puts xml_io if Ebayr.debug == true

        result = LibXML::XML::Parser.io(StringIO.new(xml_io))
        result = result.parse
        return { result.root.name => xml_node_to_hash(result.root) }
      end

      def xml_node_to_hash(node)
        # If we are at the root of the document, start the hash
        return prepare(node.content.to_s) unless node.element?

        result_hash = {}
        if node.attributes.length.positive?
          result_hash[:attributes] = {}
          node.attributes.each do |key|
            result_hash[:attributes][key.name.to_sym] = prepare(key.value)
          end
        end

        return result_hash unless node.children.size.positive?

        node.children.each do |child|
          result = xml_node_to_hash(child)

          if child.name == 'text'
            unless child.next || child.prev
              return prepare(result) unless result_hash[:attributes]

              # this helps us add attributes into the result hash (e.g. currency of an amount)
              result_hash['value'] = prepare(result)
              return result_hash
            end
          elsif result_hash[child.name.to_sym]
            if result_hash[child.name.to_sym].is_a?(Object::Array)
              result_hash[child.name.to_sym] << prepare(result)
            else
              result_hash[child.name.to_sym] = [result_hash[child.name.to_sym]] << prepare(result)
            end
          else
            result_hash[child.name.to_sym] = prepare(result)
          end
        end

        return result_hash
      end

      def prepare(data)
        return data unless Ebayr.convert_integers

        data.instance_of?(String) && data.to_i.to_s == data ? data.to_i : data
      end
    end
  end
end
