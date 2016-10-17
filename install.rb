require "net/http"
require "uri"

response = Net::HTTP.get_response("https://raw.githubusercontent.com/samueleaton/sentry/v0.1.0/install.rb")
puts "response: #{response}"
puts "response.body: #{response.body}"
