module Setup
  class Namespace
    include CenitScoped
    include Slug

   build_in_data_type.referenced_by(:name)

    field :name, type: String

    before_validation do
      self.name =
        if name.nil?
          ''
        else
          name.strip
        end.strip
    end

    after_save do
      if (old_name = changed_attributes['name'])
        #TODO Refactor namespace name on setup models
      end
    end

    validates_uniqueness_of :name

    def set_schemas_scope(schemas)
      @schemas_scope = {}
      schemas.each { |schema| @schemas_scope[schema.uri] = schema }
    end

    def schema_for(base_uri, relative_uri)
      uri = Cenit::Utility.abs_uri(base_uri, relative_uri)
      if (schema = @schemas_scope[uri])
        schema
      else
        Setup::Schema.where(namespace: name, uri: uri).first
      end
    end
  end
end
