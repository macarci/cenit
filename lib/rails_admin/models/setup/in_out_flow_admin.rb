module RailsAdmin
  module Models
    module Setup
      module InOutFlowAdmin
        extend ActiveSupport::Concern

        included do
          rails_admin do
            object_label_method { :custom_title }
            navigation_label 'Workflows'
            navigation_icon 'fa fa-envelope-o'
            label 'IN/OUT Flow'
            weight 500

            configure :namespace, :enum_edit
            configure :active, :toggle_boolean

            edit do
              field :namespace
              field :name
              field :income_channel do
                #shared_read_only
                inline_edit false
                inline_add false
                help 'Required'
              end
              field :outgoing_channel do
                #shared_read_only
                inline_edit false
                inline_add false
                help 'Required'
              end
              field :transformation do
                #shared_read_only
                visible { bindings[:object].income_channel && bindings[:object].outgoing_channel }
                contextual_params do
                  if (inch = bindings[:object].income_channel) && (outch = bindings[:object].outgoing_channel)
                    { 
                      source_data_type_id: inch.data_type_id.to_s,
                      target_data_type_id: outch.data_type_id.to_s
                    }
                  end
                end
              end
              field :active do
                #shared_read_only
                visible { bindings[:object].income_channel && bindings[:object].outgoing_channel }
              end
            end

            fields :namespace, :name, :income_channel, :outgoing_channel, :transformation, :active, :updated_at
          end
        end

      end
    end
  end
end
