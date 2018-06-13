module Setup
  class InOutFlow
    include CenitScoped
    include NamespaceNamed
    include CustomTitle
    include RailsAdmin::Models::Setup::InOutFlowAdmin


    belongs_to :income_channel, class_name: Setup::IncomeChannel.to_s, inverse_of: nil
    belongs_to :outgoing_channel, class_name: Setup::OutgoingChannel.to_s, inverse_of: nil
    belongs_to :transformation, class_name: Setup::ConverterTransformation.to_s, inverse_of: nil

    field :active, type: Boolean

    def ready_to_save?
      (income_channel && outgoing_channel).present?
    end
  end
end