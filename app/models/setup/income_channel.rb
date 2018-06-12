module Setup
  class IncomeChannel < Channel
    include RailsAdmin::Models::Setup::IncomeChannelAdmin

    abstract_class true
  end
end