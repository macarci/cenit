module Forms
  class FileRef
    include Mongoid::Document

    belongs_to :library, class_name: Setup::Library.to_s, inverse_of: nil
    field :file_model, type: String
    field :file_name, type: String

    before_save { false }

    def file_model_enum
      if file_model.present?
        [file_model]
      elsif library
        library.data_types.where(_type: Setup::FileDataType).collect(&:name)
      else
        []
      end
    end

    def file_name_enum
      if library && file_model && dt = library.data_types.where(name: file_model).first
        dt.records_model.all.collect(&:filename)
      else
        []
      end
    end
  end
end