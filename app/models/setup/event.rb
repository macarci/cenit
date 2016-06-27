module Setup
  class Event
    include CenitScoped
    include NamespaceNamed
    include ClassHierarchyAware
    include CrossOrigin::Document

    origins -> { Account.current_super_admin? ? :admin : nil }

    abstract_class true

    build_in_data_type.with(:name).referenced_by(:namespace, :name)
  end
end
