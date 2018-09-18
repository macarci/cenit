module Xsd
  class SimpleTypeRestriction < BasicTag
    include AttributeContainerTag

    tag 'restriction'

    attr_reader :base
    attr_reader :restrictions

    def initialize(args)
      super
      @base = args[:base]
      @restrictions = {}
      if (restrictions = args[:restrictions])
        restrictions.each { |key, value| @restrictions[key] = value }
      end
    end

    def start_element_tag(name, attributes)
      unless %w{annotation documentation}.include?(name)
        if name == 'enumeration'
          @restrictions[name] ||= []
          @restrictions[name] << attributes
        else
          if name == 'pattern'
            if (_pattern = @restrictions[name])
              attributes[0][1] = "(#{_pattern[0][1]})|(#{attributes[0][1]})"
            end
          end
          @restrictions[name] = attributes
        end
      end
      nil
    end

    def to_json_schema
      json = documenting(qualify_type_ref(base).to_json_schema)
      @restrictions.each do |key, value|
        restriction =
          case key
          when 'enumeration'
            enum = value.collect { |v| v[0][1] }.uniq
            type_cast =
              case json['type']
              when 'integer'
                :to_i
              when 'number'
                :to_f
              when 'boolean'
                :to_b
              when 'string'
                :to_s
              else
                nil # TODO Create a warning for enum type casting
              end
            enum = enum.map { |value| value && value.to_s.send(type_cast) } if type_cast
            { 'enum' => enum }
          when 'length'
            { 'minLength' => value[0][1].to_i, 'maxLength' => value[0][1].to_i }
          when 'pattern'
            { 'pattern' => value[0][1] }
          when 'minInclusive'
            { 'minimum' => value[0][1].to_i }
          when 'maxInclusive'
            { 'maximum' => value[0][1].to_i }
          when 'minExclusive'
            { 'minimum' => value[0][1].to_i, 'exclusiveMinimum' => true }
          when 'maxExclusive'
            { 'maximum' => value[0][1].to_i, 'exclusiveMaximum' => true }
          # when 'fractionDigits' # TODO Include totalDigits fractionDigits in the validator
          #   { 'multipleOf' => 1.0 / (10 ** value[0][1].to_i) }
          # when 'totalDigits'
          #   { 'maximum' => 10 ** value[0][1].to_i - 1 }
          else
            #TODO simpleType and whiteScpace restrictions
            { (key = key.gsub('xs:', '')) => value[0][1].to_i } unless value.empty?
          end
        json = json.merge(restriction) if restriction
      end
      json
    end

  end
end