module Setup
  class Parameter
    include CenitScoped
    include JsonMetadata
    include ChangedIf
    include RailsAdmin::Models::Setup::ParameterAdmin   

    build_in_data_type.with(:key, :value, :description, :metadata).referenced_by(:key)

    deny :copy, :new, :translator_update, :import, :convert, :send_to_flow

    field :key, type: String, as: :name
    field :description, type: String
    field :value

    validates_presence_of :key

    def meta_type
      (metadata['type'] || :string).to_sym
    end

    def to_s
      "#{key}: #{value}"
    end

    def parent_relation
      @parent_relation ||= reflect_on_all_associations(:belongs_to).detect { |r| send(r.name) }
    end

    def location
      (r = parent_relation) && r.inverse_name
    end

    def parent_model
      (r = parent_relation) && r.klass
    end

    def parent
      (r = parent_relation) && send(r.name)
    end

  end
end
