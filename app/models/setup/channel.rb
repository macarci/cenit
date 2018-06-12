module Setup
  class Channel
    include CenitScoped
    include NamespaceNamed
    include CustomTitle
    include ClassHierarchyAware
    include RailsAdmin::Models::Setup::ChannelAdmin

    abstract_class true

    belongs_to :data_type, class_name: Setup::DataType.to_s, inverse_of: nil
  end
end