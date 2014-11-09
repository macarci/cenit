module Setup
  class Flow < Base
    include Setup::Enum

    belongs_to :webhook, class_name: Setup::Webhook.name
    belongs_to :event, class_name: Setup::Event.name

    field :name, type: String
    field :purpose, type: String
    field :active, type: Boolean

    validates_presence_of :name, :purpose, :webhook, :event, :active
    
    validate :event_and_flow_both_have_the_same_purpose

    validate do
      webhook.model == event.model
    end 

    rails_admin do
      field :name 
      field :purpose
      field :event
      field :webhook
      field :active
    end  

    after_save do |flow|
      if flow.active?
        Cenit::Rabbit.add_new_consumer(flow)
      else
        Cenit::Rabbit.remove_consumer(flow)
      end
    end

    # To test with after_destroy callback
    before_destroy do |for_flow|
      Cenit::Rabbit.remove_consumer(for_flow)
    end

    # This method process the object:
    # - First there is an object validations, if present
    # - Second applies object transformation
    # Returns nil if it is a no valid object
    # Returns (transformed) object
    def process(object)
      
      return nil if not valid_object?(object)

      result = transform object
      result
    end

    # This method runs schema validation(if present) on object
    # If there is an schema for validation return the result
    # of validate the object against the schema
    # Else returns true
    def valid_object?(object)
      # TO DO 
      true
    end

    def transform(object)
      # TO DO
      object
    end

    private
    def event_and_flow_both_have_the_same_purpose
      if this.purpose != event.purpose
        errors.add(:purpose, "This flow's purpose and event's purpose both must be equals")
      end
    end
  end
end
