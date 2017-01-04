# coding: utf-8
require "net/http"
require "uri"
require 'fileutils'

USER = "samueleaton"
BRANCH = "master"

DEST_DIR = "./dev"
MAIN_FILE = "sentry_cli.cr"
BIN = "./sentry"

REMOTE_SOURCES = [
  "https://raw.githubusercontent.com/#{USER}/sentry/#{BRANCH}/src/sentry.cr",
  "https://raw.githubusercontent.com/#{USER}/sentry/#{BRANCH}/src/sentry_cli.cr",
  "https://raw.githubusercontent.com/#{USER}/sentry/#{BRANCH}/src/sentry_command.cr"
]

sources = {}

STDOUT.write "Getting sources : "

REMOTE_SOURCES.each do |source_uri|
  uri = URI.parse source_uri
  response = Net::HTTP.get_response uri
  if response.code.to_i > 299
    STDERR.puts "HTTP request error for #{File.basename source_uri}"
    STDERR.puts "URL : #{source_uri}"
    STDERR.puts "Error message : #{response.msg}"
    exit 1
  else
    STDOUT.write '.'
    sources[File.basename source_uri] = response.body
  end
end
puts

FileUtils.mkdir_p DEST_DIR

sources.each do |filename, content|
  File.write "#{DEST_DIR}/#{filename}", content
end


puts "Compiling sentry..."
system "crystal build --release #{DEST_DIR}/#{MAIN_FILE} -o #{BIN}"

puts "🤖  sentry installed!"
puts "
To run, do (from your app's root directory):
  #{BIN}
"
puts "
To see options:
  #{BIN} --help

"
