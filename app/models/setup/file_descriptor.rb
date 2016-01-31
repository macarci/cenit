module Setup
  class FileDescriptor
    include CenitScoped

    BuildInDataType.regist(self).and('required' => ['file_model'])

    field :file_ref, type: String

   end
end