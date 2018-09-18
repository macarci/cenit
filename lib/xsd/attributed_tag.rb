module Xsd
  class AttributedTag < BasicTag

    def initialize(args)
      super
      @xmlns = { }
      args[:attributes].each do |attr|
        if attr[0] == 'xmlns'
          @xmlns[:default] = attr[1]
        elsif attr[0] =~ /\Axmlns:/
          @xmlns[attr[0].from(attr[0].index(':') + 1)] = attr[1]
        end
      end
    end

    def tag_name
      self.class.try(:tag_name)
    end

    def xmlns(ns)
      @xmlns[ns] || super
    end

    def attributeValue(name, attributes)
      name = name.to_s
      (a = attributes.detect { |a| a[0] == name }) ? a[1] : nil
    end
  end
end