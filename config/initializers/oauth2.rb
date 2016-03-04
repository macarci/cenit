require 'oauth2'

OAuth2::Response.register_parser(:text, %w(text/plain text/html)) do |body|
  MultiJson.load(body) rescue Rack::Utils.parse_query(body) rescue body
end