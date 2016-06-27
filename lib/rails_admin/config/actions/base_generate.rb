module RailsAdmin
  module Config
    module Actions
      class BaseGenerate < RailsAdmin::Config::Actions::Base

        register_instance_option :only do
          Setup::Schema
        end

        register_instance_option :http_methods do
          [:get, :post]
        end

        register_instance_option :controller do
          proc do
            @bulk_ids = params.delete(:bulk_ids)
            if object_ids = params.delete(:object_ids)
              @bulk_ids = object_ids
            end
            source = (@object && [@object.id.to_s]) || @bulk_ids
            options_config = RailsAdmin::Config.model(Forms::GenerateOptions)
            if options_params = params[options_config.abstract_model.param_key]
              options_params = options_params.select { |k, _| %w(override_data_types).include?(k.to_s) }.permit!
            else
              options_params = {}
            end
            @form_object = Forms::GenerateOptions.new(options_params)
            result = nil
            begin
              result = Setup::DataTypeGeneration.process(@form_object.attributes.merge(source: source))
            rescue Exception => ex
              do_flash(:error, 'Error generating data types:', ex.message)
            end if params[:_save]
            if result
              do_flash_process_result(result)
              redirect_to back_or_index
            else
              conflicting_data_types = []
              @new_data_types_count = 0
              Setup::DataTypeGeneration.data_type_schemas(source).values.each do |h|
                @new_data_types_count += h.size
                conflicting_data_types += Setup::DataType.any_in(name: h.keys).to_a
              end unless Cenit.asynchronous_data_type_generation
              @new_data_types_count -= conflicting_data_types.length
              if @object
                @object.instance_variable_set(:@_to_override, conflicting_data_types)
              end
              @model_config = options_config
              render :form
            end
          end
        end

        register_instance_option :link_icon do
          'icon-cog'
        end

        register_instance_option :pjax? do
          false
        end
      end
    end
  end
end
