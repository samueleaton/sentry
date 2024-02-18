require "uri"
require "http/client"
require "file_utils"

print "🤖  Fetching sentry files..."

def check_code(url : String)
  response = HTTP::Client.get url

  if response.status_code > 299
    puts "HTTP request error. Could not fetch #{url}"
    puts response.body
    exit 1
  end

  response
end

sentry_source_code = check_code("https://raw.githubusercontent.com/zw963/sentry/master/src/sentry.cr").body
sentry_cli_source_code = check_code("https://raw.githubusercontent.com/zw963/sentry/master/src/sentry_cli.cr").body

puts " success"

# Write files to dev directory
FileUtils.mkdir_p "./dev"
File.write "./dev/sentry.cr", sentry_source_code
File.write "./dev/sentry_cli.cr", sentry_cli_source_code

# compile sentry files
puts "🤖  Compiling sentry using --release flag..."
build_args = ["build", "--release", "./dev/sentry_cli.cr", "-o", "./sentry"]
compile_success = system "crystal", build_args

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
