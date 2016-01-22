module Setup
  class BasicAuthorization < Setup::Authorization
    include CenitScoped
    include AuthorizationHeader

    BuildInDataType.regist(self).with(:namespace, :name).referenced_by(:namespace, :name)

    field :username, type: String
    field :password, type: String

    validates_presence_of :username, :password

    auth_template_parameters basic_auth: :basic_auth

    def build_auth_header(template_parameters)
      'basic ' + ::Base64.encode64("#{auth.username}:#{auth.password}").gsub("\n", '')
    end
  end
end