require "uri"
require "http/client"
require "file_utils"

print "🤖  Fetching sentry files..."

# Fetch sentry.cr
sentry_uri = "https://raw.githubusercontent.com/samueleaton/sentry/master/src/sentry.cr"
fetch_sentry_response = HTTP::Client.get sentry_uri

if fetch_sentry_response.status_code > 299
  puts "HTTP request error. Could not fetch #{sentry_uri}"
  puts fetch_sentry_response.body
  exit 1
end

sentry_code = fetch_sentry_response.body

# Fetch sentry_cli.cr
sentry_cli_uri = "https://raw.githubusercontent.com/samueleaton/sentry/master/src/sentry_cli.cr"
fetch_cli_response = HTTP::Client.get sentry_cli_uri

if fetch_cli_response.status_code > 299
  puts "HTTP request error. Could not fetch #{sentry_cli_uri}"
  puts fetch_cli_response.body
  exit 1
end

sentry_cli_code = fetch_cli_response.body

puts " success"

# Write files to dev directory
FileUtils.mkdir_p "./dev"
File.write "./dev/sentry.cr", sentry_code
File.write "./dev/sentry_cli.cr", sentry_cli_code

# compile sentry files
puts "🤖  Compiling sentry using --release flag..."
build_args = ["build", "--release", "--no-debug", "./dev/sentry_cli.cr", "-o", "./sentry"]
system "crystal", build_args

puts "🤖  Sentry installed!"
puts "\nTo execute sentry, do:
  ./sentry\n"
puts "\nTo see options:
  ./sentry --help\n\n"
