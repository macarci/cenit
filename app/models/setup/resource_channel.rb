module Setup
  class ResourceChannel
    include CenitScoped
    include NamespaceNamed
    include CustomTitle
    include Parameters
    include RailsAdmin::Models::Setup::ResourceChannelAdmin

    build_in_data_type.and(properties: { pagination: { type: {} } }).excluding(:pagination_attrs).referenced_by(:namespace, :name)

    belongs_to :operation, class_name: Setup::Operation.to_s, inverse_of: nil

    parameters :parameters, :headers, :template_parameters

    belongs_to :response_type, class_name: Setup::DataType.to_s, inverse_of: nil
    belongs_to :item_type, class_name: Setup::DataType.to_s, inverse_of: nil

    field :pagination_schema, type: Symbol
    field :pagination_attrs, type: Hash, default: {}

    before_save :validates_configuration

    def set_pagination_defaults
      if operation
        self.pagination_schema ||= pagination_model.default_pagination_schema
        self.response_type ||= pagination_model.default_response_type
        self.item_type ||= pagination_model.default_item_type
      end
    end

    def set_default_params
      if operation
        hash = {}
        operation.params_stack.each do |entity|
          self.class.parameters_relations_names.each do |relation_name|
            next unless (params = entity.try(relation_name)).present?
            group_hash = (hash[relation_name] ||= {})
            params.each { |param| group_hash[param.key] = param.value }
          end
        end
        self.class.parameters_relations_names.each do |relation_name|
          send(relation_name).each { |param| hash.delete(param.key) }
        end
        hash.each do |relation_name, params|
          relation = send(relation_name)
          params.each do |key, value|
            relation.new(key: key, value: value)
          end
        end
      end
    end

    def validates_configuration
      errors.add(:operation, "can't be blank!") unless operation
      if pagination_attrs.present?
        pagination.validate
      else
        errors.add(:pagination, "can't be blank!") unless pagination_schema == :none
      end
      errors.add(:pagination, pagination.errors.full_messages.to_sentence) if pagination.errors.present?
      errors.blank?
    end

    def write_attribute(name, value)
      if name.to_s == 'pagination_attrs'
        value.delete('_type')
        value.delete(:_type)
        value.keep_if { |k, v| Cenit::Utility.json_object?(v) && v.present? && pagination_model.property?(k) }
      end
      r = super
      if name.to_s == 'pagination_schema' && pagination_model.key != value
        @pagination = @mongoff_model = nil
        pagination_model.schema
      end
      r
    end

    def assign_attributes(attrs = nil)
      r = super
      set_pagination_defaults
      set_default_params unless persisted? || self.class.parameters_relations_names.any? do |param|
        param = "#{param}_attributes"
        attrs.key?(param) || attrs.key?(param.to_sym)
      end
      r
    end

    def ready_to_save?
      (operation && pagination_schema).present?
    end

    def pagination(options = {})
      if operation
        @pagination ||= pagination_model.new(pagination_attrs)
      else
        @pagination = nil
      end
    end

    def set_relation(name, relation)
      r = super
      if operation
        if @lazy_pagination
          self.pagination = @lazy_pagination
        else
          pagination
        end
      end
      r
    end

    def pagination=(data)
      unless data.is_a?(Hash)
        data =
          if data.is_a?(String)
            JSON.parse(data)
          else
            data.try(:to_json) || {}
          end
      end
      if operation
        @pagination = pagination_model.new_from_json(data)
        if @pagination.is_a?(Hash)
          self.pagination_attrs = @pagination
          @pagination = nil
        else
          self.pagination_attrs = @pagination.attributes
        end
        @lazy_pagination = nil
      else
        @lazy_pagination = data
      end
    end

    def pagination_attributes=(attrs)
      @pagination = pagination_model.new(attrs)
      self.pagination_attrs = @pagination.attributes
    end

    def pagination_model
      if operation
        if @mongoff_model && @mongoff_model.operation != operation
          @mongoff_model = nil
        end
        @mongoff_model ||= PaginationModel.for(channel: self, cache: false)
      else
        @mongoff_model = nil
        Mongoff::Model.for(data_type: self.class.data_type,
                           schema: {},
                           name: "#{self.class.pagination_model_name}Default",
                           cache: false)
      end
    end

    def association_for_pagination
      @pagination_association ||= PaginationAssociation.new(self)
    end

    def reflect_on_association(name)
      if name == :pagination
        association_for_pagination
      else
        super
      end
    end

    def share_hash(options = {})
      hash = super
      if (pagination = hash['pagination'])
        pagination.delete('id')
      end
      hash
    end

    class << self

      def pagination_model_name
        "#{self}::Pagination"
      end

      def stored_properties_on(record)
        super + ['pagination']
      end

      def for_each_association(&block)
        super
        block.yield(name: :pagination, embedded: true, many: false)
      end

      def pagination_schema_enum
        PAGINATION_SCHEMA
      end

      PAGINATION_SCHEMA = {
        'By page token': :page_token
      }
    end

    class PaginationAssociation < Mongoff::Association

      attr_reader :owner

      def initialize(owner)
        super(owner.class, :pagination, :embeds_one)
        @owner = owner
      end

      def klass
        owner.pagination_model
      end
    end

    class PaginationModel < Mongoff::Model

      attr_reader :channel, :key, :ns_dt, :default_response_type, :default_pagination_schema, :default_item_type

      def operation
        channel.operation
      end

      def ns_dt
        @ns_dt ||= channel.response_type ||
          Setup::DataType.where(namespace: operation.namespace).first || operation.class.data_type
      end

      def proto_schema
        required = []
        properties = {}
        if operation.metadata.is_a?(Hash) && (responses = operation.metadata['responses'])
          if (success_response = responses['200'])
            response_schema = success_response['schema'] || {}
            _, @default_response_type = Mongoff::Model.check_referenced_schema(response_schema, ns_dt)
          end
        end
        response_schema ||= {}
        response_schema = ns_dt.merge_schema(response_schema)
        if (@key = channel.pagination_schema)
          response_schema = ns_dt.merge_schema(response_schema)
          schema = send("process_#{channel.pagination_schema}_response", response_schema)
          properties.merge!(schema[:properties])
          required.concat(schema[:required])
        else
          @default_pagination_schema = :page_token
        end
        sch = {
          'type' => 'object',
          'properties' => properties
        }
        unless required.empty?
          sch['required'] = required
        end
        sch
      end

      def process_page_token_response(response_schema)
        sch = { properties: properties = {}, required: required = [] }
        if response_schema['type'] == 'object' && (response_properties = response_schema['properties']).is_a?(Hash)
          enums = Hash.new { |h, k| h[k] = [] }
          response_properties.each do |property, schema|
            next unless schema.is_a?(Hash)
            case schema['type']
            when 'array'
              enums[:items]
            when 'string'
              enums[:page_token]
            when 'number', 'integer'
              enums[:numbers]
            else
              enums[:others]
            end << property
          end
          properties['items'] = {
            'description' => 'The entry in the response schema to take items',
            'type' => 'string',
            'enum' => enums[:items]
          }
          unless enums[:items].empty?
            properties['items']['default'] = enums[:items].first
            _, @default_item_type = Mongoff::Model.check_referenced_schema(response_schema['properties'][enums[:items].first], ns_dt)
          end
          properties['next_page_token'] = {
            'description' => 'The entry in the response schema to take the next page token',
            'type' => 'string',
            'enum' => enums[:page_token]
          }
          unless enums[:items].empty?
            properties['next_page_token']['default'] = enums[:page_token].first
          end
          properties['page_token_parameter'] = {
            'description' => 'The page token parameter',
            'type' => 'string',
            'enum' => param_enum = operation.parameters.select { |p| p.meta_type == :string }.collect(&:key)
          }
          unless param_enum.empty?
            properties['page_token_parameter']['default'] =
              param_enum.detect { |p| p.downcase['pagetoken'] } ||
                param_enum.detect { |p| p.downcase['page'] } ||
                param_enum.detect { |p| p.downcase['token'] } ||
                param_enum.first
          end
          properties['total'] = {
            'description' => 'The entry in the response schema to take the total number of items',
            'type' => 'string',
            'enum' => enums[:numbers]
          }
          unless enums[:numbers].empty?
            properties['total']['default'] = enums[:numbers].first
          end
          required << 'items'
          required << 'next_page_token'
          required << 'page_token_parameter'
        end
        sch
      end

      class << self

        def for(options)
          channel = options[:channel]
          options[:data_type] ||= channel.operation.class.try(:data_type)
          model = super
          model.instance_variable_set(:@channel, channel)
          model
        end
      end
    end
  end
end
