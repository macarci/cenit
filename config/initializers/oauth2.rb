# require 'oauth2'
require 'oauth2/response'

n = OAuth2::Response.new(nil)

class A
  KK = []
end

# puts "--------------------------------------------------"
#
# puts OAuth2::Response.name
# puts "cnsts: #{n.constants}"


OAuth2::Response::PARSERS[:text] = ->(body) { MultiJson.load(body) rescue Rack::Utils.parse_query(body) }

puts "--------------------------------------------------"


OAuth2::Response::CONTENT_TYPES['text/html'] = :text