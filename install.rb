require "net/http"
require "uri"
require "yaml"
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

begin
  shard_yml = YAML.load(File.read "./shard.yml")
  raise "missing key in shard.yml: name" unless shard_yml.has_key? "name"
rescue => e
  puts "Error with shard.yml"
  puts e
  exit 1
end

process_name = shard_yml["name"]
sentry_code.gsub!(/\[process_name\]/, process_name)
sentry_cli_code.gsub!(/\[process_name\]/, process_name)

FileUtils.mkdir_p "./dev"
File.write "./dev/sentry.cr", sentry_code
File.write "./dev/sentry_cli.cr", sentry_cli_code

puts "Compiling sentry..."
system "crystal build --release ./dev/sentry_cli.cr -o ./sentry"

puts "🤖  sentry installed!"
puts "\nTo run, do (from your app's root directory):
  ./sentry\n"
puts "\nTo see options:
  ./sentry --help\n\n"
