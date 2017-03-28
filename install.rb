require "net/http"
require "uri"
require 'fileutils'

sentry_uri = URI.parse("https://raw.githubusercontent.com/samueleaton/sentry/master/src/sentry.cr")
response = Net::HTTP.get_response(sentry_uri)

if response.code.to_i > 299
  puts "HTTP request error"
  puts response.msg
  exit 1
end

sentry_code = response.body

sentry_cli_uri = URI.parse("https://raw.githubusercontent.com/samueleaton/sentry/master/src/sentry_cli.cr")
response = Net::HTTP.get_response(sentry_cli_uri)

if response.code.to_i > 299
  puts "HTTP request error"
  puts response.msg
  exit 1
end

sentry_cli_code = response.body

FileUtils.mkdir_p "./dev"
File.write "./dev/sentry.cr", sentry_code
File.write "./dev/sentry_cli.cr", sentry_cli_code

puts "Compiling sentry using --release..."
system "crystal build --release ./dev/sentry_cli.cr -o ./sentry"

puts "🤖  sentry installed!"
puts "\nTo execute sentry, do:
  ./sentry\n"
puts "\nTo see options:
  ./sentry --help\n\n"
