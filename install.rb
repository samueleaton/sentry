require "net/http"
require "uri"
require "yaml"
require 'fileutils'

uri = URI.parse("https://raw.githubusercontent.com/samueleaton/sentry/master/src/sentry.cr")
response = Net::HTTP.get_response(uri)

if response.code.to_i > 299
  puts "HTTP request error"
  puts response.msg
  exit 1
end

sentry_code = response.body

begin
  shard_yml = YAML.load(File.read "./shard.yml")
  raise "missing key in shard.yml: name" unless shard_yml.has_key? "name"
rescue => e
  puts "Error with shard.yml"
  puts e
  exit 1
end

app_name = shard_yml["name"]
sentry_code.gsub!(/\[app_name\]/, app_name)

FileUtils.mkdir_p "./dev"
File.write "./dev/sentry.cr", sentry_code

puts "Compiling sentry..."
system "crystal build --release ./dev/sentry.cr -o ./sentry"

puts "🤖  sentry installed!"
puts "\nTo run, do (from you app's root directory):
  ./sentry\n\n"
