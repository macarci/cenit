module Setup
  class Authorization
    include CenitScoped
    include NamespaceNamed
    include ClassHierarchyAware

    abstract_class true

    BuildInDataType.regist(self).referenced_by(:namespace, :name)

    def authorized?
      fail NotImplementedError
    end

    def method_missing(symbol, *args)
      hashes = []
      if symbol.to_s.start_with?('all_')
        suffix = symbol.to_s.from('all_'.length).singularize
        fields.each { |field| hashes << self.class.send('auth_' + field.pluralize) if field.end_with?(suffix) }
      elsif field = CONFIG_FIELDS.detect { |field| "each_#{field}" == symbol.to_s.singularize }
        hashes << self.class.send('auth_' + field.pluralize)
      end if block_given?
      if hashes.present?
        args = args.unshift(self)
        hashes.each do |hash|
          hash.each do |key, value_access|
            value =
              if value_access.respond_to?(:call)
                value_access.call(*args)
              else
                send(value_access)
              end
            yield(key, value)
          end
        end
      else
        super
      end
    end

    class << self

      def method_missing(symbol, *args)
        if CONFIG_FIELDS.any? { |field| "auth_#{field.pluralize}" == symbol.to_s }
          ivar = "@#{symbol}".to_sym
          if args.length > 0
            instance_variable_set(ivar, args[0].stringify_keys)
          end
          value = instance_variable_get(ivar) || {}
          if superclass == Object
            value
          else
            superclass.send(symbol).merge(value)
          end
        else
          super
        end
      end
    end

    CONFIG_FIELDS = %w(header template_parameter parameter)

    CONFIG_FIELDS.each { |field| send("auth_#{field.pluralize}", {}) }
  end
end