module RailsAdmin

  class MongoffModelConfig < RailsAdmin::Config::Model

    def initialize(mongoff_entity)
      super(RailsAdmin::MongoffAbstractModel.abstract_model_for(mongoff_entity))
      @model = @abstract_model.model
      @parent = self

      (abstract_model.properties + abstract_model.associations).each do |property|
        type = property.type
        if property.is_a?(RailsAdmin::MongoffAssociation)
          type = (type.to_s + '_association').to_sym
        elsif (enumeration = property.enum)
          type = :enum
        end
        configure property.name, type do
          visible { property.visible? }
          label { property.name.to_s.to_title }
          filterable { property.filterable? }
          required { property.required? }
          valid_length { {} }
          enum { enumeration } if enumeration
          if (title = property.title)
            label { title }
          end
          if (description = property.description)
            description = (property.required? ? 'Required. ' : 'Optional. ') + description
            help { description }
          end
          unless (g = property.group.to_s.gsub(/ +/, '_').underscore.to_sym).blank?
            group g
          end
          if property.is_a?(RailsAdmin::MongoffAssociation)
            # associated_collection_cache_all true
            pretty_value do
              v = bindings[:view]
              action = v.instance_variable_get(:@action)
              if (showing = action.is_a?(RailsAdmin::Config::Actions::Show) && !v.instance_variable_get(:@showing))
                amc = RailsAdmin.config(association.klass)
              else
                amc = polymorphic? ? RailsAdmin.config(associated) : associated_model_config # perf optimization for non-polymorphic associations
              end
              am = amc.abstract_model
              if action.is_a?(RailsAdmin::Config::Actions::Show) && !v.instance_variable_get(:@showing)
                v.instance_variable_set(:@showing, true)
                fields = amc.list.with(controller: self, view: v, object: amc.abstract_model.model.new).visible_fields
                table = <<-HTML
                    <table class="table table-condensed table-striped">
                      <thead>
                        <tr>
                          #{fields.collect { |field| "<th class=\"#{field.css_class} #{field.type_css_class}\">#{field.label}</th>" }.join}
                          <th class="last shrink"></th>
                        <tr>
                      </thead>
                      <tbody>
                  #{[value].flatten.select(&:present?).collect do |associated|
                  can_see = !am.embedded_in?(bindings[:controller].instance_variable_get(:@abstract_model)) && (show_action = v.action(:show, am, associated))
                  '<tr class="script_row">' +
                    fields.collect do |field|
                      field.bind(object: associated, view: v)
                      "<td class=\"#{field.css_class} #{field.type_css_class}\" title=\"#{v.strip_tags(associated.to_s)}\">#{field.pretty_value}</td>"
                    end.join +
                    '<td class="last links"><ul class="inline list-inline">' +
                    if can_see
                      v.menu_for(:member, amc.abstract_model, associated, true)
                    else
                      ''
                    end +
                    '</ul></td>' +
                    '</tr>'
                end.join}
                      </tbody>
                    </table>
                HTML
                v.instance_variable_set(:@showing, false)
                table.html_safe
              else
                [value].flatten.select(&:present?).collect do |associated|
                  wording = associated.send(amc.object_label_method)
                  can_see = !am.embedded_in?(bindings[:controller].instance_variable_get(:@abstract_model)) && (show_action = v.action(:show, am, associated))
                  can_see ? v.link_to(wording, v.url_for(action: show_action.action_name, model_name: am.to_param, id: associated.id), class: 'pjax') : wording
                end.to_sentence.html_safe
              end
            end
          end
        end
      end
      if @model.is_a?(Mongoff::GridFs::FileModel)
        configure :data, :file_upload do
          required { bindings[:object].new_record? }
        end
        configure :length do
          label 'Size'
          pretty_value do #TODO Factorize these code in custom rails admin field type
            if objects = bindings[:controller].instance_variable_get(:@objects)
              unless max = bindings[:controller].instance_variable_get(:@max_length)
                bindings[:controller].instance_variable_set(:@max_length, max = objects.collect { |storage| storage.length }.reject(&:nil?).max)
              end
              (bindings[:view].render partial: 'size_bar', locals: { max: max, value: bindings[:object].length }).html_safe
            else
              bindings[:view].number_to_human_size(value)
            end
          end
        end
        edit do
          field :data
        end
        list do
          field :_id
          field :filename
          field :contentType
          field :uploadDate
          field :aliases
          field :metadata
          field :length
        end
        show do
          field :_id
          field :filename
          field :contentType
          field :uploadDate
          field :aliases
          field :metadata
          field :length
          field :md5
        end
      end

      navigation_label { target.data_type.namespace }

      object_label_method { @object_label_method ||= Config.label_methods.detect { |method| target.property?(method) } || :to_s }
    end

    def parent
      self
    end

    def target
      @model
    end

    def excluded?
      false
    end

    def label
      contextualized_label
    end

    def label_plural
      contextualized_label_plural
    end

    def contextualized_label(context = nil)
      if target.parent
        target.to_s.split('::').last
      else
        case context
        when nil
          target.data_type.title
        else
          target.data_type.custom_title
        end
      end
    end

    def contextualized_label_plural(context = nil)
      contextualized_label(context).pluralize
    end

    def root
      self
    end

    def visible?
      true
    end
  end
end