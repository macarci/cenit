module RailsAdmin
  module Models
    module Setup
      module ResourceChannelAdmin
        extend ActiveSupport::Concern

        included do
          rails_admin do
            weight 413
            configure :code, :code
            navigation_label 'Workflows'
            label 'Resource Channel'
            weight 410

            hide_on_navigation

            wizard_steps do
              {
                start:
                  {
                    label: I18n.t('admin.config.mapping_converter.wizard.start.label'),
                    description: I18n.t('admin.config.mapping_converter.wizard.start.description')
                  },
                end:
                  {
                    label: I18n.t('admin.config.converter.wizard.end.label'),
                    description: I18n.t('admin.config.converter.wizard.end.description')
                  }
              }
            end

            current_step do
              if bindings[:object].operation
                :end
              else
                :start
              end
            end

            configure :namespace, :enum_edit

            extra_associations do
              association = Mongoff::Association.new(abstract_model.model, :pagination, :embeds_one)
              [RailsAdmin::MongoffAssociation.new(association, abstract_model.model)]
            end

            configure :pagination, :has_one_association do
              nested_form_safe true
            end

            edit do
              field :namespace, :enum_edit#, &RailsAdmin::Config::Fields::Base::SHARED_READ_ONLY
              field :name#, &RailsAdmin::Config::Fields::Base::SHARED_READ_ONLY

              field :operation do
                #shared_read_only
                inline_edit false
                inline_add false
                help 'Required'
              end

              field :parameters do
                visible { bindings[:object].operation }
              end

              field :headers do
                visible { bindings[:object].operation }
              end

              field :template_parameters do
                visible { bindings[:object].operation }
              end

              field :response_type do
                #shared_read_only
                visible { bindings[:object].operation }
              end

              field :data_type do
                #shared_read_only
                visible { bindings[:object].operation }
              end

              field :pagination_schema do
                #shared_read_only
                visible { bindings[:object].operation }
              end

              field :pagination  do
                #shared_read_only
                visible { bindings[:object].pagination_schema.present? }
              end
            end

            show do
              field :namespace
              field :name
              field :operation
              field :pagination

              field :_id
              field :created_at
              #field :creator
              field :updated_at
              #field :updater
            end

            list do
              field :namespace
              field :name
              field :operation
              field :updated_at
            end

            filter_query_fields :namespace, :name
          end
        end

      end
    end
  end
end
