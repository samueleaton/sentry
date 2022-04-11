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

# Write files to temp directory
build_dir = "#{Dir.tempdir}/sentry-build-#{Time.utc.to_unix}"
FileUtils.mkdir_p build_dir
File.write "#{build_dir}/sentry.cr", sentry_code
File.write "#{build_dir}/sentry_cli.cr", sentry_cli_code

# compile sentry files
puts "🤖  Compiling sentry using --release flag..."
build_args = ["build", "--release", "#{build_dir}/sentry_cli.cr", "-o", "./sentry"]
compile_success = system "crystal", build_args
FileUtils.rm_r build_dir

if compile_success
  puts "🤖  Sentry installed!"
  puts "\nTo execute sentry, do:
    ./sentry\n"
  puts "\nTo see options:
    ./sentry --help\n\n"
else
  puts "🤖  Bzzt. There was an error compiling sentry."
  exit 1
end
