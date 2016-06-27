module Setup
  module NamespaceNamed
    extend ActiveSupport::Concern

    include DynamicValidators
    include CustomTitle

    included do
      field :namespace, type: String
      field :name, type: String, default: ''

      validates_presence_of :name
      validates_uniqueness_of :name, scope: :namespace

      before_save do
        self.namespace =
          if namespace.nil?
            ''
          else
            namespace.strip
          end
        self.name = name.to_s.strip
        # unless Account.current_super_admin?
        #   errors.add(:namespace, 'is reserved') if Cenit.reserved_namespaces.include?(namespace.downcase)
        # end TODO Delete comment
        errors.blank?
      end

      after_save do
        Setup::Optimizer.regist_ns(namespace)
      end
    end

    def namespace_enum
      enum = Setup::Namespace.all.asc(:name).collect(&:name)
      enum << namespace unless enum.include?(namespace)
      enum
    end

    def scope_title
      namespace
    end

    def namespace_ns
      if @namespace_ns.nil? || @namespace_ns.name != namespace
        @namespace_ns = Setup::Namespace.find_or_create_by(name: namespace)
      end
      @namespace_ns
    end

    def namespace_ns=(namespace_ns)
      @namespace_ns = namespace_ns
      self.namespace = namespace_ns.name if namespace != namespace_ns.name
    end
  end
end