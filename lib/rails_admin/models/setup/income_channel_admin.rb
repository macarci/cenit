module RailsAdmin
  module Models
    module Setup
      module IncomeChannelAdmin
        extend ActiveSupport::Concern

        included do
          rails_admin do
            navigation_label 'Workflows'
            navigation_icon 'fa fa-download'
            visible { User.current_super_admin? && group_visible }
            weight 410
            object_label_method { :custom_title }


            fields :namespace, :name, :data_type, :updated_at
          end
        end

      end
    end
  end
end
