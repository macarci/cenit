module Setup
  class OutgoingChannel < Channel
    include RailsAdmin::Models::Setup::OutgoingChannelAdmin

    abstract_class true
  end
end