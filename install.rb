require "net/http"
require "uri"
require 'fileutils'

sentry_uri = URI.parse("https://raw.githubusercontent.com/samueleaton/sentry/master/src/sentry.cr")
req = Net::HTTP.new(sentry_uri.host, sentry_uri.port)
req.use_ssl = (sentry_uri.scheme == "https")
response = req.request(Net::HTTP::Get.new(sentry_uri.request_uri))

if response.code.to_i > 299
  puts "HTTP request error"
  puts response.msg
  exit 1
end

sentry_code = response.body

sentry_cli_uri = URI.parse("https://raw.githubusercontent.com/samueleaton/sentry/master/src/sentry_cli.cr")
req = Net::HTTP.new(sentry_cli_uri.host, sentry_cli_uri.port)
req.use_ssl = (sentry_cli_uri.scheme == "https")
response = req.request(Net::HTTP::Get.new(sentry_cli_uri.request_uri))

if response.code.to_i > 299
  puts "HTTP request error"
  puts response.msg
  exit 1
end

sentry_cli_code = response.body

FileUtils.mkdir_p "./dev"
File.write "./dev/sentry.cr", sentry_code
File.write "./dev/sentry_cli.cr", sentry_cli_code

puts "Compiling sentry using --release flag..."
compile_success = system "crystal build --release ./dev/sentry_cli.cr -o ./sentry"

if compile_success
  puts "🤖  sentry installed!"
  puts "\nTo execute sentry, do:
    ./sentry\n"
  puts "\nTo see options:
    ./sentry --help\n\n"
else
  puts "🤖  Bzzt. There was an error compiling sentry."
end
